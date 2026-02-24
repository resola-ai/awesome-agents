# Fowler Knowledge Priming Structure — Detailed Reference

This document provides detailed guidance for each of the 7 sections in a Fowler-style AGENTS.md.

Source: [Martin Fowler — Reduce Friction with AI: Knowledge Priming](https://martinfowler.com/articles/reduce-friction-ai/knowledge-priming.html)

---

## Section 1: Architecture Overview

**Purpose**: Give an AI agent (or new developer) a mental model of the system in 30 seconds.

**What to include**:
- What the system does (one sentence)
- The major components or layers (e.g., API server, worker queue, database, frontend)
- How those components interact (primary data flow)
- The deployment model if relevant (monolith, microservices, serverless, edge)

**What to avoid**:
- Marketing language ("cutting-edge", "scalable", "robust")
- Implementation details that belong in section 4 (project structure)
- History / migration context unless it affects current architecture

**Good example**:
```markdown
## Architecture Overview

This service is a REST API that processes webhook events from GitHub and stores
normalized build metadata in PostgreSQL. A background worker (BullMQ) handles
async tasks like cache invalidation and Slack notifications. The frontend is a
Next.js app served from Vercel that reads exclusively from the API — it has no
direct database access.
```

**Bad example** (too vague):
```markdown
## Architecture Overview

A modern, scalable web application built with best practices.
```

---

## Section 2: Tech Stack and Versions

**Purpose**: Let an AI agent know exactly which version of every library is in use, so it does not suggest APIs that don't exist in that version.

**What to include**:
- Runtime / language + version (e.g., `Node.js 20.11`, `Python 3.12`, `Go 1.22`)
- Framework + version (e.g., `Next.js 14.2`, `FastAPI 0.111`, `Gin 1.10`)
- Key libraries + versions (ORM, auth, validation, testing)
- Database and version (e.g., `PostgreSQL 16`, `Redis 7.2`)
- Infrastructure tools (e.g., `Docker 26`, `Terraform 1.8`)

**Format**: Table is clearest for quick scanning.

**Example**:
```markdown
## Tech Stack and Versions

| Layer | Technology | Version |
|-------|-----------|---------|
| Runtime | Node.js | 20.11 LTS |
| Framework | Next.js | 14.2 |
| Language | TypeScript | 5.4 |
| Database | PostgreSQL | 16.2 |
| ORM | Drizzle | 0.30 |
| Auth | NextAuth.js | 5.0 beta |
| Testing | Vitest | 1.6 |
| Deployment | Vercel | — |
```

**Rules**:
- Version numbers must be read from package.json / go.mod / pyproject.toml — never guessed
- If a version cannot be determined, write `unknown` not a plausible guess
- Do not include internal/private packages unless they have public docs

---

## Section 3: Curated Knowledge Sources

**Purpose**: Point AI agents to the right documentation so they use version-accurate APIs rather than hallucinating.

**What to include** (aim for 5–10 items):
- Official docs for the primary framework at the correct version
- Official docs for key libraries (ORM, auth, etc.)
- Internal docs: ADRs, runbooks, design docs, architecture decisions
- Influential external references specific to the project's patterns (e.g., a specific RFC, a well-known library guide)

**What to avoid**:
- Generic links (MDN, Wikipedia, Stack Overflow home page)
- Links to docs for versions you are NOT using
- Links that don't exist (never invent URLs)

**Example**:
```markdown
## Curated Knowledge Sources

- [Next.js 14 App Router docs](https://nextjs.org/docs) — primary framework reference
- [Drizzle ORM docs](https://orm.drizzle.team/docs/overview) — all database queries use Drizzle, not raw SQL
- [NextAuth.js v5 migration guide](https://authjs.dev/getting-started/migrating-to-v5) — auth is on v5 beta, API differs significantly from v4
- [Vercel deployment docs](https://vercel.com/docs) — deployment config and environment variable management
- `docs/adrs/` — architectural decision records for major choices made in this project
- `docs/runbooks/` — operational runbooks for common failure scenarios
```

---

## Section 4: Project Structure

**Purpose**: Let an AI agent orient quickly and know where to look for specific code.

**What to include**:
- Directory tree 2 levels deep (no deeper — it becomes noise)
- One-line annotation for each significant directory
- Entry point(s) clearly marked
- Generated / build output directories noted (so agents don't edit them)

**Example**:
```markdown
## Project Structure

```
project-root/
├── app/                    # Next.js App Router pages and layouts
│   ├── (auth)/             # Auth-gated routes (login, dashboard)
│   ├── api/                # API route handlers
│   └── layout.tsx          # Root layout
├── src/
│   ├── db/                 # Drizzle schema definitions and migrations
│   ├── lib/                # Shared utilities and server-side helpers
│   └── components/         # Reusable React components
├── tests/                  # Vitest test files (mirror src/ structure)
├── public/                 # Static assets served at /
├── docs/
│   ├── adrs/               # Architectural Decision Records
│   └── runbooks/           # Operational runbooks
├── .env.example            # Environment variable template
└── package.json            # Dependencies and scripts
```
```

**Rules**:
- Do not list every file — list directories and notable files only
- Mark generated directories explicitly: `dist/  # ← build output, do not edit`
- If the project has a monorepo structure, show the top-level packages and their roles

---

## Section 5: Naming Conventions

**Purpose**: Ensure AI-generated code matches the project's style, reducing diff noise and review friction.

**What to include**:
- File naming (kebab-case, PascalCase, snake_case?)
- Component/class naming
- Function naming (verb-first? camelCase? snake_case?)
- Boolean variable naming (is/has/should prefix?)
- Constants (SCREAMING_SNAKE_CASE? camelCase?)
- Test file naming (*.test.ts? *.spec.ts? placed next to source or in tests/?)
- Any domain-specific conventions (e.g., "all API handlers are named handle<Verb><Resource>")

**Example**:
```markdown
## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Files (components) | PascalCase | `UserCard.tsx` |
| Files (utilities) | kebab-case | `format-date.ts` |
| React components | PascalCase | `UserCard`, `SubmitButton` |
| Functions | camelCase, verb-first | `fetchUser()`, `formatDate()` |
| Boolean variables | `is`/`has`/`should` prefix | `isLoading`, `hasPermission` |
| Constants | SCREAMING_SNAKE_CASE | `MAX_RETRY_COUNT` |
| Drizzle tables | snake_case | `user_sessions`, `api_keys` |
| Test files | Same name + `.test.ts` | `format-date.test.ts` |
| Environment vars | SCREAMING_SNAKE_CASE | `DATABASE_URL`, `NEXT_PUBLIC_API_URL` |
```

---

## Section 6: Code Examples

**Purpose**: Show, not tell. AI agents learn preferred patterns faster from working code than from prose descriptions.

**What to include**:
- 2–3 examples, each 10–20 lines
- Examples that demonstrate the project's most common patterns (e.g., a typical route handler, a typical component, a typical DB query)
- Real code from actual project files — cite the source

**What to avoid**:
- Invented code
- Trivially obvious examples (a Hello World)
- Examples longer than ~30 lines (break into multiple focused examples)

**Example entry**:
````markdown
## Code Examples

### API Route Handler Pattern

All API handlers follow this structure — input validation with Zod, DB via Drizzle,
consistent error response shape.

```typescript
// from app/api/users/[id]/route.ts
import { db } from '@/src/db'
import { users } from '@/src/db/schema'
import { eq } from 'drizzle-orm'
import { z } from 'zod'

const paramsSchema = z.object({ id: z.string().uuid() })

export async function GET(req: Request, { params }: { params: { id: string } }) {
  const parsed = paramsSchema.safeParse(params)
  if (!parsed.success) return Response.json({ error: 'Invalid ID' }, { status: 400 })

  const user = await db.select().from(users).where(eq(users.id, parsed.data.id)).get()
  if (!user) return Response.json({ error: 'Not found' }, { status: 404 })

  return Response.json(user)
}
```
````

---

## Section 7: Anti-patterns to Avoid

**Purpose**: Prevent AI agents from repeating known mistakes, using deprecated patterns, or working around constraints incorrectly.

**What to include**:
- Patterns that were tried and abandoned (source: TODO/FIXME comments, git history, README warnings)
- Deprecated APIs or libraries that are still present but should not be extended
- Common mistakes specific to the project's stack or domain
- Patterns that violate architectural constraints (e.g., "components must not import from db/")

**Example**:
```markdown
## Anti-patterns to Avoid

- **Do not use `fetch()` directly in components** — use the `useQuery` hooks in `src/lib/api/` which handle auth headers, error boundaries, and caching.
- **Do not write raw SQL** — all DB access goes through Drizzle ORM. Raw queries bypass type safety and migration tracking.
- **Do not import from `app/` into `src/`** — `app/` is Next.js routing only; shared logic belongs in `src/lib/`.
- **Do not add secrets to `.env`** — use `.env.local` (gitignored). `.env` is for non-secret defaults only.
- **Do not use `any` in TypeScript** — if a type is unknown, use `unknown` and narrow it. `any` bypasses all type checking.
- **Do not call the database from client components** — all DB access must go through API routes or Server Actions.
```

**Sources to mine for anti-patterns**:
- Search for `TODO`, `FIXME`, `HACK`, `XXX`, `DO NOT` in source files
- Read README "known issues" or "limitations" sections
- Check git log messages for "revert", "fix: do not use X" patterns

---

## Complete AGENTS.md Template

Use this template as the skeleton when writing a new AGENTS.md from scratch. Replace all `<!-- ... -->` placeholders with verified content.

```markdown
# AGENTS.md

<!-- Knowledge priming document for AI agents and new contributors. -->
<!-- Keep this file to 1–3 pages. Move details to linked docs. -->
<!-- Last updated: YYYY-MM-DD -->

## Architecture Overview

<!-- 3–5 sentences: what the system does, major components, primary data flow, deployment model -->

## Tech Stack and Versions

| Layer | Technology | Version |
|-------|-----------|---------|
| <!-- Runtime --> | | |
| <!-- Framework --> | | |
| <!-- Language --> | | |
| <!-- Database --> | | |
| <!-- Testing --> | | |

## Curated Knowledge Sources

<!-- 5–10 links. Official docs for the specific versions above. Internal docs. -->

- <!-- [Framework docs](url) — what it covers -->
- <!-- [ORM docs](url) — what it covers -->
- `docs/adrs/` — Architectural Decision Records <!-- if they exist -->

## Project Structure

```
<!-- paste annotated 2-level tree here -->
```

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| <!-- Files --> | | |
| <!-- Functions --> | | |
| <!-- Booleans --> | | |
| <!-- Constants --> | | |
| <!-- Tests --> | | |

## Code Examples

<!-- 2–3 real code blocks from actual project files. Cite source file. -->

### <!-- Pattern Name -->

<!-- Brief explanation of what this example demonstrates -->

```<!-- language -->
// from <!-- path/to/source/file -->
<!-- paste real code here -->
```

## Anti-patterns to Avoid

<!-- Bullet list sourced from TODO comments, README warnings, or architectural constraints -->

- <!-- Do not ... because ... -->
- <!-- Do not ... because ... -->
- <!-- Do not ... because ... -->
```
