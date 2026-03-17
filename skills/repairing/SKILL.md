---
name: repairing
description: Use when a singularity-managed skill is failing, scoring below threshold, or producing incorrect outputs that need automated correction via /singularity-repair
---

# Auto-Repair a Failing Skill

Diagnose why a skill is underperforming and rewrite it to fix identified weaknesses. This is the core of the recursive evolution loop.

## When to Use

- Skill average score < 50 (auto-repair threshold)
- Scoring skill suggested repair
- User noticed skill producing wrong or incomplete output

## Workflow

### Step 1: Diagnose

Read the skill's score history:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/score-manager.sh" list <skill-name>
```

Read recent telemetry:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/telemetry-writer.sh" list <skill-name> --last 5
```

Identify patterns:
- Which rubric dimensions score lowest consistently?
- What edge cases caused failures?
- Are errors recurring?

### Step 2: Read Current Skill

Load the skill's SKILL.md:
```
~/.claude/skills/<skill-name>/SKILL.md
```

Also read any supporting files in `references/`.

### Step 3: Identify Repair Targets

Map low-scoring dimensions to specific skill content:

| Low Dimension | Likely Cause | Repair Focus |
|---------------|-------------|--------------|
| Correctness | Wrong instructions or logic | Rewrite core workflow steps |
| Completeness | Missing requirements | Add missing steps or checks |
| Edge Cases | No error handling guidance | Add edge case handling section |
| Efficiency | Verbose or roundabout | Streamline workflow, remove unnecessary steps |
| Reusability | Hardcoded or too specific | Parameterize, add flexibility |

### Step 4: Rewrite

Edit the SKILL.md to address identified weaknesses. Preserve what works (high-scoring dimensions) and focus changes on the lowest-scoring areas.

**Rules:**
- Don't rewrite from scratch — surgical fixes only
- Preserve the existing structure and naming
- Add a "## Repair History" section at the bottom documenting what changed and why

### Step 5: Bump Version

The skill is now a new version. Update:
1. Score file — add new version entry:
   - Read current version from `~/.claude/singularity/scores/<skill-name>.json`
   - Increment patch: v1.0.0 → v1.0.1 (or minor if significant changes: v1.0.0 → v1.1.0)
2. Registry — update `currentVersion`

### Step 6: Test

Invoke the repaired skill with a scenario that previously failed or scored low.

### Step 7: Score

Run `singularity-claude:scoring` on the test output.

### Step 8: Compare

| New > Old avg | Keep new version |
|---------------|-----------------|
| New <= Old avg | Revert: restore previous SKILL.md from git history and keep old version as current |

If repair failed (new version scores equal or worse):
- Log the failed repair attempt in telemetry
- Suggest user intervention: *"Auto-repair didn't improve the skill. Consider manual editing or `/singularity-review` for deeper analysis."*

### Step 9: Log Telemetry

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/telemetry-writer.sh" log <skill-name> \
  --trigger "auto-repair" \
  --summary "Repaired: <what changed>. Score: <old-avg> → <new-score>"
```

## Report

After repair, show:
```
Repair Summary for <skill-name>:
  Previous version: v1.0.0 (avg: 42/100)
  New version: v1.0.1
  Changes: <bullet list of what was fixed>
  Test score: <score>/100
  Status: <Improved ✓ / Failed ✗ — reverted>
```
