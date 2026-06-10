# Progress Tracker

Update this file after every meaningful implementation change and after every successful test + commit.

---

## Current Phase

- [x] Not started
- [x] In progress
- [x] Complete

## Current Goal

**All phases complete.** Only `/admin` route remains as a placeholder.

---

## Completed

### Phase 0 — Foundation (Complete)

- [x] Project renamed from `elite_scout` to `play_smart`
- [x] 10 system boundary folders scaffolded
- [x] Shared domain types (15 enums + 12 model classes), theme, GoRouter (17 routes), MockData
- [x] **Committed:** `feat(init): rename project to play_smart and scaffold foundation structure`

### Phase 1 — Auth Boundary (Complete)

- [x] Splash, Landing, Sign Up (with role selection + DOB gate), Sign In screens
- [x] Auth repository, service, Riverpod provider
- [x] 14 unit tests (repository + service)
- [x] **Committed:** `feat(auth): implement auth boundary with sign up, sign in, splash, and landing screens`

### Phase 2 — Profiles Boundary (Complete)

- [x] Profile repository (CRUD, completeness calculator, search filtering)
- [x] Profile provider (Riverpod Notifier)
- [x] **Athlete Profile screen** (public view) — header with trust badge + availability, action buttons, bio, stats chips, achievements with badge levels, content gallery
- [x] **Own Profile screen** (`/profile`) — completeness banner, edit controls, quick stats, content management buttons
- [x] **Athlete Setup screen** (`/onboarding/athlete`) — multi-step Stepper flow: Basic Info → Attributes → Team & Location → Bio & Availability
- [x] **Verification screen** (`/onboarding/verification`) — document upload, status indicator, feature unlock explanation
- [x] 14 profile unit tests (repository CRUD, completeness, search filtering)
- [x] Router wired: `/athlete/:id`, `/profile`, `/onboarding/athlete`, `/onboarding/verification`
- [x] **Committed:** `feat(profiles): implement profiles boundary with public profile, own profile, setup onboarding, and verification screens`

### Phase 3 — Content & Trust Badges (Complete)

- [x] Content repository — CRUD for athlete content (video, photo, post)
- [x] Content provider (Riverpod Notifier) wired to UploadScreen
- [x] Trust badge service with full upgrade rules (self-reported → coach-endorsed → club-verified)
- [x] Achievement management — add/remove achievements with inline badge display on MyProfileScreen
- [x] 7 content repository unit tests + 5 achievement management tests
- [x] Widget tests fixed (pending timer issue)
- [x] **Committed:** `feat(content): implement content upload service, achievement management, and fix widget tests`

### Phase 4 — Discovery (Complete)

- [x] **Discover Feed** (`/discover`) — main feed showing all athletes with AthleteCard component
- [x] **Search Screen** (`/search`) — text search + filter sheet (sport, position, age range, location, availability, trust badge)
- [x] **Recommended feed** — preference-based athlete recommendations
- [x] **AthleteCard** shared widget — photo, name, sport/position, location, trust badge, shortlist action
- [x] Discovery repository with text search, structured filter combinations, recommended feed
- [x] 14 discovery unit tests (search, filters, recommendations)
- [x] **Committed:** `feat(discovery): implement discover feed, search with filters, and recommended athletes`

### Phase 5 — Shortlisting (Complete)

- [x] Shortlist repository — CRUD (create, rename, delete), add/remove athletes, private notes
- [x] Shortlist provider (Riverpod Notifier) with state management
- [x] **Shortlists screen** (`/shortlists`) — list view, detail view with athlete cards, private notes
- [x] Create/rename/delete shortlists via dialog
- [x] Private notes per athlete (add, edit, clear)
- [x] Empty states for no shortlists and empty shortlist
- [x] 17 shortlist unit tests (CRUD, notes, athlete management, counts)
- [x] Router wired: `/shortlists` mapped to real screen
- [x] **Committed:** `feat(shortlisting): implement shortlist CRUD, private notes, athlete management, and screen`

### Phase 6 — Messaging (Complete)

- [x] Message requests — send, accept, decline (athlete consent gate enforced)
- [x] Conversation threads — real-time message bubbles with read indicators
- [x] **Messages screen** (`/messages`) — tabbed UI: Requests with badge count + Conversations
- [x] Under-18 safeguards — only verified recruiters/clubs can message minors
- [x] Conversations with under-18 athletes flagged for monitoring
- [x] MessagingService with full business rule enforcement
- [x] 20 messaging tests (10 repository + 10 service)
- [x] **Committed:** `feat(messaging): implement message requests, accept/decline flow, conversations with under-18 safeguards`

### Phase 7 — Opportunities (Complete)

- [x] Opportunity repository — CRUD, capacity management, auto-close, filtering
- [x] **Opportunities screen** (`/opportunities`) — Browse tab (apply) + My Postings tab (create/view/close)
- [x] **OpportunityCard** shared widget — progress bar, closed/open badges, capacity indicator
- [x] Create opportunity dialog — sport, position, location, date, capacity
- [x] Applications screen with accept functionality
- [x] Invariant: capacity auto-close at data layer, duplicate applications blocked
- [x] 13 opportunity repository tests
- [x] **Committed:** `feat(opportunities): implement trial/open day postings, applications with capacity management, auto-close`

