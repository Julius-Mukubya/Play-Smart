# Mobile App ↔ Backend Integration Guide

This document is for whoever wires the **Flutter mobile app** up to the Supabase backend that
now exists. `supabase-backend.md` was the original spec the schema was designed from, but the
dashboard build deviated from it in five places, and the schema is now live — this doc is the
delta between "what that spec said" and "what's actually deployed", plus the practical
integration steps.

Read `supabase-backend.md` first for the full design rationale. This doc only covers what
changed and how to actually connect.

---

## 1. What changed from `supabase-backend.md`

These five differences matter to any repository/service layer built against the original spec:

1. **`account_role` has no `coach` value.** It's `'athlete' | 'recruiter' | 'club' | 'admin'`
   only — Decision 1 in the spec was resolved by folding "coach" into "recruiter." Anywhere the
   spec assumed a distinct coach account, use `recruiter` instead. `TrustBadgeService`-equivalent
   logic (badge upgrades) now checks for `recruiter` or `club`, not `coach` or `club`.
2. **`public.athletes` has `lat numeric` and `lng numeric`** (nullable) — not in the original
   spec. These are geocoded server-side from `city`/`country` (Database Webhook → Edge Function →
   Mapbox), **not written directly by the client**. Leave them alone when creating/updating an
   athlete profile; don't expect them to be populated immediately after a profile save.
3. **`public.shortlist_athletes` has a `stage` column** (`text`, default `'shortlisted'`, one of
   `shortlisted | contacted | invited | evaluated`) — this backs the web dashboard's outreach
   Kanban board. Not part of the mobile app's `Shortlist` model; you can ignore it entirely unless
   the mobile app ever needs to show outreach stage to an athlete.
4. **`public.applications` has a `status` enum** (`pending | accepted | rejected`) instead of a
   plain `accepted boolean`. **`accepted` still exists** as a generated column
   (`generated always as (status = 'accepted') stored`), so any existing code reading
   `application.accepted` keeps working unchanged — you get a real "rejected" state for free if
   you start reading `status` instead.
5. **New table: `public.content_reports`** (`content_id`, `reporter_id`, `reason`, `status`,
   `created_at`) — backs admin moderation, which didn't have a table in the original spec. If the
   mobile app has a "report this video" action, insert here instead of anything ad hoc.

Everything else — table names, columns, RLS shape, RPCs, triggers — matches
`supabase-backend.md` as written.

---

## 2. Project credentials

Get these from **Supabase Dashboard → Project Settings → API** (same project the web dashboard
uses — check `.env.local` in this repo for the project ref if you're unsure which project that
is):

| Value | Where it's used |
| --- | --- |
| Project URL | `SUPABASE_URL` |
| `anon` / `public` key | `SUPABASE_ANON_KEY` |

Never embed the `service_role` key in the mobile app — it bypasses every RLS policy in this
schema. It's server-only (used by Edge Functions, the web dashboard's admin routes).

```yaml
# pubspec.yaml
dependencies:
  supabase_flutter: ^2.x
```

```dart
await Supabase.initialize(
  url: 'SUPABASE_URL',
  anonKey: 'SUPABASE_ANON_KEY',
);
```

---

## 3. Auth integration

Supabase Auth (`auth.users`) is the identity provider. A database trigger
(`handle_new_user`, fires `after insert on auth.users`) creates the matching `public.users` row
automatically — **the client never inserts into `public.users` directly.**

### Sign-up

The trigger reads three keys out of the signup call's user metadata:

```dart
await supabase.auth.signUp(
  email: email,
  password: password,
  data: {
    'name': displayName,
    'role': 'athlete', // or 'recruiter' | 'club' — never 'admin' (no self-service path)
    'date_of_birth': '2008-03-14', // ISO date string, or omit entirely for recruiter/club
  },
);
```

