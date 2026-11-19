---
name: create
description: Builds a new reusable skill in ~/.claude/skills/ and starts tracking it with singularity (registry entry, score file, first test run). Use when the user asks for a new skill, or agrees to turn a procedure they keep repeating into one.
argument-hint: "[what the skill should do]"
---

# Create a skill

Build a skill that Claude Code can load, then register it so singularity counts its uses and scores.

If the `skill-creator` skill is available, prefer it for writing and testing the SKILL.md itself (interview, test prompts, evals), then come back here for steps 4-6 to register it.

## Step 1: Requirements

Ask the user one question at a time:

1. What does the skill do? One sentence.
2. When should it run? What the user says, or what situation triggers it.
3. What does it produce? Files, code changes, a report.
4. What can go wrong? Inputs or situations it must handle.

## Step 2: Check for overlap

```bash
jq -r '.skills | keys[]' ~/.claude/singularity/registry.json
ls ~/.claude/skills/
```

If a similar skill exists, ask: *"'<name>' already covers <overlap>. Extend it, or create a separate skill?"*

## Step 3: Write the SKILL.md

Write `~/.claude/skills/<skill-name>/SKILL.md`. Supporting files (templates, scripts, reference docs) go next to it, one level deep, linked from the SKILL.md.

```yaml
---
name: <skill-name>        # lowercase, digits and hyphens, matches the folder name, max 64 chars
description: <what it does> + <when to use it>   # third person, max 1024 chars
---
```

Rules (from the current Claude Code skill guidance):
- The description is how Claude decides to load the skill: say what it does and when to use it, with the words a user would actually say. Lean slightly toward triggering; skills tend to under-trigger.
- Keep the SKILL.md under 500 lines. Move long reference material into separate files.
- Add `disable-model-invocation: true` if only the user should start it (deploys, anything with side effects).
- Add `argument-hint` if it takes an argument.

Template: `references/skill-template.md`.

## Step 4: Register

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/score-manager.sh" register <skill-name> --tags '["<tag>", "<tag>"]'
```

This creates the score file and the registry entry. Never edit `registry.json` by hand: `score-manager.sh` is its only writer.

## Step 5: Test once

Run the new skill on one realistic task from step 1 (invoke it with the Skill tool). Fix anything that breaks before going further.

## Step 6: Score the test run

Run `singularity-claude:score` on that run to set the baseline.

## Report

- Location: `~/.claude/skills/<skill-name>/SKILL.md`
- Version: v1.0.0, maturity: draft
- Next: use it on real tasks; each use is counted automatically. Score runs with `/singularity-claude:score <skill-name>`.
