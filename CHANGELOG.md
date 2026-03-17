# Changelog

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
