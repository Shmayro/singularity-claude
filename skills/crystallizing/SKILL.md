---
name: crystallizing
description: Use when a skill has proven itself with consistently high scores across multiple executions and should be locked as a stable, immutable version via /singularity-crystallize
---

# Crystallize a Validated Skill

Lock a battle-tested skill version as production-grade. Crystallized skills are immutable — further changes require a new version.

## When to Use

- Skill average score >= 90 with 5+ executions
- Skill has handled at least one edge case
- User confirms the skill is ready

## Workflow

### Step 1: Validate Readiness

Read score file and config:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/score-manager.sh" trend <skill-name>
```

Check requirements:
- [ ] Average score >= `crystallizationThreshold` (default: 90)
- [ ] Execution count >= `crystallizationMinExecutions` (default: 5)
- [ ] At least one edge case recorded in score history
- [ ] Maturity is `hardened` (not `draft` or `tested`)

If not ready, explain what's missing:
*"This skill needs <X more runs / higher scores / edge case coverage> before crystallization."*

### Step 2: Confirm with User

Show the skill's full score summary and ask:
*"Ready to crystallize <skill-name> v<version>? This locks the current version as immutable."*

### Step 3: Create Git Tag

If `~/.claude/skills/` is a git repository:
```bash
cd ~/.claude/skills
git add <skill-name>/
git commit -m "singularity: crystallize <skill-name> v<version>"
git tag "singularity/<skill-name>/v<version>"
```

If not a git repo, create a backup copy:
```bash
mkdir -p ~/.claude/singularity/crystallized/<skill-name>/
cp -r ~/.claude/skills/<skill-name>/ ~/.claude/singularity/crystallized/<skill-name>/v<version>/
```

### Step 4: Update Records

Update score file:
- Set maturity to `"crystallized"` for the current version

Update registry:
- Set `maturity` to `"crystallized"`

### Step 5: Log Telemetry

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/telemetry-writer.sh" log <skill-name> \
  --trigger "crystallization" \
  --summary "Crystallized v<version> (avg: <score>/100, <count> runs)"
```

## Report

```
Crystallized: <skill-name> v<version>
  Average score: <avg>/100 over <count> executions
  Edge cases handled: <count>
  Git tag: singularity/<skill-name>/v<version>
  Status: LOCKED — further changes require a new version
```

## Rollback

To recover a crystallized version later:
```bash
git checkout singularity/<skill-name>/v<version> -- <skill-name>/
```

Or restore from backup:
```bash
cp -r ~/.claude/singularity/crystallized/<skill-name>/v<version>/ ~/.claude/skills/<skill-name>/
```
