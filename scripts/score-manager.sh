#!/usr/bin/env bash
# score-manager.sh — CLI for managing singularity skill scores
# Uses jq if available, falls back to node -e for JSON manipulation

set -euo pipefail

SINGULARITY_DATA="${HOME}/.claude/singularity"
SCORES_DIR="${SINGULARITY_DATA}/scores"

# JSON tool detection
json_tool=""
if command -v jq &>/dev/null; then
  json_tool="jq"
elif command -v node &>/dev/null; then
  json_tool="node"
else
  echo "Error: Neither jq nor node found. Install one to use score-manager." >&2
  exit 1
fi

# Atomic write: write to temp file, then rename
atomic_write() {
  local target="$1"
  local content="$2"
  local tmp="${target}.tmp.$$"
  printf '%s' "$content" > "$tmp"
  mv "$tmp" "$target"
}

# Read JSON file and extract with jq or node
json_query() {
  local file="$1"
  local query="$2"
  if [ "$json_tool" = "jq" ]; then
    jq -r "$query" "$file"
  else
    node -e "const d=JSON.parse(require('fs').readFileSync('${file}','utf8')); const q=${query}; console.log(typeof q==='object'?JSON.stringify(q,null,2):q)"
  fi
}

usage() {
  cat <<'EOF'
Usage: score-manager.sh <command> <skill-name> [options]

Commands:
  init <skill>                     Create score file for a new skill
  add <skill> <score>              Record a score (0-100)
    [--version <ver>]              Version (auto-detected from git tag or v1.0.0)
    [--context <text>]             What the skill was used for
    [--strengths <json-array>]     What went well
    [--weaknesses <json-array>]    What needs improvement
    [--edge-cases <json-array>]    Edge cases encountered
  list <skill>                     Show score history
  average <skill> [--version <v>]  Get average score
  trend <skill>                    Show score trend across versions
  maturity <skill>                 Get current maturity level
EOF
  exit 1
}

cmd_init() {
  local skill="$1"
  local file="${SCORES_DIR}/${skill}.json"

  if [ -f "$file" ]; then
    echo "Score file already exists for '${skill}'" >&2
    exit 1
  fi

  mkdir -p "${SCORES_DIR}"
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  local content
  content=$(cat <<INIT
{
  "\$schema": "singularity-score-v1",
  "skillName": "${skill}",
  "versions": [
    {
      "version": "v1.0.0",
      "gitTag": "singularity/${skill}/v1.0.0",
      "scores": [],
      "averageScore": 0,
      "executionCount": 0,
      "maturity": "draft"
    }
  ],
  "currentVersion": "v1.0.0",
  "createdAt": "${now}",
  "lastScoredAt": null
}
INIT
)
  atomic_write "$file" "$content"
  echo "Initialized score file for '${skill}'"
}

cmd_add() {
  local skill="$1"
  local score="$2"
  shift 2

  # Parse optional args
  local version="" context="" strengths="[]" weaknesses="[]" edge_cases="[]"
  while [ $# -gt 0 ]; do
    case "$1" in
      --version) version="$2"; shift 2 ;;
      --context) context="$2"; shift 2 ;;
      --strengths) strengths="$2"; shift 2 ;;
      --weaknesses) weaknesses="$2"; shift 2 ;;
      --edge-cases) edge_cases="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  # Validate score
  if ! [[ "$score" =~ ^[0-9]+$ ]] || [ "$score" -lt 0 ] || [ "$score" -gt 100 ]; then
    echo "Error: Score must be 0-100" >&2
    exit 1
  fi

  local file="${SCORES_DIR}/${skill}.json"
  if [ ! -f "$file" ]; then
    echo "Error: No score file for '${skill}'. Run 'init' first." >&2
    exit 1
  fi

  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Use current version if not specified
  if [ -z "$version" ]; then
    version=$(jq -r '.currentVersion' "$file" 2>/dev/null || echo "v1.0.0")
  fi

  if [ "$json_tool" = "jq" ]; then
    local updated
    updated=$(jq --arg ver "$version" --argjson score "$score" --arg ts "$now" \
      --arg ctx "$context" --argjson str "$strengths" --argjson weak "$weaknesses" \
      --argjson edge "$edge_cases" '
      .lastScoredAt = $ts |
      (.versions[] | select(.version == $ver)) |= (
        .scores += [{
          "timestamp": $ts,
          "score": $score,
          "context": $ctx,
          "strengths": $str,
          "weaknesses": $weak,
          "edgeCasesEncountered": $edge
        }] |
        .executionCount = (.scores | length) |
        .averageScore = ((.scores | map(.score) | add) / (.scores | length) | floor)
      )
    ' "$file")
    atomic_write "$file" "$updated"
  else
    node -e "
      const fs = require('fs');
      const d = JSON.parse(fs.readFileSync('${file}', 'utf8'));
      const v = d.versions.find(v => v.version === '${version}');
      if (!v) { console.error('Version not found'); process.exit(1); }
      v.scores.push({
        timestamp: '${now}', score: ${score}, context: '${context}',
        strengths: ${strengths}, weaknesses: ${weaknesses},
        edgeCasesEncountered: ${edge_cases}
      });
      v.executionCount = v.scores.length;
      v.averageScore = Math.floor(v.scores.reduce((s,e) => s + e.score, 0) / v.scores.length);
      d.lastScoredAt = '${now}';
      fs.writeFileSync('${file}', JSON.stringify(d, null, 2));
    "
  fi

  # Compute and update maturity
  _update_maturity "$skill" "$version"

  # Show result
  local avg
  avg=$(jq -r --arg ver "$version" '.versions[] | select(.version == $ver) | .averageScore' "$file" 2>/dev/null || echo "?")
  local count
  count=$(jq -r --arg ver "$version" '.versions[] | select(.version == $ver) | .executionCount' "$file" 2>/dev/null || echo "?")
  echo "Recorded score ${score} for ${skill} ${version} (avg: ${avg}/100, ${count} runs)"
}

