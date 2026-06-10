# Progress Tracker

Update this file after every meaningful implementation change and after every successful test + commit.

---

## Current Phase

- [x] Not started
- [x] In progress
- [x] Complete

## Current Goal

**Phase 4: Discovery** — Search, filtering, map view, recommended feed.

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

---

## In Progress

- **Phase 4: Discovery** — Search, filtering, map view, recommended feed

## Next Up

1. ~~Implement auth: sign up with role selection, sign in, session management (Phase 1)~~ ✅
2. ~~Implement athlete onboarding: profile setup flow (Phase 2)~~ ✅
3. ~~Implement recruiter/club verification submission flow (Phase 2)~~ ✅
4. ~~Implement athlete profile public view (Phase 2)~~ ✅
5. ~~Implement content upload (video with compression, photos, posts) (Phase 3)~~ ✅
6. ~~Implement trust badge system (endorsement and roster confirmation flows) (Phase 3)~~ ✅
7. **Implement search and filtering (discovery boundary) (Phase 4)** ← YOU ARE HERE
8. Implement shortlisting (recruiter/club, with tier limits) (Phase 5)
9. Implement messaging (message request gate, conversation threads) (Phase 6)
10. Implement opportunities (posting, applications, capacity management) (Phase 7)
11. Implement analytics (free aggregate vs. premium full identity) (Phase 8)
12. Implement payments (Pesapal/Flutterwave/Stripe integration, subscription management, Post Boost, webhooks) (Phase 9)
13. Implement notifications (all event types, push delivery) (Phase 8)

---

## Open Questions

1-6. ~~Resolved~~ ✅
7. **Under-18 restrictions** — Define exact rules before implementing messaging boundary
8. **Pricing** — Confirm exact prices before implementing payments boundary
9. **Video compression spec** — Define target bitrate before implementing upload
10. **Coach-Endorsed badge** — Define how coaches are verified before implementing trust badge system

---

## Git Log

```
d146c32 feat(init): rename project to play_smart and scaffold foundation structure
4837aa6 feat(auth): implement auth boundary with sign up, sign in, splash, and landing screens
c8467fa feat(profiles): implement profiles boundary with public profile, own profile, setup onboarding, and verification screens
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

**Phase 3 (Content & Trust Badges) is complete.** The project now has:

- **52 unit tests** passing — 14 auth + 19 profiles (incl. 5 achievement CRUD) + 7 content repository + 10 trust badge + 2 widget
- **Content boundary** — ContentRepository, ContentNotifier provider, UploadScreen wired to persist content
- **Achievement management** — Add/remove achievements on MyProfileScreen with inline badge display
- **Trust badge service** — Full badge upgrade rules enforced (self-reported → coach-endorsed → club-verified)
- **Widget tests fixed** — Pending timer issue resolved by pumping duration in SplashScreen tests
- **4 git commits** on main
