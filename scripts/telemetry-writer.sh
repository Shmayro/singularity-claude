#!/usr/bin/env bash
# telemetry-writer.sh — CLI for singularity skill telemetry
# Writes structured JSON logs for skill execution auditing

set -euo pipefail

SINGULARITY_DATA="${HOME}/.claude/singularity"
TELEMETRY_DIR="${SINGULARITY_DATA}/telemetry"

usage() {
  cat <<'EOF'
Usage: telemetry-writer.sh <command> <skill-name> [options]

Commands:
  log <skill> [options]            Record a telemetry entry
    --trigger <type>               How the skill was invoked (user-invoked, auto-repair, gap-detected)
    --version <ver>                Skill version (default: from registry)
    --summary <text>               What happened
    --score <n>                    Score if available
    --error <text>                 Error message if failed
    --edge-case <text>             Edge case encountered
    --files-created <json-array>   Files created
    --files-modified <json-array>  Files modified
    --duration <ms>                Execution duration in milliseconds

  list <skill> [--last <n>]        Show recent telemetry entries (default: 10)

  replay <skill> <timestamp>       Show full telemetry entry

  prune [--days <n>]               Remove entries older than n days (default: 90)
EOF
  exit 1
}

cmd_log() {
  local skill="$1"
  shift

  # Parse options
  local trigger="user-invoked" version="" summary="" score="" error="" edge_case=""
  local files_created="[]" files_modified="[]" duration="0"

  while [ $# -gt 0 ]; do
    case "$1" in
      --trigger) trigger="$2"; shift 2 ;;
      --version) version="$2"; shift 2 ;;
      --summary) summary="$2"; shift 2 ;;
      --score) score="$2"; shift 2 ;;
      --error) error="$2"; shift 2 ;;
      --edge-case) edge_case="$2"; shift 2 ;;
      --files-created) files_created="$2"; shift 2 ;;
      --files-modified) files_modified="$2"; shift 2 ;;
      --duration) duration="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  # Auto-detect version from registry
  if [ -z "$version" ] && [ -f "${SINGULARITY_DATA}/registry.json" ] && command -v jq &>/dev/null; then
    version=$(jq -r --arg s "$skill" '.skills[$s].currentVersion // "v1.0.0"' "${SINGULARITY_DATA}/registry.json" 2>/dev/null || echo "v1.0.0")
  fi
  [ -z "$version" ] && version="v1.0.0"

  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local short_id
  short_id=$(head -c 4 /dev/urandom | xxd -p | head -c 8)
  local date_part
  date_part=$(date -u +"%Y-%m-%d-%H-%M-%S")

  local skill_dir="${TELEMETRY_DIR}/${skill}"
  mkdir -p "$skill_dir"

  local filename="${date_part}-${short_id}.json"
  local filepath="${skill_dir}/${filename}"

  # Build score field
  local score_field="null"
  [ -n "$score" ] && score_field="$score"

  # Build errors array
  local errors_field="[]"
  [ -n "$error" ] && errors_field="[\"$(printf '%s' "$error" | sed 's/"/\\"/g')\"]"

  # Build edge cases array
  local edge_cases_field="[]"
  [ -n "$edge_case" ] && edge_cases_field="[\"$(printf '%s' "$edge_case" | sed 's/"/\\"/g')\"]"

  cat > "$filepath" << ENTRY
{
  "\$schema": "singularity-telemetry-v1",
  "skillName": "${skill}",
  "version": "${version}",
  "timestamp": "${now}",
  "trigger": "${trigger}",
  "inputs": {},
  "outputs": {
    "filesCreated": ${files_created},
    "filesModified": ${files_modified},
    "summary": "$(printf '%s' "$summary" | sed 's/"/\\"/g')"
  },
  "duration_ms": ${duration},
  "score": ${score_field},
  "errors": ${errors_field},
  "edgeCases": ${edge_cases_field},
  "repairTriggered": false
}
ENTRY

  echo "Telemetry logged: ${filepath}"
}

cmd_list() {
  local skill="$1"
  shift
  local last=10

  while [ $# -gt 0 ]; do
    case "$1" in
      --last) last="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  local skill_dir="${TELEMETRY_DIR}/${skill}"
  if [ ! -d "$skill_dir" ]; then
    echo "No telemetry for '${skill}'" >&2
    exit 1
  fi

  # List most recent entries
  ls -1t "$skill_dir"/*.json 2>/dev/null | head -n "$last" | while read -r f; do
    if command -v jq &>/dev/null; then
      jq -r '"[\(.timestamp)] \(.trigger) | score: \(.score // "n/a") | \(.outputs.summary // "no summary")"' "$f"
    else
      basename "$f"
    fi
  done
}

cmd_replay() {
  local skill="$1"
  local timestamp="$2"
  local skill_dir="${TELEMETRY_DIR}/${skill}"

  # Find matching file
  local match
  match=$(ls -1 "${skill_dir}/"*"${timestamp}"* 2>/dev/null | head -1)

  if [ -z "$match" ]; then
    echo "No telemetry entry matching '${timestamp}' for '${skill}'" >&2
    exit 1
  fi

  if command -v jq &>/dev/null; then
    jq '.' "$match"
  else
    cat "$match"
  fi
}

cmd_prune() {
  local days=90
  while [ $# -gt 0 ]; do
    case "$1" in
      --days) days="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  local count=0
  find "$TELEMETRY_DIR" -name "*.json" -mtime +"$days" -print0 2>/dev/null | while IFS= read -r -d '' f; do
    rm "$f"
    count=$((count + 1))
  done
  echo "Pruned ${count} entries older than ${days} days"
}

# Main dispatch
[ $# -lt 1 ] && usage

cmd="$1"
shift

case "$cmd" in
  log) [ $# -lt 1 ] && usage; cmd_log "$@" ;;
  list) [ $# -lt 1 ] && usage; cmd_list "$@" ;;
  replay) [ $# -lt 2 ] && usage; cmd_replay "$@" ;;
  prune) cmd_prune "$@" ;;
  *) usage ;;
esac
