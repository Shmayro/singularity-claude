---
name: using-singularity
description: Explains the singularity-claude skill engine, which tracks how well your own skills perform, repairs the ones that score low and locks the ones that proved themselves. Use when the user asks about singularity, skill scores or maturity, or keeps repeating the same multi-step procedure that could become a skill.
---

# Singularity

singularity-claude tracks skills you create in `~/.claude/skills/`. Every time one of them runs, a hook counts the use. Scoring a run, repairing a weak skill and locking a proven one are separate commands.

## Commands

| Command | What it does |
|---------|--------------|
| `/singularity-claude:create` | Build a new skill and start tracking it |
| `/singularity-claude:score <skill>` | Rate the last run of a skill, 0-100 |
| `/singularity-claude:review <skill>` | Health report and next step for one skill |
| `/singularity-claude:repair <skill>` | Fix a skill that scores low, keeping the old version as a backup |
| `/singularity-claude:crystallize <skill>` | Lock a version that proved itself |
| `/singularity-claude:dashboard` | All tracked skills in one table |

## When to suggest a new skill

Suggest `/singularity-claude:create` only when the user has done the same multi-step procedure more than once, or says they will. A one-off task does not need a skill.

## When to suggest scoring

After a tracked skill finishes a real task, offer `/singularity-claude:score <skill>`. Scores drive the rest: a low average leads to repair, a high one to crystallization.

## Data

- Registry: `~/.claude/singularity/registry.json` (written only by `scripts/score-manager.sh`)
- Scores: `~/.claude/singularity/scores/<skill>.json`
- Telemetry: `~/.claude/singularity/telemetry/<skill>/`
- Config: `~/.claude/singularity/config.json`

## Maturity

| Level | Rule |
|-------|------|
| `draft` | fewer than 3 scored runs |
| `tested` | 3+ scored runs, average 60+ |
| `hardened` | 5+ scored runs, average 80+, at least one edge case recorded |
| `crystallized` | locked with `/singularity-claude:crystallize` |
