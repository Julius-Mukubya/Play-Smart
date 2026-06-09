# Progress Tracker

Update this file after every meaningful implementation change and after every successful test + commit.

---

## Current Phase

- [x] Not started
- [x] In progress
- [ ] Complete

## Current Goal

**Phase 0: Foundation** — Rename project, scaffold folder structure, define shared domain types, set up theme, router, mock data, and test infrastructure.

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
- [x] Committed to git

### Phase 1 — Auth Boundary
- [ ] Not started

## In Progress

- None yet — Phase 0 complete, awaiting Phase 1.

## Next Up

1. Implement auth: sign up with role selection, sign in, session management (Phase 1)
2. Implement athlete onboarding: profile setup flow (Phase 2)
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

1. ~~**Framework choice** — Web (Next.js) + mobile (React Native / Expo)? Or Flutter? Or mobile-only MVP first?~~ **Resolved: Flutter (existing project)**
2. ~~**Database** — PostgreSQL (Prisma) or another option?~~ **Resolved: Local/mock for now, ready for Firebase/Supabase**
3. ~~**File storage** — Cloudinary or S3?~~ **Resolved: Local/mock for now, ready for Cloudinary/S3**
4. ~~**Auth provider** — Clerk, Firebase Auth, or custom JWT?~~ **Resolved: Local/mock for now, ready for Firebase**
5. ~~**Search** — PostgreSQL full-text or Algolia?~~ **Resolved: In-memory filtering for now, ready for Algolia**
6. ~~**Color palette** — Exact hex values for all CSS tokens in `ui-context.md` are undecided.~~ **Resolved: Light blue theme — see ui-context.md**
7. **Under-18 restrictions** — The requirements say "additional safeguards for users under 18" but do not specify exactly what is restricted. Define the exact rules (e.g. no direct messaging from adult recruiters, restricted content types, parental consent) before implementing the auth boundary.
8. **Pricing** — The requirements give ranges (e.g. Premium Monthly UGX 15,000–25,000). Confirm exact prices before implementing the payments boundary.
9. **Video compression spec** — What target bitrate or resolution should compressed videos be encoded to? Define before implementing upload.
10. **Coach-Endorsed badge** — What is the verification requirement for a "verified coach" who can endorse achievements? The requirements mention the badge but do not define how coaches are verified. Resolve before implementing the trust badge system.

---

## Architecture Decisions

### Stack: Flutter + Riverpod + Local/Mock
- Chosen: Flutter (existing), Riverpod for state management, local/mock data repositories
- Reason: The project already existed as a Flutter project. Riverpod provides clean state management with testability. Local/mock allows us to build the full architecture without a backend dependency.
- Date: 2026-06-09

### Color Palette: Light Blue Theme
- Chosen: Light blue accent (#4A90D9) on alice blue background (#F0F8FF)
- Reason: User requested light blue theme; fits the "energetic, professional sports platform" brief.
- Date: 2026-06-09

### Project Rename: elite_scout → play_smart
- Chosen: Renamed to align with the product name defined in project-overview.md
- Reason: The product is called "Play Smart" in all context files; the old name "Elite Scout" was inconsistent.
- Date: 2026-06-09

---

## Git Log

```
### feat(init): rename project to play_smart and scaffold foundation structure
- Branch: main
- Files changed: pubspec.yaml, lib/main.dart, lib/core/router/app_router.dart, lib/core/theme/app_theme.dart, lib/shared/types/domain_types.dart, lib/shared/utils/mock_data.dart, test/widget_test.dart, context/architecture.md, context/ui-context.md, context/progress-tracker.md
- Tests passed: Play Smart app renders placeholder screen, Play Smart app navigates to discover route
- Committed: 2026-06-09
- Notes: Phase 0 complete. Project renamed from elite_scout to play_smart. Dependencies added (flutter_riverpod, mocktail, etc.). 10 system boundary folders scaffolded. Shared domain types defined (15 enums + 12 model classes). GoRouter configured with 17 routes. MockData repository with seed data. Light blue theme implemented. Tests passing.
```

---

## Session Notes

Phase 0 (Foundation) is complete. The project has been renamed, restructured into 10 system boundaries, and populated with shared domain types, a mock data repository, theme, and router. Next step is Phase 1: Auth boundary implementation.