What the trigger does with this, automatically:
- Creates `public.users` with `role`, `name`, `email` (from the auth record).
- Computes `is_under_18` from `date_of_birth` (defaults `false` if omitted).
- Sets `verification_status = 'approved'` if `role = 'athlete'`, otherwise `'pending'` (recruiters
  and clubs need admin approval before they can post trials, message athletes, etc. — see
  `architecture.md` invariant #6, unchanged from the spec).
- Seeds a default `public.user_privacy_settings` row for the new user.

If your Supabase project has **"Confirm email"** enabled (check Authentication → Providers →
Email), `signUp` won't return a session until the user clicks the confirmation link — handle that
state (there's no session yet, but the account and profile row already exist).

### Sign-in / session

`supabase.auth.signInWithPassword(...)`, `supabase.auth.currentSession`, `supabase.auth.signOut()`
map directly — no custom logic needed, the `public.users` row was already created at sign-up.

### Role/session claims

There's a Custom Access Token Hook (`custom_access_token_hook`) registered in this project that
embeds the user's role into the session JWT as a `user_role` claim, purely so Postgres RLS
policies can check `auth.jwt()->>'user_role'` cheaply. **You never need to read this claim from
the client** — it's an internal RLS optimization, not something app code depends on.

---

## 4. RPCs — call these instead of raw table writes

A handful of operations are **not** exposed as plain `INSERT`/`UPDATE` grants because they need
atomicity or server-side authorization that a raw table write can't provide. Call these via
`supabase.rpc(...)`:

| RPC | Who calls it | Purpose |
| --- | --- | --- |
| `apply_to_opportunity(p_opportunity_id uuid, p_message text default '')` | athlete | Atomically checks capacity, inserts the application, increments `opportunities.application_count`, auto-closes at capacity. Raises an exception if the opportunity is closed or full — catch and surface that to the user. |
| `record_profile_view(p_athlete_id uuid)` | recruiter/club/admin | Logs a profile view. Never insert into `analytics_events` directly — there's no client insert policy on that table at all. |
| `get_view_count(p_athlete_id uuid)` | anyone | Aggregate view count for an athlete. |
| `get_shortlist_count(p_athlete_id uuid)` | anyone | How many shortlists an athlete appears on. |
| `get_full_analytics(p_athlete_id uuid)` | athlete (own profile only) | Full per-viewer analytics — **raises an exception unless the athlete's `subscription_tier` is `premium_monthly` or `premium_annual`.** Use `get_view_count`/`get_shortlist_count` for the free-tier aggregate-only view. |
| `upgrade_achievement_badge(p_achievement_id uuid)` | recruiter/club | Advances a badge exactly **one tier per call** (`self_reported → coach_endorsed → club_verified`). This is web-dashboard-only in practice (clubs verifying roster spots), but if the mobile app ever adds an endorsement action, call this rather than updating `achievements.badge_level` directly — there's no update grant on that column at all. |

Example:

```dart
final application = await supabase.rpc('apply_to_opportunity', params: {
  'p_opportunity_id': opportunityId,
  'p_message': message,
});
```

---

## 5. RLS behavior worth knowing before you build against it

- **`achievements.badge_level` has no client update path at all.** Only `upgrade_achievement_badge`
  (security definer) can move it. A raw `update` from the client will be silently blocked by RLS.
- **`athletes.profile_badge_level` and `profile_completeness` are always server-recomputed.**
  Triggers overwrite whatever the client sends on every insert/update — completeness is
  recalculated from the row's own fields, badge level is recalculated from the athlete's
  achievements. Don't try to set these directly; it's a no-op.
- **Shortlist `private_note` is owner-only, by design.** An athlete can never read a recruiter's
  private note about them, even indirectly — there's no RLS path that exposes
  `shortlist_athletes` rows to the athlete they're about.
- **`messages` insert requires an accepted `message_requests` row first** (invariant #1 — a
  trigger raises an exception otherwise, this isn't just a UI guard). If either party is under 18,
  a second trigger additionally requires the counterpart to be an **approved** recruiter or club,
  or the insert is rejected.
- **`notifications` can never be inserted by a client**, only by triggers/service role. Don't try
  to create a notification row from the app to work around a missing feature — ask for the
  trigger to be added instead.
- **`opportunities` insert requires `verification_status = 'approved'`** on the creator's profile
  (recruiter/club only) — this is enforced in the RLS policy itself, not just app-side.

---

## 6. Storage buckets

| Bucket | Public? | Path convention | Notes |
| --- | --- | --- | --- |
| `avatars` | public read | `avatars/{user_id}/{filename}` | Owner-write only. |
| `athlete-content` | public read | `athlete-content/{user_id}/{content_id}/{filename}` | Owner-write only. Store the returned public URL in `athlete_content.file_url` / `thumbnail_url` — never upload binary data into a table column. |
| `verification-documents` | private | `verification-documents/{user_id}/{filename}` | Owner can upload; owner + admin can read. Use a signed URL if you need to display it back to the uploader. |
| `profile-exports` | private | n/a | Server/Edge-Function only — not relevant to the mobile app. |

Current per-bucket size limits: `avatars` 5MB, `athlete-content` 200MB, `verification-documents`
15MB. **Check your Supabase plan's global upload cap** (free tier defaults to 50MB regardless of
the bucket setting) before assuming large video uploads will succeed directly to Supabase Storage
— see the open "video pipeline" decision in `supabase-backend.md` §12 Decision 3, which is still
unresolved as of this writing.

---

## 7. What's NOT built yet

These pieces are referenced in `supabase-backend.md` §10 but have **not** been implemented as of
this doc — don't build mobile features that assume they exist:

- Edge Functions: `payment-webhook`, `send-push-notification`, `export-athlete-pdf`,
  `grace-period-sweep`, `geocode-athlete-location`.
- Push notifications (FCM) — `notifications` rows get created by triggers, but nothing delivers a
  push yet.
- Payment provider integration (Pesapal/Flutterwave/Stripe) — `payment_transactions` /
  `subscriptions` tables exist and are readable, but nothing writes to them yet outside manual
  testing.
- Realtime replication on `messages`/`notifications` — check Database → Replication before relying
  on live message delivery instead of polling.

---

## 8. Quick verification checklist

- [ ] `supabase.auth.signUp` with `role: 'athlete'` → confirm a `public.users` row appears with
      `verification_status = 'approved'`.
- [ ] Same, with `role: 'recruiter'` → confirm `verification_status = 'pending'`.
- [ ] Upload a file to `athlete-content/{your_user_id}/...` → confirm you can read it back via the
      public URL, and that a different user's client **cannot** upload into your folder.
- [ ] Call `apply_to_opportunity` twice against the same opportunity as the same athlete → second
      call should fail on the `unique (opportunity_id, athlete_id)` constraint, not create a
      duplicate.
- [ ] Try inserting a `messages` row directly (not via an accepted request) → should be rejected
      by `check_message_consent`.
