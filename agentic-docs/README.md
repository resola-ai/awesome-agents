# agentic-docs

A Claude Code plugin for AI-powered document infrastructure. Bootstraps a comprehensive, project-specific documentation system by analyzing your codebase and populating a standard set of architecture and design documents.

## Features

- **`/agentic-docs:setup`** — Initializes the full documentation framework, including root-level docs and a detailed `docs/` structure.
- **Project Research** — Automatically scans manifests, source files, database schemas, and git history to understand your project.
- **Intelligent Population** — Writes project-specific content (not boilerplate) for architecture, design, security, reliability, and more.
- **Maintenance** — Merges new insights into existing documents without overwriting accurate manual edits.

## Agents

| Agent | Model | Role |
|-------|-------|------|
| `doc-setup` | Sonnet | Researches codebase and bootstraps the entire documentation system |

## Installation

```bash
# Option 1: Reference directly
claude --plugin-dir /path/to/agentic-docs

# Option 2: Add to your project's .claude/settings.json
{
  "plugins": ["/path/to/agentic-docs"]
}
```

## Setup

No additional setup required. The plugin uses your existing Claude Code session.

## Usage

### Initialize Documentation

```bash
/agentic-docs:setup
```

You can also trigger it with natural language:
- "Setup docs for this project"
- "Bootstrap the documentation framework"
- "Initialize documentation layout"

## Document Structure

The `doc-setup` agent creates and maintains the following structure:

- **Root Documents**:
  - `AGENTS.md` — Agent navigation hub and documentation map.
  - `ARCHITECTURE.md` — High-level system design and tech stack overview.
- **`docs/` Directory**:
  - `DESIGN.md` — Design principles and patterns.
  - `FRONTEND.md` — Frontend architecture and conventions.
  - `PLANS.md` — Engineering roadmap and execution plans.
  - `PRODUCT_SENSE.md` — Product vision and user journeys.
  - `QUALITY_SCORE.md` — Code quality assessment and gaps.
  - `RELIABILITY.md` — Reliability practices and SLOs.
  - `SECURITY.md` — Security posture and authentication patterns.
  - `generated/db-schema.md` — Auto-derived database schema reference.
  - `exec-plans/` — Active and completed technical execution plans.
  - `design-docs/` — Index of technical design decisions.
  - `product-specs/` — Index of product specifications.

## How It Works

1. **Research Phase**: The agent scans project manifests (`package.json`, etc.), directory layout, source code, configs, database schemas, and git history.
2. **Structure Creation**: Creates the standardized directory hierarchy using `mkdir -p`.
3. **Drafting Phase**: Generates project-specific content for each file based on the research findings.
4. **Validation Phase**: Reports what was created, what was updated, and identifies areas requiring manual attention.

## Planned Features


## Version

`0.1.0`
