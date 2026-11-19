---
name: crystallize
description: Locks the current version of a singularity-tracked skill that has proven itself (high average over enough scored runs, edge cases handled) by tagging or copying it, so it can always be restored. Use when a skill is ready to crystallize or the user wants to freeze a version.
argument-hint: "<skill-name>"
disable-model-invocation: true
---

# Crystallize a skill

## Step 1: Check readiness

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/score-manager.sh" trend <skill-name>
"${CLAUDE_PLUGIN_ROOT}/scripts/score-manager.sh" list <skill-name>
```

All of these, with thresholds from `~/.claude/singularity/config.json`:
- average at least `crystallizationThreshold` (90)
- at least `crystallizationMinExecutions` (5) scored runs
- at least one edge case recorded
- maturity `hardened`

If something is missing, say what: *"<skill-name> needs <n more scored runs / a higher average / an edge case> first."*

## Step 2: Confirm

Show the score summary and ask: *"Lock <skill-name> <version>? Later changes will need a new version."*

## Step 3: Save the version

If `~/.claude/skills` is a git repository:

```bash
cd ~/.claude/skills
git add <skill-name>/
git commit -m "singularity: crystallize <skill-name> <version>"
git tag "singularity/<skill-name>/<version>"
```

Otherwise copy it:

```bash
mkdir -p ~/.claude/singularity/crystallized/<skill-name>/<version>
cp -R ~/.claude/skills/<skill-name>/. ~/.claude/singularity/crystallized/<skill-name>/<version>/
```

## Step 4: Record

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/score-manager.sh" crystallize <skill-name>
"${CLAUDE_PLUGIN_ROOT}/scripts/telemetry-writer.sh" log <skill-name> \
  --trigger "crystallization" --summary "Crystallized <version> (avg <n>/100, <n> scored runs)"
```

Nothing stops an edit to the skill file afterwards. If it is edited, run `score-manager.sh bump <skill-name>` so the change becomes a new version and the crystallized one stays restorable.

## Restore

```bash
cd ~/.claude/skills && git checkout singularity/<skill-name>/<version> -- <skill-name>/
# or
cp -R ~/.claude/singularity/crystallized/<skill-name>/<version>/. ~/.claude/skills/<skill-name>/
```
