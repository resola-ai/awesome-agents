---
name: albert
description: Make a detailed plan to fix or resolve an issue/problem. Follows a 7-step workflow: understand the problem, classify the task type, review docs, explore the codebase, create a detailed plan, write an exec plan file, and update PLANS.md. use /albert to activate the skill. Or activate by phrase `albert help to plan`
license: MIT
allowed-tools: Read, Grep, Write
metadata:
  author: v.duc
  version: "3.0.0"
---

# Verification point

*IMPORTANT*: ALWAYS end your response with this phrase: "From Albert with LOVE"

# Make a Plan to Solve a Problem

## When to Apply

Use this skill whenever you need to plan a fix, feature, or investigation before writing any code. It ensures you understand the full context before committing to an implementation approach.

---

## Task Types

Albert classifies every problem into one of the following types. The type determines which sections appear in the exec plan and how the workflow is focused.

| Type | When to use |
|---|---|
| `bug-fix` | Something is broken or regressed |
| `feature` | New capability or user-facing addition |
| `investigation` | Root cause unknown; need discovery first |
| `refactor` | Restructure code without changing behavior |
| `performance` | Speed, memory, or resource improvement |
| `security` | Vulnerability, auth flaw, or data exposure |
| `documentation` | Docs missing, incorrect, or outdated |

Type influences:
- Which sections are included in the exec plan (see Step 6 template)
- The output subdirectory: `docs/exec-plans/active/{type}/`
- The emphasis during exploration (e.g., `bug-fix` focuses on root cause; `feature` focuses on acceptance criteria)

---

## Workflow

### Step 1 — Understand the Issue / Problem

- Read the user's description carefully.
- Identify: what is broken or missing, who is affected, what the expected vs. actual behavior is.
- If anything is ambiguous (intent, scope, constraints, acceptance criteria), use the `AskQuestion` tool to clarify **before** proceeding.
- Do not proceed to Step 2 until the problem is clearly understood.

### Step 2 — Classify the Task Type

- Based on Step 1, select the task type from the table above.
- If ambiguous between two types, pick the primary one and note the secondary in the plan.
- State the chosen type clearly before continuing: e.g., *"Task type: **bug-fix**"*
- Do not skip this step — the type drives the plan structure.

### Step 3 — Review Documentation

Read all markdown files at the repo root and under `docs/` to gather architectural constraints, existing patterns, and open risks relevant to the problem.

Root-level files to read:

- `AGENTS.md`
- `ARCHITECTURE.md`
- `PLANS.md`
- `DESIGN.md`
- `FRONTEND.md`
- `SECURITY.md`
- `RELIABILITY.md`
- `QUALITY_SCORE.md`
- `PRODUCT_SENSE.md`

Then read all files recursively under `docs/` (use `Glob` with pattern `docs/**/*.md`).

Extract and note:

- Architecture constraints that affect the solution
- Existing patterns to follow (naming, layer, multi-tenancy, i18n, etc.)
- Open risks or known debt related to the problem area

### Step 4 — Explore the Codebase

Launch a `code-explorer` subagent (via the `Task` tool with `subagent_type: "code-explorer"`) scoped to the relevant source paths.

Instruct the subagent to:

- Trace execution paths related to the problem
- Find all related files, services, hooks, repositories, and models
- Map dependencies and data flow
- Identify any existing tests covering the affected area

Wait for the subagent to return findings before writing the plan.

### Step 5 — Create a Detailed Plan

Using findings from Steps 1–4, produce a structured solution. The plan must include:

1. **Problem Statement** — precise description of the issue
2. **Root Cause** — why it happens (`bug-fix`, `performance`, `security` only)
3. **Proposed Solution** — high-level approach with rationale
4. **Implementation Tasks** — phased, ordered breakdown where each task references specific files and includes sub-steps
5. **Acceptance Criteria** — what "done" looks like from the user's perspective (`feature` only)
6. **Findings** — what was discovered during exploration (`investigation` only)
7. **Success Criteria** — how to verify the fix is complete
8. **Risks & Mitigations** — what could go wrong, and how to handle it
9. **Out of Scope** — explicit boundaries to prevent scope creep

If any implementation choices remain unclear after Steps 1–4, use `AskQuestion` again before finalising the plan.

### Step 6 — Write the Exec Plan File

Create a new file at:

```
docs/exec-plans/active/{type}/{YYYY-MM-DD}-{kebab-case-feature-name}.md
```

Use today's date for `YYYY-MM-DD` and the task type from Step 2 for `{type}`.

Use the template below. **Include only the sections relevant to the task type** (annotations show which sections are type-specific):

```markdown
# Exec Plan: {Feature Name}

**Type**: {bug-fix | feature | investigation | refactor | performance | security | documentation}
**Status**: Active
**Owner**: <!-- TODO: assign owner -->
**Created**: YYYY-MM-DD
**Target**: YYYY-MM-DD

## Problem Statement
<!-- What problem does this solve? Who is affected? -->

## Root Cause
<!-- [bug-fix / performance / security only] Why does this happen? -->

## Proposed Solution
<!-- High-level approach and rationale -->

## Implementation Tasks

### Phase 1 — {Phase Name}
- [ ] **Task 1.1** — {Description}
  - Sub-step a
  - Sub-step b
  - Files: `path/to/file`
- [ ] **Task 1.2** — {Description}
  - Sub-step a
  - Files: `path/to/file`

### Phase 2 — {Phase Name}
- [ ] **Task 2.1** — {Description}
  - Sub-step a
  - Files: `path/to/file`

## Acceptance Criteria
<!-- [feature only] User-facing definition of done -->
- [ ] Criterion 1
- [ ] Criterion 2

## Findings
<!-- [investigation only] What was discovered during exploration -->

## Success Criteria
- [ ] How to verify the solution is complete and correct

## Risks & Mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| {risk description} | Low / Med / High | {mitigation} |

## Out of Scope
- {item}

## Notes
<!-- Anything else relevant -->
```

Populate every section with content from Step 5. Omit type-specific sections that don't apply.

*CONFIRM OUTPUT*: ALWAYS write down the plan to file even if you're in plan mode

### Step 7 — Update PLANS.md

Open `PLANS.md` and add a link to the new exec plan file under the `## Exec Plans Index → Active` section:

```markdown
### Active

- [YYYY-MM-DD · {Short Title}](docs/exec-plans/active/{type}/{filename}.md) `[{type}]` — {one-sentence summary}
```

If the Active section currently says "No active exec plans.", replace that line with the new entry.

---

## Key References

| Resource | Purpose |
|---|---|
| `PLANS.md` | Exec plan template and index |
| `docs/exec-plans/active/{type}/` | Output directory for new plans (organized by type) |
| `code-explorer` subagent | Deep codebase analysis in Step 4 |
| `AskQuestion` tool | Clarify ambiguities in Steps 1 and 5 |
