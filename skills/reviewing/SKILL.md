---
name: reviewing
description: Use when wanting to assess the health of a singularity-managed skill, check its maturity, decide whether it needs repair or is ready for crystallization via /singularity-review
---

# Review Skill Health

Produce a comprehensive health report for a singularity-managed skill and recommend next actions.

## Workflow

### Step 1: Load Data

Read the skill's data from three sources:

1. **Score history:**
   ```bash
   "${CLAUDE_PLUGIN_ROOT}/scripts/score-manager.sh" list <skill-name>
   ```

2. **Registry entry:** Read from `~/.claude/singularity/registry.json`

3. **Recent telemetry:**
   ```bash
   "${CLAUDE_PLUGIN_ROOT}/scripts/telemetry-writer.sh" list <skill-name> --last 10
   ```

### Step 2: Compute Health Metrics

| Metric | How to Calculate |
|--------|-----------------|
| **Current version** | From score file `currentVersion` |
| **Maturity** | From score file version entry |
| **Average score** | From score file version `averageScore` |
| **Score trend** | Compare last 3 scores: improving (+), declining (-), stable (=) |
| **Execution count** | From score file version `executionCount` |
| **Lowest dimension** | Find the rubric dimension with lowest average across scores |
| **Edge cases handled** | Count unique edge cases from score entries |
| **Staleness** | Days since `lastExecuted` in registry |
| **Repair history** | Count telemetry entries with trigger "auto-repair" |

### Step 3: Generate Recommendation

| Condition | Recommendation |
|-----------|---------------|
| Average declining over last 3 scores | "Skill is degrading. Consider `/singularity-repair`" |
| Average < 50 with 2+ runs | "Skill needs repair. Run `/singularity-repair`" |
| Average >= 90, 5+ runs, has edge cases, maturity is `hardened` | "Ready for crystallization. Run `/singularity-crystallize`" |
| Execution count < 3 | "Needs more usage data. Use the skill more before evaluating." |
| Not executed in 30+ days | "Stale skill. Review if still relevant." |
| One dimension consistently low | "Weakest area: <dimension>. Targeted repair recommended." |
| All metrics healthy | "Skill is healthy. Continue using." |

### Step 4: Present Report

```
Health Report: <skill-name>
═══════════════════════════════════════
Version:     <version>
Maturity:    <level>
Avg Score:   <avg>/100 (<trend>)
Executions:  <count>
Last Used:   <date> (<days> days ago)
Edge Cases:  <count> handled

Dimension Breakdown:
  Correctness:    <avg>/20
  Completeness:   <avg>/20
  Edge Cases:     <avg>/20
  Efficiency:     <avg>/20
  Reusability:    <avg>/20

Weakest Area: <dimension> (<avg>/20)
Repairs:     <count> attempted

Recommendation: <recommendation>
═══════════════════════════════════════
```

### Optional: Deep Analysis

If the user wants more detail, dispatch the `singularity-claude:gap-detector` agent to analyze whether this skill's weaknesses indicate a need for:
- Splitting into multiple focused skills
- Merging with another skill
- Fundamentally different approach
