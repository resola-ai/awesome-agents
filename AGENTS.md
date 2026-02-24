## Project Overview

This repository contains a collection of reusable agent skills following the Agent Skills open standard. Each skill is a self-contained, portable module that works across any agent that supports the Agent Skills standard (Cursor, Claude Code, etc.). Skills include both instructions and optional executable scripts.

## Repository Structure

```
agent-skills/
├── AGENTS.md              # This file - project guidelines
├── README.md              # Project overview and usage
├── .gitignore             # Git ignore rules
└── skills/                # Individual skill modules
    ├── <skill-name>/      # One directory per skill
    │   ├── SKILL.md       # Skill definition with YAML frontmatter
    │   ├── scripts/       # Optional: Executable scripts
    │   ├── references/    # Optional: Detailed docs loaded on demand
    │   └── assets/        # Optional: Templates, data files, etc.
    └── _template/         # Template for creating new skills
```

## Conventions

### Skill Naming
- Use lowercase with underscores for skill directory names (e.g., `markdown_crawl`, `setup_agent_cli_hooks`)
- Skill names should be descriptive and action-oriented
- **CRITICAL**: The `name` field in YAML frontmatter MUST match the parent folder name exactly

### Skill Structure
Each skill directory must contain:
- `SKILL.md` - Main skill file with YAML frontmatter and instructions

Optional directories:
- `scripts/` - Executable code that agents can run (bash, python, etc.)
- `references/` - Additional documentation loaded on demand for efficiency
- `assets/` - Static resources like templates, images, or data files

### SKILL.md Format

Each skill is defined in a `SKILL.md` file with YAML frontmatter:

```markdown
---
name: skill-name
description: Brief description of what this skill does and when to use it.
disable-model-invocation: false
metadata:
  version: "1.0.0"
  author: ""
  tags: []
  license: ""
compatibility: "Optional environment requirements"
---

# Skill Name

## When to Use

- Use this skill when...
- This skill is helpful for...

## Instructions

Detailed step-by-step instructions for the agent.

## Examples

Example usage and outputs.
```

### Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Skill identifier. Must match parent folder name. Lowercase, numbers, underscores/hyphens only. |
| `description` | Yes | Describes what the skill does and when to use it. Used by agents to determine relevance. |
| `disable-model-invocation` | No | When `true`, skill is only used when explicitly invoked (like a slash command). Default: `false` |
| `metadata` | No | Arbitrary key-value mapping (version, author, tags, etc.) |
| `license` | No | License name or reference to a bundled license file. |
| `compatibility` | No | Environment requirements (system packages, network access, etc.) |

### Writing Skill Instructions
- Start with a "When to Use" section describing relevant scenarios
- Be specific and unambiguous in instructions
- Include examples where helpful
- Define expected inputs and outputs clearly
- Use markdown formatting for readability
- Keep main `SKILL.md` focused; move detailed docs to `references/`

## Development Workflow

1. Copy `skills/_template/` to `skills/<your-skill-name>/`
2. Rename `SKILL.md` and update the YAML frontmatter with skill metadata
3. Write the agent instructions in the markdown body of `SKILL.md`
4. Add executable scripts to `scripts/` if needed
5. Move detailed reference docs to `references/` for on-demand loading
6. Add static assets (templates, configs) to `assets/` if needed
7. **IMPORTANT**: Ensure the `name` field in frontmatter matches the folder name exactly
8. Test the skill locally before committing

## Code Review Checklist

- [ ] Skill has a valid `SKILL.md` with YAML frontmatter
- [ ] `name` field in frontmatter matches the folder name exactly
- [ ] `description` field clearly states what the skill does and when to use it
- [ ] YAML frontmatter is valid and properly formatted
- [ ] Instructions include a "When to Use" section
- [ ] No sensitive data or credentials in any files
- [ ] Scripts in `scripts/` are executable and have clear error messages
- [ ] Detailed docs are in `references/` to keep context efficient

## Agent Skills Standard

This repository follows the Agent Skills open standard. Learn more:
- **Official Site**: https://agentskills.io
- **Cursor Documentation**: https://cursor.com/docs/context/skills
- **Standard Benefits**: Portable across agents, version-controlled, executable, progressive loading