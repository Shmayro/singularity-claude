---
name: repair
description: Diagnoses why a singularity-tracked skill scores low from its score history and telemetry, saves a backup, rewrites the weak parts as a new version, and reverts if the new version does not do better. Use when a skill's average score is below the repair threshold or the user says a skill keeps getting something wrong.
argument-hint: "<skill-name>"
disable-model-invocation: true
---

# Repair a skill

## Step 1: Diagnose

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/score-manager.sh" list <skill-name>
"${CLAUDE_PLUGIN_ROOT}/scripts/telemetry-writer.sh" list <skill-name> --last 10
```

Find the pattern:
- Which rubric parts score lowest across runs?
- Which weaknesses and edge cases repeat?
- Pick one or two concrete failures to fix. Write them down as test tasks: you will rerun them in step 6.

## Step 2: Back up the current version

`~/.claude/skills` is usually not a git repository, so copy the skill before touching it:

```bash
v=$(jq -r '.currentVersion' ~/.claude/singularity/scores/<skill-name>.json)
mkdir -p ~/.claude/singularity/backups/<skill-name>/$v
cp -R ~/.claude/skills/<skill-name>/. ~/.claude/singularity/backups/<skill-name>/$v/
```

## Step 3: Map weak parts to the text

| Low part | Usual cause | Fix |
|----------|-------------|-----|
| Correctness | Wrong or vague instructions | Rewrite the steps that produced the wrong result |
| Completeness | A requirement is never mentioned | Add the missing step or check |
| Edge cases | No guidance for unusual input | Add the edge cases from the score history |
| Efficiency | Detours, repeated work | Cut steps |
| Reusability | Hardcoded values | Turn them into inputs |

## Step 4: Edit

Make targeted edits to the SKILL.md. Keep what scores well, keep the structure and names. Add a short `## Repair history` entry at the bottom: date, what changed, why.

## Step 5: New version

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/score-manager.sh" bump <skill-name>          # v1.0.0 -> v1.0.1
"${CLAUDE_PLUGIN_ROOT}/scripts/score-manager.sh" bump <skill-name> --minor  # bigger change: v1.0.0 -> v1.1.0
```

## Step 6: Rerun the failures

Run the repaired skill on the test tasks from step 1 and score each with `singularity-claude:score`. One run proves little: use every test task you wrote down.

## Step 7: Keep or revert

- New scores clearly better than the old average: keep.
- Not better: restore the backup and say so.

```bash
cp -R ~/.claude/singularity/backups/<skill-name>/<old-version>/. ~/.claude/skills/<skill-name>/
```

## Step 8: Log

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/telemetry-writer.sh" log <skill-name> \
  --trigger "repair" --summary "<what changed>. Scores: <old avg> -> <new scores>. <kept|reverted>"
```

## Report

```
Repair of <skill-name>
  Before: <old version>, average <n>/100
  After:  <new version>, test scores <a>, <b>
  Changes: <bullets>
  Result: kept | reverted to <old version>
```
