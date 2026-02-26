---
name: albert
description: Make a detailed plan to fix or resolve an issue/problem. Follows a 6-step workflow: understand the problem, review docs, explore the codebase, create a detailed plan, write an exec plan file, and update PLANS.md. use /albert to activate the skill. Or activate by phrase `albert help to plan`
license: MIT
metadata:
  author: v.duc
  version: "2.0.0"
---

# Make a Plan to Solve a Problem

## When to Apply

Use this skill whenever you need to plan a fix, feature, or investigation before writing any code. It ensures you understand the full context before committing to an implementation approach.

---

## Workflow

### Step 1 — Understand the Issue / Problem

- Read the user's description carefully.
- Identify: what is broken or missing, who is affected, what the expected vs. actual behavior is.
- If anything is ambiguous (intent, scope, constraints, acceptance criteria), use the `AskQuestion` tool to clarify **before** proceeding.
- Do not proceed to Step 2 until the problem is clearly understood.

### Step 2 — Review Documentation

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

### Step 3 — Explore the Codebase

Launch a `code-explorer` subagent (via the `Task` tool with `subagent_type: "code-explorer"`) scoped to the relevant source paths.

Instruct the subagent to:

- Trace execution paths related to the problem
- Find all related files, services, hooks, repositories, and models
- Map dependencies and data flow
- Identify any existing tests covering the affected area

Wait for the subagent to return findings before writing the plan.

### Step 4 — Create a Detailed Plan

Using findings from Steps 1–3, produce a structured solution. The plan must include:

1. **Problem Statement** — precise description of the issue
2. **Root Cause** — why it happens (if known)
3. **Proposed Solution** — high-level approach with rationale
4. **Implementation Steps** — ordered, file-level checklist (each step references specific files)
5. **Success Criteria** — how to verify the fix is complete
6. **Risks** — what could go wrong, and mitigations
7. **Out of Scope** — explicit boundaries to prevent scope creep

If any implementation choices remain unclear after Steps 1–3, use `AskQuestion` again before finalising the plan.

### Step 5 — Write the Exec Plan File

Create a new file at:

```
docs/exec-plans/active/{YYYY-MM-DD}-{kebab-case-feature-name}.md
```

Use today's date for `YYYY-MM-DD`. Use the template from `PLANS.md` (reproduced below for convenience):

```markdown
# Exec Plan: {Feature Name}

**Status**: Active
**Owner**: <!-- TODO: assign owner -->
**Created**: YYYY-MM-DD
**Target**: YYYY-MM-DD

## Problem Statement
What problem does this solve?

## Proposed Solution
High-level approach.

## Implementation Steps
- [ ] Step 1
- [ ] Step 2
- [ ] Step 3

## Success Criteria
How do we know it's done?

## Risks
What could go wrong?

## Notes
Anything else relevant.
```

Populate every section with the content produced in Step 4.

### Step 6 — Update PLANS.md

Open `PLANS.md` and add a link to the new exec plan file under the `## Exec Plans Index → Active` section:

```markdown
### Active

- [YYYY-MM-DD · {Short Title}](docs/exec-plans/active/{filename}.md) — {one-sentence summary}
```

If the Active section currently says "No active exec plans.", replace that line with the new entry.

---

## Key References

| Resource | Purpose |
|---|---|
| `PLANS.md` | Exec plan template and index |
| `docs/exec-plans/active/` | Output directory for new plans |
| `code-explorer` subagent | Deep codebase analysis in Step 3 |
| `AskQuestion` tool | Clarify ambiguities in Steps 1 and 4 |
|
