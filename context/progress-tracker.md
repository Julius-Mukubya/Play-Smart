# Progress Tracker

Update this file after every meaningful implementation change and after every successful test + commit.

---

## Current Phase

- [x] Not started
- [x] In progress
- [ ] Complete

## Current Goal

**Phase 2: Profiles** — Athlete profile setup onboarding, public profile view, own profile with edit controls, and recruiter/club verification submission screen.

---

## Completed

### Phase 0 — Foundation (Complete)

- [x] Project renamed from `elite_scout` to `play_smart`
- [x] Dependencies: flutter_riverpod, go_router, google_fonts, cached_network_image, image_picker, video_player, path_provider, mocktail
- [x] Color palette defined (light blue theme) with AppColors constants
- [x] AppTheme configured with Material 3, Inter font, light blue accent
- [x] 10 system boundary folders scaffolded: auth/, profiles/, discovery/, shortlisting/, opportunities/, messaging/, notifications/, payments/, analytics/, admin/
- [x] Shared domain types: 15 enums + 12 model classes in `lib/shared/types/domain_types.dart`
- [x] GoRouter configured with all 17 routes
- [x] MockData repository with seed data for all boundaries
- [x] 2 widget tests passing (render + navigation)
- [x] Updated context files: architecture.md (stack choices), ui-context.md (color tokens)
- [x] **Committed:** `feat(init): rename project to play_smart and scaffold foundation structure`

### Phase 1 — Auth Boundary (Complete)

- [x] Auth models: AuthState sealed class, SignUpData, SignInData
- [x] Auth repository: sign up, sign in, sign out, session, age gate, duplicate email detection, password validation
- [x] Auth service: verification gating, shortlist permission, message permission, post-sign-in routing, under-18 checks
- [x] Auth provider: Riverpod Notifier with all auth operations
- [x] Splash screen: session check with auto-redirect to landing or discover
- [x] Landing screen: public entry with hero, CTAs, trust badge explanation
- [x] Sign Up screen: role selection (Athlete, Recruiter, Club), DOB picker, validation, error display
- [x] Sign In screen: email/password login with forgot password link
- [x] 14 unit tests passing (auth repository + auth service)
- [x] **Committed:** `feat(auth): implement auth boundary with sign up, sign in, splash, and landing screens`

### Phase 2 — Profiles (In Progress)

- [x] Profile repository: CRUD, completeness calculator, search filtering
- [x] Profile provider: Riverpod Notifier for loading/updating profiles
- [x] Athlete profile screen (public view): header, action buttons, bio, stats chips, achievements with badges, content gallery
- [ ] Wire profile screen into GoRouter
- [ ] Own profile screen (edit controls + analytics section)
- [ ] Profile setup onboarding flow (multi-step)
- [ ] Recruiter/Club verification submission screen
- [ ] Profile tests
- [ ] BUILD → TEST → COMMIT

---

## In Progress

- **Phase 2: Profiles** — Profile repository, provider, and public view screen built. Need to wire into router, build own profile + onboarding + verification screens, write tests, and commit.

## Next Up

1. ~~Implement auth: sign up with role selection, sign in, session management (Phase 1)~~ ✅
2. **Implement athlete onboarding: profile setup flow (Phase 2)** ← YOU ARE HERE
3. Implement recruiter/club verification submission flow (Phase 2)
4. Implement athlete profile public view (Phase 2)
5. Implement content upload (video with compression, photos, posts) (Phase 3)
6. Implement search and filtering (discovery boundary) (Phase 4)
7. Implement shortlisting (recruiter/club, with tier limits) (Phase 5)
8. Implement trust badge system (endorsement and roster confirmation flows) (Phase 3)
9. Implement messaging (message request gate, conversation threads) (Phase 6)
10. Implement opportunities (posting, applications, capacity management) (Phase 7)
11. Implement analytics (free aggregate vs. premium full identity) (Phase 8)
12. Implement payments (Pesapal/Flutterwave/Stripe integration, subscription management, Post Boost, webhooks) (Phase 9)
13. Implement notifications (all event types, push delivery) (Phase 8)

---

## Open Questions

1. ~~**Framework choice** — Web (Next.js) + mobile (React Native / Expo)? Or Flutter?~~ **Resolved: Flutter**
2. ~~**Database** — PostgreSQL (Prisma) or another option?~~ **Resolved: Local/mock for now**
3. ~~**File storage** — Cloudinary or S3?~~ **Resolved: Local/mock for now**
4. ~~**Auth provider** — Clerk, Firebase Auth, or custom JWT?~~ **Resolved: Local/mock for now**
5. ~~**Search** — PostgreSQL full-text or Algolia?~~ **Resolved: In-memory filtering**
6. ~~**Color palette** — Exact hex values~~ **Resolved: Light blue theme**
7. **Under-18 restrictions** — Define exact rules before implementing auth boundary detailed restrictions
8. **Pricing** — Confirm exact prices before implementing payments boundary
9. **Video compression spec** — Define target bitrate before implementing upload
10. **Coach-Endorsed badge** — Define how coaches are verified before implementing trust badge system

---

## Architecture Decisions

### Stack: Flutter + Riverpod + Local/Mock
- Chosen: Flutter (existing), Riverpod for state management, local/mock data repositories
- Reason: The project already existed as a Flutter project. Riverpod provides clean state management with testability.
- Date: 2026-06-09

### Color Palette: Light Blue Theme
- Chosen: Light blue accent (#4A90D9) on alice blue background (#F0F8FF)
- Reason: User requested light blue theme.
- Date: 2026-06-09

### Project Rename: elite_scout → play_smart
- Chosen: Renamed to align with the product name defined in project-overview.md
- Reason: The product is called "Play Smart" in all context files.
- Date: 2026-06-09

---

## Git Log

```
d146c32 feat(init): rename project to play_smart and scaffold foundation structure
4837aa6 feat(auth): implement auth boundary with sign up, sign in, splash, and landing screens
```

---

## Session Notes

Phase 0 and Phase 1 are complete and committed. Phase 2 (Profiles) has its repository, provider, and public profile screen built. The remaining work in Phase 2 is: wire the profile screen into the router, build the own profile screen with edit controls, build the profile setup onboarding flow, build the verification submission screen, write tests, and commit.