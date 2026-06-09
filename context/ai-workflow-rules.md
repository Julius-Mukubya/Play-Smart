# AI Workflow Rules

## Approach

Build PlaySmart incrementally using a spec-driven workflow. The context files define what to build, how to build it, and the current state of progress. Always implement against these specs — do not infer or invent behavior from scratch. The requirements document (`PlaySmart_Requirements.docx`) is the authoritative product source; the context files are derived from it and are what you implement against.

## Scoping Rules

- Work on one feature unit at a time
- Prefer small, verifiable increments over large speculative changes
- Do not combine unrelated system boundaries in a single implementation step
- A system boundary (e.g. `auth/`, `profiles/`, `messaging/`) is a natural unit ceiling — do not cross multiple boundaries in one step unless they are trivially coupled

## When to Split Work

Split an implementation step if it combines:

- UI changes and server/API changes in different system boundaries
- Multiple unrelated account type flows (e.g. athlete profile setup and recruiter verification in one step)
- Payment logic and feature gating logic
- Behavior not clearly defined in the context files

If a change cannot be verified end to end quickly, the scope is too broad — split it.

## Handling Missing Requirements

- Do not invent product behavior not defined in the context files
- If a requirement is ambiguous (e.g. exact shortlist limit enforcement behavior, under-18 restriction detail), resolve it in the relevant context file before implementing
- If a requirement is missing, add it as an open question in `progress-tracker.md` before continuing
- The three open areas most likely to need resolution before implementation: exact color palette and visual design tokens, framework and infrastructure choices (see `architecture.md` stack table), and under-18 restriction specifics

## Protected Files

Do not modify the following unless explicitly instructed:

- `components/ui/*` — generated UI library components (shadcn/ui or equivalent)
- Any third-party library internals
- Payment provider SDK files

## Keeping Docs in Sync

Update the relevant context file whenever implementation changes affect:

- System architecture or boundaries → `architecture.md`
- Storage model decisions → `architecture.md`
- Code conventions or standards → `code-standards.md`
- Feature scope → `project-overview.md`
- UI, screens, or components → `ui-context.md`
- Test scope or strategy → `test-context.md`
- Progress, git log, or open questions → `progress-tracker.md`

## Before Moving to the Next Unit

1. The current unit works end to end within its defined scope
2. No invariant defined in `architecture.md` was violated
3. `progress-tracker.md` reflects the completed work
4. `npm run build` (or platform equivalent) passes
5. The messaging consent gate, trust badge rules, and payment tier gates have not been weakened or bypassed
