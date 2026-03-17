---
name: using-singularity
description: Use when starting any conversation where skills may need to be created, evaluated, repaired, or when a capability gap is detected during task execution
---

# Singularity — Self-Evolving Skill Engine

You have singularity-claude, a system that creates, scores, repairs, and hardens Claude Code skills through recursive improvement cycles.

## Decision Flow

When a task arrives:

1. Task arrives → Does a skill exist?
   - **Yes** → Execute it → Score with `/singularity-score` → Maturity auto-updates
     - Avg < 50 (2+ runs) → Suggest `/singularity-repair`
     - Avg ≥ 90, 5+ runs, hardened, edge cases → Suggest `/singularity-crystallize`
     - Otherwise → Keep using and scoring
   - **No** → Is this a recurring need?
     - **Yes** → Create with `/singularity-create`
     - **No** → Do manually

## Available Commands

| Command | Skill | Purpose |
|---------|-------|---------|
| `/singularity-create` | `singularity-claude:creating-skills` | Build a new skill |
| `/singularity-score` | `singularity-claude:scoring` | Rate a skill execution 0-100 |
| `/singularity-review` | `singularity-claude:reviewing` | Health check a skill |
| `/singularity-repair` | `singularity-claude:repairing` | Auto-fix a failing skill |
| `/singularity-crystallize` | `singularity-claude:crystallizing` | Lock a validated version |
| `/singularity-dashboard` | `singularity-claude:dashboard` | Overview of all managed skills |

## Capability Gap Detection

Watch for these signals during task execution — they indicate a new skill should be created:

1. **Repetition across sessions** — You're doing the same multi-step procedure you've done before
2. **Task failure without skill coverage** — No existing skill addresses this capability
3. **Generalizable pattern** — The procedure would apply beyond this specific task
4. **Complex workflow** — The task requires 5+ steps that could be encoded

When you detect a gap, suggest: *"This looks like a capability gap. Want me to create a skill for this with `/singularity-create`?"*

## Data Locations

- **Registry:** `~/.claude/singularity/registry.json`
- **Scores:** `~/.claude/singularity/scores/<skill-name>.json`
- **Telemetry:** `~/.claude/singularity/telemetry/<skill-name>/`
- **Config:** `~/.claude/singularity/config.json`
- **Created skills:** `~/.claude/skills/<skill-name>/SKILL.md`

## Maturity Levels

| Level | Criteria | Meaning |
|-------|----------|---------|
| `draft` | < 3 executions | New, unproven |
| `tested` | 3+ runs, avg >= 60 | Working but not battle-tested |
| `hardened` | 5+ runs, avg >= 80, edge cases handled | Reliable |
| `crystallized` | Locked via git tag | Production-grade, immutable |
