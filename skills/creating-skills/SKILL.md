---
name: creating-skills
description: Use when a new reusable skill needs to be built, either detected by gap analysis, requested by the user, or triggered by /singularity-create
---

# Create a New Skill

Build a new Claude Code skill through a structured workflow that ensures quality, testability, and integration with the singularity evolution engine.

## Prerequisites

- Read `superpowers:writing-skills` if available — it defines SKILL.md authoring best practices
- This skill creates standard Claude Code skills usable by any plugin

## Workflow

### Step 1: Requirements Gathering

Ask the user ONE question at a time:

1. **What** does this skill do? (core purpose in one sentence)
2. **When** should it trigger? (symptoms, conditions, error messages)
3. **What tools** does it need? (Read, Write, Edit, Bash, Agent, etc.)
4. **What's the output?** (files created, code modified, analysis produced)

### Step 2: Check Registry

Read `~/.claude/singularity/registry.json` to verify no duplicate or overlapping skill exists.

If a similar skill exists, ask: *"A skill called '<name>' already covers <overlap>. Should I extend it or create a separate skill?"*

### Step 3: Generate SKILL.md

Create the skill following these conventions:

```yaml
---
name: <skill-name>  # kebab-case, verb-first (e.g., creating-api-clients)
description: Use when <triggering conditions>  # Max 500 chars, start with "Use when"
---
```

**Content structure:**
- Overview (1-2 sentences)
- When to use / when NOT to use
- Workflow steps (numbered, actionable)
- Common mistakes / red flags
- Integration with other skills (if applicable)

**Rules:**
- Description = triggering conditions ONLY, not what the skill does
- Keep under 500 words for frequently-used skills
- Use cross-references (`superpowers:skill-name`) not file paths
- Include a "When NOT to use" section

### Step 4: Write the Skill

Write to `~/.claude/skills/<skill-name>/SKILL.md`

If the skill needs supporting files (templates, rubrics, scripts), create them in:
`~/.claude/skills/<skill-name>/references/`

### Step 5: Register

Update `~/.claude/singularity/registry.json`:

```bash
# Using score-manager to initialize scoring
"${CLAUDE_PLUGIN_ROOT}/scripts/score-manager.sh" init <skill-name>
```

Then update registry.json to add the skill entry:
```json
{
  "skills": {
    "<skill-name>": {
      "location": "~/.claude/skills/<skill-name>/SKILL.md",
      "createdBy": "singularity-claude:creating-skills",
      "createdAt": "<ISO-8601>",
      "currentVersion": "v1.0.0",
      "maturity": "draft",
      "tags": ["<relevant>", "<tags>"],
      "lastExecuted": null,
      "executionCount": 0,
      "averageScore": 0
    }
  }
}
```

### Step 6: Initial Test

Invoke the newly created skill via the `Skill` tool to verify it loads correctly.

### Step 7: Initial Score

Run `singularity-claude:scoring` on the test output to establish a baseline score.

### Step 8: Log Telemetry

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/telemetry-writer.sh" log <skill-name> \
  --trigger "creation" \
  --summary "Created new skill: <description>"
```

## Output

After creation, report:
- Skill location: `~/.claude/skills/<skill-name>/SKILL.md`
- Initial version: v1.0.0
- Maturity: draft
- Next steps: use the skill, then score with `/singularity-score`
