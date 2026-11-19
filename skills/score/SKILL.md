---
name: score
description: Rates one run of a singularity-tracked skill from 0 to 100 on a five-part rubric, records it, and updates the skill's average and maturity. Use right after a tracked skill finished a real task, or when the user asks how well a skill did.
argument-hint: "<skill-name>"
---

# Score a skill run

## Step 1: Identify the skill and the run

Find which tracked skill just ran and what it was asked to do:

```bash
jq -r '.skills | keys[]' ~/.claude/singularity/registry.json
```

If the skill is not tracked, ask: *"'<name>' isn't tracked by singularity. Register it first?"* If yes: `"${CLAUDE_PLUGIN_ROOT}/scripts/score-manager.sh" register <name>`.

## Step 2: Assess

Read `scoringMode` from `~/.claude/singularity/config.json`:
- `auto` (default): dispatch the `singularity-claude:skill-assessor` agent with the skill name and version, the user's original request, what the skill produced, and the rubric in `references/scoring-rubric.md`. It returns JSON.
- `manual`: ask the user for a 0-100 score and one line on what went well and what did not.
- `hybrid`: run the assessor, show its score, let the user override it.

## Step 3: Record

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/score-manager.sh" add <skill-name> <total-score> \
  --context "<what the skill was used for>" \
  --strengths '["<strength>"]' \
  --weaknesses '["<weakness>"]' \
  --edge-cases '["<edge case, if any>"]'
```

This also updates maturity and the registry. Do not edit `registry.json` yourself.

## Step 4: Log

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/telemetry-writer.sh" log <skill-name> \
  --trigger "scoring" --score <total-score> --summary "<one-line assessment>"
```

## Step 5: Report

```
Score: <total>/100 (average <avg>/100 over <n> scored runs)
  Correctness   <n>/20
  Completeness  <n>/20
  Edge cases    <n>/20
  Efficiency    <n>/20
  Reusability   <n>/20
Maturity: <level>
```

Then compare with `~/.claude/singularity/config.json`:
- Average below `autoRepairThreshold` (50) with 2+ scored runs: suggest `/singularity-claude:repair <skill-name>`.
- Average at or above `crystallizationThreshold` (90) with `crystallizationMinExecutions` (5) runs and maturity `hardened`: suggest `/singularity-claude:crystallize <skill-name>`.
