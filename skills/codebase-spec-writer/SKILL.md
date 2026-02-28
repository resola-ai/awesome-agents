---
name: codebase-spec-writer
description: >
  Scans a codebase using MCP tools (Serena, Filesystem, GitHub, or similar) and automatically
  generates product specification documents — one Markdown file per feature, organized by
  folder/module structure. Use this skill whenever the user asks to "document the codebase",
  "generate product specs", "write feature specs from code", "reverse-engineer documentation",
  or wants to understand what a codebase does in product terms. Also trigger when users say
  things like "create specs for my repo", "document my features", "what does each module do",
  or "generate a spec doc". Works with any language or framework.
---

# Codebase Spec Writer

Scans a codebase and produces one product specification Markdown file per top-level feature/module.

---

## Phase 1: Discover Available Tools

Before doing anything else, check which MCP tools are available:

- **Serena** — preferred for deep code intelligence (symbol lookup, call graphs, semantic search)
- **Filesystem MCP** — for directory listing and file reading
- **GitHub MCP** — for remote repos (list files, read contents, search code)

Use whatever is available. If multiple are present, prefer Serena for analysis and Filesystem/GitHub for directory structure.

---

## Phase 2: Map the Codebase Structure

1. **Get the root directory** — ask the user for the repo path or URL if not already provided.
2. **List top-level folders** — these become your candidate features.
3. **Filter out non-feature folders** — ignore common infrastructure folders:
   - `node_modules`, `vendor`, `.git`, `dist`, `build`, `out`, `coverage`, `__pycache__`
   - `assets`, `static`, `public` (unless they contain significant logic)
   - Config-only folders: `.github`, `.vscode`, `infra` (flag these separately)
4. **Present the feature list to the user** — confirm or let them add/remove/rename before proceeding.

Example output to show user:
```
Detected features/modules:
  ✓ auth/
  ✓ dashboard/
  ✓ billing/
  ✓ api/
  ✗ node_modules/ (skipped)
  ✗ dist/ (skipped)

Shall I generate specs for all 4 features? Or would you like to adjust this list?
```

---

## Phase 3: Analyze Each Feature

For each confirmed feature folder, perform the following analysis. Use Serena where available for deeper insight; fall back to direct file reading otherwise.

### 3a. Collect Raw Data

For each feature folder:
- List all files and subdirectories
- Read key files: entry points (`index.*`, `main.*`, `app.*`), route files, controller files, service files, README if present
- If using Serena: use symbol search, call graph, and semantic search to identify public interfaces
- If using GitHub MCP: use search_code to find usages of this module from other parts of the codebase

### 3b. Extract Signal

From the raw data, identify:
- **What it does** — the core purpose in 1-2 sentences
- **Who uses it** — other modules that import/call it, or external users (API consumers, UI users)
- **Key entry points** — main functions, classes, API routes, CLI commands
- **Data it touches** — database models, schemas, key data structures
- **Dependencies** — other internal modules it depends on; notable external packages
- **Configuration** — environment variables, config keys it reads
- **Notable edge cases** — error handling patterns, feature flags, TODOs/FIXMEs in code

---

## Phase 4: Write the Spec Document

For each feature, produce a Markdown file using this template:

```markdown
# [Feature Name] — Product Specification

**Module path:** `path/to/module/`
**Last analyzed:** [today's date]
**Status:** [Active / In Progress / Deprecated — infer from code signals if possible]

---

## Overview

[2-4 sentence plain-English summary of what this feature does and why it exists.]

---

## User Stories

[Inferred from the code. Each story follows: "As a [user type], I can [action] so that [outcome]."]

- As a [role], I can ...
- As a [role], I can ...

---

## Core Functionality

[List the main things this module does. Be concrete — reference real function/class names.]

| Capability | Description | Key File(s) |
|---|---|---|
| [e.g. User login] | [What it does] | `auth/login.ts` |
| ... | ... | ... |

---

## Technical Implementation

### Entry Points
[List main entry points: exported functions, API routes, CLI commands, event listeners]

### Data Models
[Key data structures, database tables, or schemas this feature owns or heavily uses]

### Key Dependencies
**Internal:** [other modules from this repo it depends on]
**External:** [notable npm/pip/etc packages]

### Configuration
[Environment variables or config keys this module reads, with brief description]

---

## API / Interface

[If this module exposes an API (REST, GraphQL, function exports, events), document it here.]

[If no external API: write "Internal module — no public API exposed."]

---

## Known Limitations & Edge Cases

[Inferred from TODOs, FIXMEs, error handling patterns, or comments in code. If none found, write "None identified during automated analysis."]

---

## Open Questions

[Things that are unclear from the code alone — ambiguous business logic, undocumented behavior, etc. Flag these for the human to fill in.]

---

*This spec was auto-generated by the codebase-spec-writer skill. Review and update as needed.*
```

---

## Phase 5: Output Files

- Save each spec to an `output/specs/` directory (or wherever the user specifies)
- Name files: `[feature-name]-spec.md` (lowercase, hyphenated)
- After all files are written, generate a `README-specs.md` index file:

```markdown
# Product Specifications Index

Generated: [date]
Source: [repo path or URL]

## Features

| Feature | Spec File | Status |
|---|---|---|
| Auth | [auth-spec.md](./auth-spec.md) | Active |
| Dashboard | [dashboard-spec.md](./dashboard-spec.md) | Active |
...
```

- Present all files to the user using the `present_files` tool
- Summarize: how many specs were generated, any features that were skipped or flagged

---

## Tips & Edge Cases

**Monorepos**: Treat each package/app as a top-level feature group. Go one level deeper if packages themselves have feature subfolders.

**Flat codebases**: If there are no meaningful subfolders (everything is at root), group by file type or naming convention (e.g. all `*Controller.*` files = one feature group).

**Large features**: If a folder has 50+ files, don't try to read everything. Prioritize: entry points → route/controller files → service files → models. Skip test files, generated files, and config files.

**Insufficient signal**: If a folder is too sparse to write a meaningful spec, write a short stub with an "Open Questions" section noting what's missing, rather than skipping it.

**Language detection**: Detect the primary language from file extensions. Adjust terminology accordingly (e.g. "routes" for web apps, "handlers" for Go, "controllers" for Rails, "resolvers" for GraphQL).

---

## Reference

See `references/spec-template.md` for the full annotated spec template with inline guidance notes.
