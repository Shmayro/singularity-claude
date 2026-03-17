# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in singularity-claude, please report it responsibly.

**Do NOT open a public issue.**

Instead, email the maintainer directly or use [GitHub's private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability).

## Scope

singularity-claude stores data locally at `~/.claude/singularity/`. Security concerns include:

- **Score/telemetry data integrity** — JSON files should not be tampered with
- **Script injection** — Shell scripts must sanitize inputs
- **Skill content injection** — Generated SKILL.md files should not contain malicious instructions

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.1.x   | Yes       |
