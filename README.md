# Agent Skills

A collection of reusable agent skills following the **Agent Skills open standard**. These skills are portable across any agent platform that supports the standard (Cursor, Claude Code, Codex, OpenCode, Gemini CLI, Amp, etc.).

## What are Agent Skills?

Agent Skills is an open standard for extending AI agents with specialized capabilities. Skills package domain-specific knowledge and workflows that agents can use to perform specific tasks.

### Key Features

- **Portable**: Works across any agent that supports the Agent Skills standard
- **Version-controlled**: Stored as files in your repository
- **Executable**: Can include scripts and code that agents execute
- **Progressive**: Loads resources on demand, keeping context usage efficient

Learn more: [Agent Skills Documentation](https://agentskills.io) | [Cursor Skills Docs](https://cursor.com/docs/context/skills)

## Getting Started

### Skill Structure

Each skill is defined in a single `SKILL.md` file with YAML frontmatter:

```
skills/my-skill/
├── SKILL.md           # Main skill definition with YAML frontmatter
├── scripts/           # Optional: Executable scripts
├── references/        # Optional: Detailed docs loaded on demand
└── assets/            # Optional: Templates, configs, data files
```

### SKILL.md Format

```markdown
---
name: my-skill
description: What this skill does and when to use it.
disable-model-invocation: false
metadata:
  version: "1.0.0"
  author: ""
  tags: []
---

# My Skill

## When to Use
- Use this skill when...

## Instructions
Step-by-step guidance for the agent.
```

### Creating a New Skill

1. Copy the template:
   ```bash
   cp -r skills/_template skills/my_new_skill
   ```

2. Edit `skills/my_new_skill/SKILL.md`:
   - Update the YAML frontmatter (name, description, metadata)
   - Ensure the `name` field matches the folder name exactly
   - Write the skill instructions in the markdown body

3. Add optional directories as needed:
   - `scripts/` - Executable code (bash, python, etc.)
   - `references/` - Detailed documentation
   - `assets/` - Templates, configs, data files

4. Test locally, then commit

### Installing Skills

#### Option 1: User-Level (Global)

Copy the skill directory to your agent's user-level skills directory:

```bash
# For Cursor
cp -r skills/markdown_crawl ~/.cursor/skills/

# For Claude Code
cp -r skills/markdown_crawl ~/.claude/skills/

# For Codex CLI
cp -r skills/markdown_crawl ~/.codex/skills/
```

#### Option 2: Project-Level

Copy the skill directory to your project's skills directory:

```bash
# For Cursor
cp -r skills/markdown_crawl .cursor/skills/

# For Claude Code
cp -r skills/markdown_crawl .claude/skills/

# For Codex CLI
cp -r skills/markdown_crawl .codex/skills/
```

After installing, restart the agent CLI so it reloads skills.

#### Supported Skill Directories

Skills are automatically loaded from these locations:

| Location | Scope |
|----------|-------|
| `.cursor/skills/` | Project-level |
| `.claude/skills/` | Project-level (Claude compatibility) |
| `.codex/skills/` | Project-level (Codex compatibility) |
| `~/.cursor/skills/` | User-level (global) |
| `~/.claude/skills/` | User-level (global, Claude compatibility) |
| `~/.codex/skills/` | User-level (global, Codex compatibility) |

## Available Skills

### markdown_crawl

Fetch web content in markdown format using Cloudflare's "Markdown for Agents" feature. Tracks metrics like token savings and usage statistics.

**Use when**: Fetching web pages, documentation sites, or converting HTML to markdown.

### setup-agent-cli-hooks

Set up hooks and lifecycle configurations for multiple AI coding agent CLIs (Claude Code, Codex, OpenCode, Gemini CLI, and Amp).

**Use when**: Configuring automation, lifecycle events, or shared hook scripts across different agent platforms.

## Repository Layout

| Path | Description |
|------|-------------|
| `AGENTS.md` | Project guidelines and conventions |
| `README.md` | This file - project overview |
| `skills/` | Individual skill modules |
| `skills/_template/` | Starter template for new skills |

## Skill Development Guidelines

See [AGENTS.md](./AGENTS.md) for:
- Skill naming conventions
- SKILL.md format and frontmatter fields
- Optional directories (scripts, references, assets)
- Development workflow
- Code review checklist

## Contributing

1. Create your skill directory under `skills/`
2. Follow the conventions in [AGENTS.md](./AGENTS.md)
3. Ensure `SKILL.md` has valid YAML frontmatter
4. Ensure the `name` field matches the folder name exactly
5. Submit a pull request

## Learn More

- **Agent Skills Standard**: https://agentskills.io
- **Cursor Skills Documentation**: https://cursor.com/docs/context/skills
- **Project Guidelines**: [AGENTS.md](./AGENTS.md)
