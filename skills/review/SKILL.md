---
name: review
description: Produces a health report for one singularity-tracked skill (version, maturity, average and trend, weakest rubric part, how often it is used, repairs so far) and recommends the next step. Use when the user asks how a skill is doing or whether to repair or crystallize it.
argument-hint: "<skill-name>"
disable-model-invocation: true
---

# Review a skill

## Step 1: Load

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/score-manager.sh" list <skill-name>
"${CLAUDE_PLUGIN_ROOT}/scripts/telemetry-writer.sh" list <skill-name> --last 20
jq --arg s <skill-name> '.skills[$s]' ~/.claude/singularity/registry.json
```

## Step 2: Compute

| Metric | Source |
|--------|--------|
| Version, maturity | registry `currentVersion`, `maturity` |
| Average score, scored runs | registry `averageScore`, `executionCount` |
| Uses | registry `useCount` (counted automatically on every run) |
| Scored share | scored runs / uses: low means the average rests on few runs |
| Trend | last 3 scores: rising, falling or flat |
| Weakest part | lowest rubric part across scores |
| Edge cases | distinct edge cases in the score history |
| Last used | registry `lastUsed` |
| Repairs | telemetry entries with trigger `repair` |

## Step 3: Recommend

| Situation | Recommendation |
|-----------|----------------|
| Fewer than 3 scored runs | Score more runs before judging |
| Used often, rarely scored | Score the next few runs |
| Average below 50 with 2+ scored runs | `/singularity-claude:repair <skill-name>` |
| Last 3 scores falling | Watch it; repair if it keeps falling |
| One rubric part always low | Targeted repair of that part |
| Average 90+, 5+ runs, hardened | `/singularity-claude:crystallize <skill-name>` |
| Not used in 30+ days | Ask whether it is still needed |
| Otherwise | Healthy, keep using it |

## Step 4: Report

```
<skill-name>  <version>  <maturity>
Average   <avg>/100 (<trend>) over <scored> scored runs, <uses> uses
Weakest   <part> (<avg>/20)
Edge cases <n> · Repairs <n> · Last used <date>
Next: <recommendation>
```

If the user wants more, dispatch the `singularity-claude:gap-detector` agent to judge whether the skill should be split, merged with another, or replaced.