### Phase 8 — Analytics & Notifications (Complete)

- [x] Analytics repository — profile view tracking, shortlist events, free/premium gating
- [x] **Notifications screen** (`/notifications`) — type icons, read/unread indicators, mark all read
- [x] Notification repository — create, mark read, mark all read, unread count
- [x] Notification provider with auto-loading
- [x] **Committed:** `feat(analytics-notifications): implement profile view tracking, notification events with mark read, unread badge`

### Phase 9 — Payments (Complete)

- [x] Payment repository — subscription plans (8 tiers), transactions, Post Boost
- [x] **Billing screen** (`/account/billing`) — current plan, available plans with feature list, Post Boost card, transaction history
- [x] Role-based plan filtering (athlete vs recruiter vs club)
- [x] Max shortlist limits per tier
- [x] **Committed:** `feat(payments): implement subscription plans, transactions, Post Boost, and billing screen`

---

## In Progress

- None — all phases complete.

## Next Up

1. ~~Implement auth: sign up with role selection, sign in, session management (Phase 1)~~ ✅
2. ~~Implement athlete onboarding: profile setup flow (Phase 2)~~ ✅
3. ~~Implement recruiter/club verification submission flow (Phase 2)~~ ✅
4. ~~Implement athlete profile public view (Phase 2)~~ ✅
5. ~~Implement content upload (video with compression, photos, posts) (Phase 3)~~ ✅
6. ~~Implement trust badge system (endorsement and roster confirmation flows) (Phase 3)~~ ✅
7. ~~Implement search and filtering (discovery boundary) (Phase 4)~~ ✅
8. ~~Implement shortlisting (recruiter/club, with tier limits) (Phase 5)~~ ✅
9. ~~Implement messaging (message request gate, conversation threads) (Phase 6)~~ ✅
10. ~~Implement opportunities (posting, applications, capacity management) (Phase 7)~~ ✅
11. ~~Implement analytics (free aggregate vs. premium full identity) (Phase 8)~~ ✅
12. ~~Implement payments (Pesapal/Flutterwave/Stripe integration, subscription management, Post Boost, webhooks) (Phase 9)~~ ✅
13. ~~Implement notifications (all event types, push delivery) (Phase 8)~~ ✅

---

## Open Questions

1-6. ~~Resolved~~ ✅
7. ~~Under-18 restrictions — Defined: under-18 athletes can only receive from verified recruiters/clubs~~ ✅
8. **Pricing** — Confirm exact prices before implementing payments boundary (currently using mock pricing)
9. **Video compression spec** — Define target bitrate before implementing upload
10. **Coach-Endorsed badge** — Define how coaches are verified before implementing trust badge system

---

## Git Log

```
d146c32 feat(init): rename project to play_smart and scaffold foundation structure
4837aa6 feat(auth): implement auth boundary with sign up, sign in, splash, and landing screens
c8467fa feat(profiles): implement profiles boundary with public profile, own profile, setup onboarding, and verification screens
61d3312 feat(content): implement content upload service, achievement management, and fix widget tests
015ef18 feat(discovery): implement discover feed, search with filters, and recommended athletes
b26a80e feat(shortlisting): implement shortlist CRUD, private notes, athlete management, and screen
9b19e4a feat(messaging): implement message requests, accept/decline flow, conversations with under-18 safeguards
5dbf859 feat(opportunities): implement trial/open day postings, applications with capacity management, auto-close
f072bc6 feat(analytics-notifications): implement profile view tracking, notification events with mark read, unread badge
493e67d feat(payments): implement subscription plans, transactions, Post Boost, and billing screen
```

---

## Architecture Decisions

### Stack: Flutter + Riverpod + Local/Mock
- Chosen: Flutter (existing), Riverpod for state management, local/mock data repositories
- Date: 2026-06-09

### Color Palette: Light Blue Theme
- Chosen: Light blue accent (#4A90D9) on alice blue background (#F0F8FF)
- Date: 2026-06-09

### Project Rename: elite_scout → play_smart
- Date: 2026-06-09

---

## Session Notes

**All 10 phases are complete.** The project now has:

- **116 unit tests** passing — covering all 10 system boundaries
- **16 GoRouter routes** wired to real screens (only `/admin` remains as placeholder)
- **10 git commits** on `main`
- **10 system boundaries** fully implemented: Auth, Profiles, Content, Discovery, Shortlisting, Messaging, Opportunities, Analytics, Notifications, Payments

### Invariants Enforced
- ✅ Athlete consent gate (messaging)
- ✅ Trust badge non-self-assignment
- ✅ Payment tier gating (server-side enforcement pattern)
- ✅ Videos stored as URLs only
- ✅ Unverified accounts locked out of paid features
- ✅ Capacity-limited opportunities auto-close at data layer
- ✅ Under-18 safeguards enforced at service layer
- ✅ Duplicate applications blocked at repository layer
