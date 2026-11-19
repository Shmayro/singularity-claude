# Changelog

## [0.2.0] - 2026-11-20

### Breaking
- Skill folders renamed so the commands are short and actually exist. Plugin skills are always invoked as `/<plugin>:<skill>`; the `/singularity-create`-style commands advertised in 0.1.0 never existed. New commands: `/singularity-claude:create`, `:score`, `:repair`, `:review`, `:crystallize`, `:dashboard`.

### Added
- `hooks/log-use`: counts every run of a tracked skill, whether Claude invoked it (`PostToolUse` on the Skill tool) or you typed its command (`UserPromptExpansion`). Registry gets `useCount` and `lastUsed`.
- `score-manager.sh register | used | bump | crystallize`. It is now the only writer of `registry.json`; `add` keeps the registry in sync.
- Repair backs up the skill to `~/.claude/singularity/backups/` before editing and restores it if the new version does not score better.
- `tests/run.sh`: end-to-end checks of scripts and hooks, run in CI.

### Changed
- Session start no longer injects the `using-singularity` skill into every session. It only reports skills to repair or crystallize, as plain facts, and reads thresholds from `config.json`.
- Descriptions follow current Claude Code guidance: what the skill does and when to use it. Repair, review, crystallize and dashboard are user-only (`disable-model-invocation`); skills taking a skill name have `argument-hint`.
- `create` points to Anthropic's `skill-creator` for writing and testing when it is installed.

## [0.1.0] - 2026-03-17

### Added
- Initial plugin structure with `.claude-plugin/` registration
- **using-singularity** skill — bootstrap context injected at session start
- **creating-skills** skill — meta-skill for building new Claude Code skills
- **scoring** skill — 5-dimension rubric (Correctness, Completeness, Edge Cases, Efficiency, Reusability)
- **repairing** skill — auto-fix failing skills through diagnosis and targeted rewrite
- **crystallizing** skill — lock validated versions via git tags
- **reviewing** skill — health check with trend analysis and recommendations
- **dashboard** skill — overview table of all managed skills with alerts
- **skill-assessor** agent (haiku) — automated scoring subagent
- **gap-detector** agent (haiku) — capability gap analysis subagent
- **score-manager.sh** — CLI for managing score JSON files
- **telemetry-writer.sh** — CLI for structured execution logging
- SessionStart hook with alert injection
- Data storage at `~/.claude/singularity/` (scores, telemetry, registry, config)
- Maturity progression: draft → tested → hardened → crystallized
