---
name: dashboard
description: Shows every singularity-tracked skill in one table (version, maturity, average score, scored runs, uses, trend, last used) with alerts for skills to repair, crystallize or retire. Use when the user wants an overview of their skills.
disable-model-invocation: true
---

# Dashboard

## Step 1: Load

```bash
jq '.skills' ~/.claude/singularity/registry.json
```

No skills: *"No skills tracked yet. Create one with `/singularity-claude:create`."*

## Step 2: Trend per skill

From `~/.claude/singularity/scores/<skill>.json`, compare the last two scores of the current version: up 5+ is `↑`, down 5+ is `↓`, otherwise `→`.

## Step 3: Table

```
| Skill            | Version | Maturity | Avg | Scored | Uses | Trend | Last used  |
|------------------|---------|----------|-----|--------|------|-------|------------|
| my-api-client    | v1.2.0  | hardened | 87  | 12     | 40   | ↑     | 2026-03-17 |
```

`Last used` comes from `lastUsed` (counted on every run), not from the last score.

## Step 4: Alerts

- Repair: average below 50 with 2+ scored runs → `/singularity-claude:repair <skill>`
- Crystallize: average 90+, 5+ scored runs, hardened → `/singularity-claude:crystallize <skill>`
- Unscored: 5+ uses but no score → score the next run with `/singularity-claude:score <skill>`
- Stale: not used in 30+ days → ask whether it is still needed

## Step 5: Totals

```
<n> skills · draft <n> · tested <n> · hardened <n> · crystallized <n>
Average <n>/100 · <n> to repair · <n> ready to crystallize
```
