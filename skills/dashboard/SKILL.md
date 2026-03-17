---
name: dashboard
description: Use when wanting an overview of all singularity-managed skills showing their scores, maturity levels, trends, and alerts via /singularity-dashboard
---

# Singularity Dashboard

Display a comprehensive overview of all managed skills with health indicators and actionable alerts.

## Workflow

### Step 1: Load Registry

Read `~/.claude/singularity/registry.json` to get the list of all managed skills.

If no skills are registered:
*"No skills tracked yet. Create your first skill with `/singularity-create`."*

### Step 2: Gather Data

For each skill in the registry:
1. Read the score file from `~/.claude/singularity/scores/<skill-name>.json`
2. Compute trend: compare last 2 scores (if available)
   - Score increased by 5+ → `↑`
   - Score decreased by 5+ → `↓`
   - Otherwise → `→`

### Step 3: Display Table

```
Singularity Dashboard
═══════════════════════════════════════════════════════════════════
| Skill              | Version | Maturity      | Avg  | Runs | Trend | Last Used  |
|--------------------|---------|---------------|------|------|-------|------------|
| my-api-client      | v1.2.0  | hardened      | 87   | 12   | ↑     | 2026-03-17 |
| data-transformer   | v1.0.1  | tested        | 72   | 5    | ↓     | 2026-03-15 |
| form-generator     | v1.0.0  | draft         | 45   | 2    | →     | 2026-03-10 |
═══════════════════════════════════════════════════════════════════
```

### Step 4: Show Alerts

Highlight skills needing attention:

**Needs Repair** (avg < 50, 2+ runs):
```
⚠ <skill-name>: avg score <n>/100 — run /singularity-repair
```

**Ready to Crystallize** (avg >= 90, 5+ runs, hardened):
```
✦ <skill-name>: avg score <n>/100, <n> runs — run /singularity-crystallize
```

**Stale** (not used in 30+ days):
```
⏳ <skill-name>: last used <n> days ago — review relevance
```

### Step 5: Summary Stats

```
Total skills: <n>
  Draft: <n>  |  Tested: <n>  |  Hardened: <n>  |  Crystallized: <n>
  Average health: <overall-avg>/100
  Alerts: <n> needing repair, <n> ready to crystallize
```
