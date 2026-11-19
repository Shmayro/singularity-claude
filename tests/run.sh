#!/usr/bin/env bash
# End-to-end checks for the scripts and hooks, in a throwaway HOME. Run: bash tests/run.sh (needs jq)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export HOME; HOME="$(mktemp -d)"
SM="bash ${ROOT}/scripts/score-manager.sh"; TW="bash ${ROOT}/scripts/telemetry-writer.sh"
REG="$HOME/.claude/singularity/registry.json"
fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "PASS: $*"; }

# session start on a fresh machine: creates the data folder, prints nothing (no alerts)
out=$(bash "${ROOT}/hooks/session-start")
[ -f "$REG" ] && [ -f "$HOME/.claude/singularity/config.json" ] || fail "data folder not created"
[ -z "$out" ] || fail "session-start should be silent without alerts, got: $out"
pass "session-start creates data, stays silent"

# register -> registry entry + score file, one writer
$SM register demo --tags '["ci"]' >/dev/null
[ -f "$HOME/.claude/singularity/scores/demo.json" ] || fail "register did not create the score file"
[ "$(jq -r '.skills.demo.currentVersion' "$REG")" = "v1.0.0" ] || fail "register: version"
[ "$(jq -r '.skills.demo.useCount' "$REG")" = "0" ] || fail "register: useCount"
pass "register"

# add -> score file and registry agree
$SM add demo 40 --context "ci" >/dev/null
$SM add demo 30 --context "ci" >/dev/null
[ "$(jq -r '.skills.demo.averageScore' "$REG")" = "35" ] || fail "registry average not synced"
[ "$(jq -r '.skills.demo.executionCount' "$REG")" = "2" ] || fail "registry count not synced"
grep -q "Score: 40" <<< "$($SM list demo)" || fail "list"
pass "add syncs the registry"

# log-use: Claude calling the Skill tool, and the user typing /demo; untracked and own skills ignored
echo '{"hook_event_name":"PostToolUse","tool_name":"Skill","tool_input":{"skill":"demo"}}' | bash "${ROOT}/hooks/log-use"
echo '{"hook_event_name":"UserPromptExpansion","command_name":"demo","expansion_type":"slash_command"}' | bash "${ROOT}/hooks/log-use"
echo '{"hook_event_name":"PostToolUse","tool_name":"Skill","tool_input":{"skill":"some-plugin:demo"}}' | bash "${ROOT}/hooks/log-use"
echo '{"hook_event_name":"PostToolUse","tool_name":"Skill","tool_input":{"skill":"not-tracked"}}' | bash "${ROOT}/hooks/log-use"
echo '{"hook_event_name":"PostToolUse","tool_name":"Skill","tool_input":{"skill":"singularity-claude:score"}}' | bash "${ROOT}/hooks/log-use"
echo 'not json' | bash "${ROOT}/hooks/log-use"
[ "$(jq -r '.skills.demo.useCount' "$REG")" = "3" ] || fail "useCount should be 3, got $(jq -r '.skills.demo.useCount' "$REG")"
[ "$(jq -r '.skills | has("not-tracked")' "$REG")" = "false" ] || fail "untracked skill was added"
log=$($TW list demo --last 5)   # captured first: grep -q in a pipe trips pipefail
grep -q "used-by-user" <<< "$log" || fail "telemetry for a typed command"
grep -q "used-by-claude" <<< "$log" || fail "telemetry for a Skill tool call"
pass "log-use counts both paths, ignores the rest"

# session start with a low-scoring skill: one factual alert, valid JSON
out=$(bash "${ROOT}/hooks/session-start")
echo "$out" | jq -e '.hookSpecificOutput.additionalContext | test("demo: average score 35/100 over 2 scored runs")' >/dev/null || fail "alert: $out"
echo "$out" | jq -e '.hookSpecificOutput.additionalContext | test("/singularity-claude:repair demo")' >/dev/null || fail "alert command"
pass "session-start reports a skill below the repair threshold"

# bump -> new version, registry follows; crystallize
[ "$($SM bump demo)" = "v1.0.1" ] || fail "patch bump"
[ "$($SM bump demo --minor)" = "v1.1.0" ] || fail "minor bump"
[ "$(jq -r '.skills.demo.currentVersion' "$REG")" = "v1.1.0" ] || fail "registry version after bump"
$SM crystallize demo >/dev/null
[ "$(jq -r '.skills.demo.maturity' "$REG")" = "crystallized" ] || fail "crystallize"
pass "bump and crystallize"

echo "all checks passed"
