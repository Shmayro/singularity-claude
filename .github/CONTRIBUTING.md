# Contributing to singularity-claude

Thanks for your interest in contributing! Here's how to get started.

## Ways to Contribute

- **Report bugs** — Open an issue with the bug report template
- **Suggest features** — Open an issue with the feature request template
- **Improve skills** — Enhance existing SKILL.md files with better instructions
- **Add scoring dimensions** — Propose new rubric criteria
- **Fix scripts** — Improve score-manager.sh or telemetry-writer.sh
- **Write docs** — Help with examples, guides, or translations
- **Platform support** — Add Cursor, Codex, or Gemini CLI compatibility

## Development Setup

```bash
# Fork and clone
git clone https://github.com/<your-username>/singularity-claude.git
cd singularity-claude

# Install locally for testing
claude plugin marketplace add .
claude plugin install singularity-claude

# Start a new Claude Code session to test
```

## Making Changes

### Skills

Skills live in `skills/<skill-name>/SKILL.md`. Follow these conventions:

- **Frontmatter**: `name` (kebab-case) + `description` (starts with "Use when...")
- **Description max**: 500 characters — triggers only, not workflow summary
- **Structure**: Overview → When to use → Workflow → Common mistakes → Red flags

### Scripts

Scripts live in `scripts/`. They must:

- Work with `jq` (preferred) and fall back to `node -e`
- Use atomic writes (temp file + `mv`)
- Include `set -euo pipefail`
- Pass [ShellCheck](https://www.shellcheck.net/)

### Agents

Agents live in `agents/<agent-name>.md`. They must:

- Use `model: haiku` for cost efficiency
- Return structured JSON only
- Include clear input/output contracts

## Submitting a Pull Request

1. Fork the repo
2. Create a feature branch: `git checkout -b feat/my-improvement`
3. Make your changes
4. Test locally by installing and using the plugin
5. Commit with [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `docs:`, etc.
6. Push and open a PR

## Commit Convention

```
<type>: <subject>

Types:
  feat     New skill, agent, or feature
  fix      Bug fix
  docs     Documentation only
  refactor Code restructure without behavior change
  test     Adding or updating tests
  chore    Build, CI, tooling changes
```

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). Be respectful and constructive.

## Questions?

Open a [discussion](https://github.com/shmayro/singularity-claude/discussions) or an issue. We're happy to help!
