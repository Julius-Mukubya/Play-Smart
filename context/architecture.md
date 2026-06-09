# Architecture Context

## Stack

| Layer        | Technology                        | Role                                               |
| ------------ | --------------------------------- | -------------------------------------------------- |
| Framework    | Flutter 3.x                       | Cross-platform mobile app (Android + iOS)          |
| Mobile       | Flutter (single codebase)         | Android and iOS mobile-first client                |
| UI           | Material Design 3 + custom theme  | Styling and component library                      |
| State Mgmt   | Riverpod 3.x                      | State management and dependency injection          |
| Auth         | Local/mock (ready for Firebase)   | Registration, login, session management            |
| Database     | Local/mock (ready for Supabase/Firebase) | User accounts, profiles, content metadata, relationships |
| File Storage | Local/mock (ready for Cloudinary/S3) | Videos, images, and generated PDF exports          |
| Payments     | Local/mock (ready for Pesapal/Flutterwave/Stripe) | Local mobile money + card payments, international cards |
| Notifications| Local/mock (ready for FCM)        | Push notifications for all notification events     |
| Search       | In-memory filtering (ready for Algolia/Postgres full-text) | Athlete search and filtering |

> **Stack decisions made:** Flutter + Riverpod + local/mock data for MVP. Backend services (Firebase, Supabase, etc.) to be integrated later.

## System Boundaries

- `auth/` — Registration, login, session, verification flow for all account types (athlete, recruiter, club). Verification approval for recruiter and club accounts lives here.
- `profiles/` — Athlete profile data, content (videos, photos, posts), achievements, trust badges, and availability status. The single source of truth for what an athlete presents to the world.
- `discovery/` — Search, filtering, map-based view, and recommended athlete feed. Read-only access to profile data. No mutations here.
- `shortlisting/` — Recruiter and club shortlists, private notes, outreach tracking. Scoped per recruiter/club account.
- `opportunities/` — Trial and open day postings, eligibility criteria, capacity limits, application management.
- `messaging/` — Message requests, accept/decline flow, conversation threads. Athlete consent gate enforced here.
- `notifications/` — All platform notification events. Triggered by other system boundaries; not responsible for business logic.
- `payments/` — Subscription management, one-off purchases (Post Boost), payment provider integrations (Pesapal, Flutterwave, Stripe), invoicing, grace period logic.
- `analytics/` — Profile view tracking, shortlist events, post performance. Free tier gets aggregated counts; premium tier gets full identity and history.
- `admin/` — Recruiter and club verification approval, moderation tools, content review.

## Storage Model

- **Database**: User accounts, profile metadata, sport/position/attributes, achievements, trust badge state, content metadata (title, tags, moment type, upload references), shortlists, private notes, opportunity postings, message request state, conversation metadata, subscription state, notification history, roster confirmations.
- **File Storage**: Video files (compressed on upload), images, generated PDF profile exports. Referenced by URL in the database — never stored as blobs in the database.
- **Search Index**: Athlete profiles indexed by sport, position, age, location, availability, and trust badge level. Kept in sync with profile writes.

## Auth and Access Model

- Every user registers as one account type: Athlete, Recruiter/Scout, or Club/Organisation.
- Recruiters and Clubs must complete a verification flow (credential submission for recruiters; official registration documents for clubs) before accessing paid features or posting opportunities.
- Guests are unauthenticated. They can browse public profiles and content. Any interaction (contact, shortlist, post) prompts registration.
- Athletes control messaging: no recruiter or club can open a conversation until the athlete accepts a message request.
- Private notes on athlete profiles are visible only to the recruiter or club scout who created them.
- Club scouts operate under the club's account and subscription but have individual logins.
- Profile analytics beyond aggregate counts are gated behind the Premium Athlete or Pro Recruiter tier.

## Invariants

1. **Athlete consent gate is inviolable.** No message thread opens without an accepted message request from the athlete. This must be enforced at the messaging service boundary, not just in the UI.
2. **Trust badges are not self-assigned.** Self-Reported is the default state. Coach-Endorsed requires a coach with a verified account to endorse. Club-Verified requires a verified club to confirm the roster entry. No badge upgrade happens without the appropriate external actor triggering it.
3. **Videos are never stored in the database.** Video files go to file storage only. The database holds the URL reference and metadata.
4. **Payment state is the source of truth for feature access.** Feature gating (shortlist limits, trial post limits, analytics visibility) must be derived from the payment/subscription record, not from any cached UI state.
5. **Capacity-limited opportunity postings close automatically.** When an opportunity reaches its capacity limit, applications are closed at the data layer — not just hidden in the UI.
6. **Recruiter and club features are disabled until verification is approved.** Unverified accounts in these roles can register but cannot shortlist, contact athletes, or post opportunities.
7. **Under-18 safeguards apply at the account layer.** Additional content and contact restrictions for users under 18 must be enforced server-side.