_update_maturity() {
  local skill="$1"
  local version="$2"
  local file="${SCORES_DIR}/${skill}.json"

  if [ "$json_tool" = "jq" ]; then
    local updated
    updated=$(jq --arg ver "$version" '
      (.versions[] | select(.version == $ver)) |= (
        .maturity = (
          if .maturity == "crystallized" then "crystallized"
          elif .executionCount >= 5 and .averageScore >= 80 and (.scores | map(.edgeCasesEncountered // []) | flatten | length) > 0 then "hardened"
          elif .executionCount >= 3 and .averageScore >= 60 then "tested"
          else "draft"
          end
        )
      )
    ' "$file")
    atomic_write "$file" "$updated"
  fi
}

cmd_list() {
  local skill="$1"
  local file="${SCORES_DIR}/${skill}.json"

  if [ ! -f "$file" ]; then
    echo "No score file for '${skill}'" >&2
    exit 1
  fi

  if [ "$json_tool" = "jq" ]; then
    jq -r '
      .versions[] |
      "Version: \(.version) | Maturity: \(.maturity) | Avg: \(.averageScore)/100 | Runs: \(.executionCount)",
      (.scores[] | "  [\(.timestamp)] Score: \(.score) — \(.context // "no context")")
    ' "$file"
  else
    node -e "
      const d = JSON.parse(require('fs').readFileSync('${file}', 'utf8'));
      d.versions.forEach(v => {
        console.log('Version: ' + v.version + ' | Maturity: ' + v.maturity + ' | Avg: ' + v.averageScore + '/100 | Runs: ' + v.executionCount);
        v.scores.forEach(s => console.log('  [' + s.timestamp + '] Score: ' + s.score + ' — ' + (s.context || 'no context')));
      });
    "
  fi
}

cmd_average() {
  local skill="$1"
  shift
  local version=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --version) version="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  local file="${SCORES_DIR}/${skill}.json"
  if [ ! -f "$file" ]; then
    echo "No score file for '${skill}'" >&2
    exit 1
  fi

  if [ -n "$version" ]; then
    jq -r --arg ver "$version" '.versions[] | select(.version == $ver) | .averageScore' "$file"
  else
    jq -r '.versions[-1].averageScore' "$file"
  fi
}

cmd_trend() {
  local skill="$1"
  local file="${SCORES_DIR}/${skill}.json"

  if [ ! -f "$file" ]; then
    echo "No score file for '${skill}'" >&2
    exit 1
  fi

  jq -r '
    .versions | to_entries[] |
    "\(.value.version)\t\(.value.averageScore)\t\(.value.executionCount)\t\(.value.maturity)"
  ' "$file" | while IFS=$'\t' read -r ver avg count mat; do
    printf "%-10s  avg: %3s/100  runs: %s  maturity: %s\n" "$ver" "$avg" "$count" "$mat"
  done
}

cmd_maturity() {
  local skill="$1"
  local file="${SCORES_DIR}/${skill}.json"

  if [ ! -f "$file" ]; then
    echo "No score file for '${skill}'" >&2
    exit 1
  fi

  jq -r '.versions[-1].maturity' "$file"
}

# Main dispatch
[ $# -lt 2 ] && usage

cmd="$1"
shift

case "$cmd" in
  init) cmd_init "$@" ;;
  add) cmd_add "$@" ;;
  list) cmd_list "$@" ;;
  average) cmd_average "$@" ;;
  trend) cmd_trend "$@" ;;
  maturity) cmd_maturity "$@" ;;
  *) usage ;;
esac
