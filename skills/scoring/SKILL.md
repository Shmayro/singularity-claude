---
name: scoring
description: Use after any singularity-managed skill execution to rate performance 0-100, track quality over time, and trigger repair when scores drop below threshold
---

# Score a Skill Execution

Evaluate skill performance using a structured 5-dimension rubric. Scores drive the evolution loop: low scores trigger repair, high scores enable crystallization.

## Workflow

### Step 1: Identify the Skill

Determine which singularity-managed skill was just executed. Check `~/.claude/singularity/registry.json` to confirm it's tracked.

If the skill isn't registered, ask: *"This skill isn't tracked by singularity. Want me to register it first?"*

### Step 2: Assess Performance

Dispatch the `singularity-claude:skill-assessor` agent (haiku model, fast and cheap) with:
- **Skill name** and version
- **What was requested** (the user's original task)
- **What was produced** (the skill's output/changes)
- **The scoring rubric** from `references/scoring-rubric.md`

The assessor returns a structured JSON score.

### Step 3: Record the Score

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/score-manager.sh" add <skill-name> <total-score> \
  --context "<what the skill was used for>" \
  --strengths '["<strength1>", "<strength2>"]' \
  --weaknesses '["<weakness1>"]' \
  --edge-cases '["<edge-case-if-any>"]'
```

### Step 4: Check Thresholds

Read config from `~/.claude/singularity/config.json`:

| Condition | Action |
|-----------|--------|
| Average < `autoRepairThreshold` (50) for 2+ runs | Suggest: *"This skill is underperforming. Run `/singularity-repair` to fix it."* |
| Average >= `crystallizationThreshold` (90) with 5+ runs | Suggest: *"This skill is ready for crystallization. Run `/singularity-crystallize` to lock it."* |

### Step 5: Update Registry

Update `~/.claude/singularity/registry.json` with:
- `lastExecuted`: current timestamp
- `executionCount`: increment
- `averageScore`: from score file

### Step 6: Log Telemetry

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/telemetry-writer.sh" log <skill-name> \
  --trigger "scoring" \
  --score <total-score> \
  --summary "<brief assessment>"
```

### Step 7: Report

Show the user:
```
Score: <total>/100 (avg: <average>/100 over <count> runs)
  Correctness:    <n>/20
  Completeness:   <n>/20
  Edge Cases:     <n>/20
  Efficiency:     <n>/20
  Reusability:    <n>/20
Maturity: <level> → <new-level-if-changed>
```

## Scoring Modes

From `config.json`:
- `"auto"` — Dispatch assessor agent automatically (default)
- `"manual"` — Ask user for the 0-100 score directly
- `"hybrid"` — Auto-assess, show result, let user override
