# Code Standards

## General

- Keep modules small and single-purpose — one file should not own multiple system boundaries
- Fix root causes; do not layer workarounds over broken behavior
- Do not mix unrelated concerns in one component or route handler
- Business logic belongs in service or domain layers, not in UI components or route handlers
- All feature access gates (subscription tier, verification status, account type) must be enforced server-side, not only in the UI

## TypeScript

- Strict mode is required throughout the project
- Avoid `any` — use explicit interfaces, union types, or `unknown` with narrowing at boundaries
- Validate and type all external input at system boundaries before trusting it (API payloads, payment webhooks, file uploads)
- Define shared domain types (e.g. `Athlete`, `Opportunity`, `TrustBadge`, `SubscriptionTier`) in a central types file rather than inline in components

## [Framework — fill in your choice]

- Default to server-side rendering / server components where applicable
- Add client-only code only where browser interactivity requires it
- Keep route handlers focused on a single responsibility: receive request → validate → call service → return response
- No business logic in route handlers — delegate to service functions

## Styling

- Use CSS custom property tokens from `ui-context.md` — no hardcoded hex values anywhere in the codebase
- Follow the border radius scale defined in `ui-context.md`
- Trust badge colors must use the badge-specific tokens (`--badge-self`, `--badge-coach`, `--badge-club`), never hardcoded

## API Routes and Server Actions

- Validate and parse all request input before any logic runs
- Enforce auth and account type (athlete / recruiter / club) before any read or mutation
- Enforce subscription tier checks server-side before any gated action (shortlisting, messaging, trial posting, analytics)
- Return consistent, predictable response shapes — include a `success` boolean and typed `data` or `error` field
- Recruiter and club routes must reject requests from unverified accounts

## Payments and Webhooks

- Payment state changes must only be applied via webhook from the payment provider (Pesapal, Flutterwave, Stripe) — never from client-side callbacks alone
- Validate webhook signatures before processing any event
- Subscription tier upgrades, downgrades, and grace period transitions are handled in the `payments/` boundary only

## File Uploads and Media

- Videos must be compressed on upload before being stored — do not store originals uncompressed
- Never store video or image binary data in the database — store the file storage URL reference only
- Validate file type and size at the upload boundary before accepting

## Trust Badges

- Badge state is stored in the database and updated only through the correct trigger:
  - `self-reported` — set by default; no action required
  - `coach-endorsed` — set only when a verified coach account submits an endorsement
  - `club-verified` — set only when a verified club confirms a roster entry
- No badge can be upgraded by the athlete themselves

## Messaging

- Message requests must be persisted in the database before any notification is sent
- A conversation thread must not be created or opened until the athlete has explicitly accepted the message request
- Enforce this at the service layer, not just in the UI

## Notifications

- All notification events are fired by the relevant system boundary (e.g. `shortlisting/` fires a shortlist notification, `messaging/` fires a message request notification)
- Notification delivery is handled exclusively by the `notifications/` boundary
- Do not fire notifications directly from UI components

## File Organisation

- `auth/` — registration, login, session, verification flows
- `profiles/` — athlete profile data, content, achievements, trust badges
- `discovery/` — search, filtering, map view, recommended feed
- `shortlisting/` — shortlists, private notes, outreach tracking
- `opportunities/` — trial and open day postings, applications, capacity management
- `messaging/` — message requests, conversation threads
- `notifications/` — notification events, delivery
- `payments/` — subscription management, boosts, payment provider integrations, invoicing
- `analytics/` — profile view tracking, post performance, shortlist events
- `admin/` — verification approval, moderation
- `components/ui/` — shared UI components (do not modify generated library components)
- `types/` — shared domain types used across boundaries
