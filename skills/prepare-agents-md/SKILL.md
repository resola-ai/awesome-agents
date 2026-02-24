---
name: prepare-agents-md
description: >
  Analyzes a project codebase and generates (or updates) a high-quality
  AGENTS.md knowledge priming document following Martin Fowler's recommended
  structure. Use this skill whenever a user asks to: "prepare AGENTS.md",
  "create a knowledge primer", "set up AI context docs", "write AGENTS.md",
  "help AI understand this project", "create onboarding docs for AI",
  "update AGENTS.md", or "refresh AGENTS.md".
  Also trigger when the user wants to update or refresh an existing AGENTS.md,
  or when a project has no AGENTS.md and the user is setting up AI tooling.
metadata:
  version: "1.0.0"
  author: michael
  tags: [documentation, agents, knowledge-priming, onboarding]
  license: MIT
---

# Prepare AGENTS.md

## When to Use

- User asks to "prepare AGENTS.md", "write AGENTS.md", or "create a knowledge primer"
- User wants to "help AI understand this project" or "set up AI context docs"
- User asks to "update AGENTS.md" or "refresh AGENTS.md" with latest changes
- A project has no AGENTS.md and is starting to adopt AI tooling
- An existing AGENTS.md is stale, incomplete, or missing key sections

---

## What You'll Produce

A concise, 1–3 page `AGENTS.md` with exactly these 7 sections (Fowler structure):

1. **Architecture Overview** — big picture: what the system is, major components, how they interact
2. **Tech Stack and Versions** — specific technologies + version numbers (critical — APIs change between versions)
3. **Curated Knowledge Sources** — 5–10 links: official docs, influential guides, internal ADRs/runbooks
4. **Project Structure** — annotated directory tree, 2 levels deep
5. **Naming Conventions** — explicit rules for files, functions, types, constants, booleans
6. **Code Examples** — 2–3 real examples from the codebase showing preferred patterns
7. **Anti-patterns to Avoid** — explicit list of what NOT to do, sourced from TODOs, code comments, or README warnings

For section-by-section guidance, see `references/fowler-structure.md`.

---

## Step 1 — Determine Mode (New vs. Update)

Check whether `AGENTS.md` already exists in the project root.

- **If it exists**: Read the full file. Note which sections are accurate, which are stale or missing, and any human-written content to preserve.
- **If it does not exist**: Proceed to research from scratch.

Do not overwrite or discard existing content without analyzing it first.

---

## Step 2 — Research the Codebase

Gather evidence systematically. Every claim in AGENTS.md must be verifiable from actual files.

### Tech Stack (required)
Read all of the following that exist:
- `package.json` / `package-lock.json` / `yarn.lock` / `bun.lockb` — for Node/JS projects
- `pyproject.toml` / `requirements.txt` / `setup.py` — for Python projects
- `go.mod` — for Go projects
- `Cargo.toml` — for Rust projects
- `build.gradle` / `pom.xml` — for JVM projects
- `Dockerfile` / `docker-compose.yml` — for runtime/infra context

Extract: language, runtime version, framework names + versions, major libraries.

### Architecture and Project Structure
- Run a directory listing 2 levels deep to map the layout
- Read `README.md`, `ARCHITECTURE.md`, `docs/DESIGN.md` if they exist
- Read any files in `docs/adrs/` or `docs/design-docs/` for architectural decisions
- Identify: entry points, core modules, build output directories, test directories

### Naming Patterns
- Scan source files in 2–3 representative directories (e.g. `src/`, `lib/`, `app/`)
- Note: file naming style (kebab-case, PascalCase, snake_case), function/variable conventions, boolean prefixes (`is`, `has`, `should`), constant casing

### Code Examples
- Find 2–3 short, representative code blocks (10–20 lines each) that show the project's preferred patterns
- Examples should be real, unmodified code from actual project files — not invented
- Good candidates: a typical API handler, a core utility function, a test structure

### Anti-patterns
- Search for `TODO`, `FIXME`, `HACK`, `XXX`, `DO NOT` comments in source files
- Check README for "avoid", "don't", "deprecated", "legacy" warnings
- Note any inconsistencies found during research (e.g. two different naming styles in use)

---

## Step 3 — Write the AGENTS.md

### General Rules
- **No fabrication**: Do not invent technology names, version numbers, patterns, or links. If you cannot verify a claim, omit it or mark it with `<!-- TODO: verify -->`.
- **Concise**: Target 1–3 pages. Move detailed content to linked files (e.g., `docs/ARCHITECTURE.md`) rather than expanding inline.
- **Real examples only**: Code blocks must come from actual project files. Include the source file path as a comment.
- **Version numbers matter**: Always include specific versions (e.g. `React 18.3`, `Python 3.11`, `Go 1.22`). "Latest" is not a version.

### Section-by-Section Instructions

See `references/fowler-structure.md` for detailed guidance on each section.

**Section 1 — Architecture Overview**
Write 3–5 sentences. Cover: what the system does, how major components relate, the primary data flow. Avoid marketing language.

**Section 2 — Tech Stack and Versions**
Use a table or bullet list. Include: language + version, runtime, framework + version, key libraries + versions, database/infra.

**Section 3 — Curated Knowledge Sources**
List 5–10 URLs. Prioritize: official docs for the frameworks/versions used, project-specific docs (ADRs, runbooks), influential references specific to the stack. Do not include generic "google it" links.

**Section 4 — Project Structure**
Show an annotated directory tree, 2 levels deep. Add a one-line comment next to each significant directory explaining its purpose.

**Section 5 — Naming Conventions**
Use a table or bullet list with explicit rules. Cover: file names, component/class names, function names, boolean variables, constants, test file names.

**Section 6 — Code Examples**
Include 2–3 fenced code blocks with a brief explanation before each. Add a comment showing the source file path.

**Section 7 — Anti-patterns to Avoid**
Bullet list of explicit "don't do this" items with brief explanations. Sourced from TODO comments, README warnings, or observed inconsistencies.

---

## Step 4 — Update Mode (if AGENTS.md already existed)

When updating an existing AGENTS.md:
1. Preserve all sections that are still accurate
2. Update version numbers if they've changed (verify from manifest files)
3. Add new sections that were missing
4. Add a brief `<!-- Updated: YYYY-MM-DD -->` comment at the top of modified sections
5. Do not delete human-written notes or project-specific annotations unless they are factually wrong

---

## Step 5 — Quality Check

Before reporting done, verify:

- [ ] All 7 sections are present
- [ ] File is 1–3 pages (roughly 200–600 lines max)
- [ ] No invented technology names or versions — every item verified from a project file
- [ ] All code examples come from real project files (path cited in comment)
- [ ] Anti-patterns section has at least 3 items
- [ ] Curated Knowledge Sources has 5–10 items with actual URLs (not placeholders)
- [ ] `name` field in frontmatter (if applicable) matches the project, not a template value

---

## Best Practices

- Read before writing — always check for existing AGENTS.md first
- Cite sources in code examples (`# from src/api/handler.go`)
- If a section cannot be populated accurately (e.g., no external docs exist yet), write a TODO comment rather than fabricating content
- Keep the file skimmable — AI agents and developers should be able to orient in under 2 minutes

---

## References

- `references/fowler-structure.md` — Detailed guidance for each of the 7 sections + a complete template
- Fowler article: https://martinfowler.com/articles/reduce-friction-ai/knowledge-priming.html
