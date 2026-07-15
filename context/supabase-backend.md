# Supabase Backend Specification

This document is the implementation spec for replacing PlaySmart's local/mock data layer
(`lib/**/repositories/*.dart`) with a real Supabase backend. It is derived directly from:

- `lib/shared/types/domain_types.dart` (canonical domain model)
- Every repository in `lib/*/repositories/*.dart` (exact CRUD operations the app performs today)
- `context/project-overview.md` and `context/architecture.md` (product rules and invariants)
- `context/code-standards.md` and `context/test-context.md` (enforcement rules and test gates)
- `lib/settings/screens/privacy_safety_screen.dart` (privacy toggle fields not yet in the domain model)

Nothing here should require changing the Flutter UI layer — only the repository implementations
swap from in-memory mock lists to Supabase client calls.

---

## 1. Scope & Current State

- The app is 100% mock/local today (`MockData` class + in-memory lists per repository). No
  Supabase/Firebase package is in `pubspec.yaml` yet and no `.env` exists.
- 10 system boundaries exist and are feature-complete on the client: Auth, Profiles, Content,
  Discovery, Shortlisting, Messaging, Opportunities, Analytics, Notifications, Payments.
- Only `/admin` is a placeholder — the admin/moderation backend (verification approval) has no
  UI yet but is referenced in `architecture.md` as a required boundary.
- Goal of this doc: give every table, policy, function, and storage bucket needed to make each
  repository's methods real, without changing their method signatures.

---

## 2. Project Setup

### Extensions
```sql
create extension if not exists "pgcrypto";   -- gen_random_uuid()
create extension if not exists "pg_trgm";    -- fuzzy text search (athlete name/sport/position)
create extension if not exists "pg_cron";    -- scheduled jobs (grace period downgrade)
```

### Flutter dependency
Add to `pubspec.yaml`:
```yaml
dependencies:
  supabase_flutter: ^2.x
```

### Environment variables (client)
| Variable | Purpose |
| --- | --- |
| `SUPABASE_URL` | Project API URL |
| `SUPABASE_ANON_KEY` | Public anon key (client) |

### Environment variables (server / Edge Functions only — never shipped in the app)
| Variable | Purpose |
| --- | --- |
| `SUPABASE_SERVICE_ROLE_KEY` | Bypasses RLS for trusted server-side operations |
| `PESAPAL_CONSUMER_KEY` / `PESAPAL_CONSUMER_SECRET` | Mobile money payments (MTN/Airtel via Pesapal) |
| `FLUTTERWAVE_SECRET_KEY` / `FLUTTERWAVE_WEBHOOK_HASH` | Card + mobile money alternative |
| `STRIPE_SECRET_KEY` / `STRIPE_WEBHOOK_SECRET` | International cards |
| `FCM_SERVER_KEY` (or Firebase service account JSON) | Push notification delivery |
| `RESEND_API_KEY` (or similar) | Receipt/invoice emails |

---

## 3. Auth Design

Supabase Auth (`auth.users`) handles credentials/sessions. A mirrored `public.users` row holds
the app's profile/role data (matches the Dart `User` model exactly).

```sql
create type account_role as enum ('athlete', 'recruiter', 'club', 'coach', 'admin');
create type verification_status as enum ('pending', 'approved', 'rejected');
create type subscription_tier as enum (
  'free', 'premium_monthly', 'premium_annual',
  'recruiter_basic', 'recruiter_pro',
  'club_grassroots', 'club_professional', 'club_enterprise'
);

create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  email text not null unique,
  role account_role not null,
  verification_status verification_status not null default 'pending',
  subscription_tier subscription_tier not null default 'free',
  date_of_birth date,
  is_under_18 boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

> **Note on `account_role`:** the Dart `AccountRole` enum only has `athlete | recruiter | club |
> guest`. `guest` is not a real account (unauthenticated), so it's excluded from the DB enum.
> `coach` and `admin` are **additions** — see [Section 12, Decision 1](#12-open-decisions-needed-from-you).

### Sign-up flow (`AuthRepository.signUp` → `SignUpData`)
1. Client calls `supabase.auth.signUp(email, password)`.
2. A trigger on `auth.users` insert creates the matching `public.users` row:

```sql
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (id, name, email, role, date_of_birth, is_under_18, verification_status)
  values (
    new.id,
    new.raw_user_meta_data ->> 'name',
    new.email,
    (new.raw_user_meta_data ->> 'role')::account_role,
    (new.raw_user_meta_data ->> 'date_of_birth')::date,
    coalesce(
      extract(year from age((new.raw_user_meta_data ->> 'date_of_birth')::date)) < 18,
      false
    ),
    case when (new.raw_user_meta_data ->> 'role')::account_role = 'athlete'
      then 'approved' else 'pending' end
  );
  -- seed default privacy settings (Section 6)
  insert into public.user_privacy_settings (user_id) values (new.id);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
```

This reproduces `AuthRepository.signUp` exactly: athletes are auto-approved,
recruiters/clubs start `pending`, `is_under_18` is derived from DOB — server-side, matching
architecture.md invariant #7 ("Under-18 safeguards apply at the account layer").

### Sign-in / session
Use `supabase.auth.signInWithPassword` / `supabase.auth.currentSession` directly —
`AuthRepository.signIn`, `signOut`, `getSession` map 1:1 to Supabase Auth SDK calls. No custom
table logic needed beyond the `users` row already created at sign-up.

### JWT claims for RLS
Add `role` to the JWT via a custom access token hook (Auth → Hooks) so RLS policies can check
`(auth.jwt() ->> 'role')` without a subquery on every row:

```sql
create or replace function public.custom_access_token_hook(event jsonb)
returns jsonb as $$
declare
  claims jsonb;
  user_role account_role;
begin
  select role into user_role from public.users where id = (event->>'user_id')::uuid;
  claims := event->'claims';
  claims := jsonb_set(claims, '{user_role}', to_jsonb(user_role));
  event := jsonb_set(event, '{claims}', claims);
  return event;
end;
$$ language plpgsql stable;
```
Register this under Authentication → Hooks → Custom Access Token in the Supabase dashboard.

---

## 4. Full Schema

### 4.1 Enums (beyond `account_role`, `verification_status`, `subscription_tier` above)

```sql
create type trust_badge_level as enum ('self_reported', 'coach_endorsed', 'club_verified');
create type availability_status as enum ('open_to_trials', 'currently_contracted', 'not_available');
create type moment_type as enum ('goal', 'assist', 'sprint', 'tackle', 'save');
create type content_type as enum ('video', 'photo', 'post');
create type notification_type as enum (
  'profile_view', 'shortlisted', 'trial_match', 'endorsement_request', 'message_request'
);
create type payment_provider as enum ('mtn_mobile_money', 'airtel_money', 'visa_mastercard', 'stripe');
create type payment_status as enum ('pending', 'success', 'failed', 'refunded');
create type subscription_status as enum ('active', 'grace_period', 'expired', 'cancelled');
```

### 4.2 Profiles boundary

```sql
create table public.athletes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.users(id) on delete cascade,
  display_name text not null,
  photo_url text,
  sports text[] not null default '{}',
  positions text[] not null default '{}',
  age int,
  height numeric,
  weight numeric,
  dominant_foot_hand text,
  current_team text,
  country text,
  city text,
  bio text,
  availability_status availability_status not null default 'open_to_trials',
  -- derived columns, recalculated server-side only (see Section 8 triggers)
  profile_badge_level trust_badge_level not null default 'self_reported',
  profile_completeness numeric not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.achievements (
  id uuid primary key default gen_random_uuid(),
  athlete_id uuid not null references public.athletes(id) on delete cascade,
  title text not null,
  description text not null default '',
  badge_level trust_badge_level not null default 'self_reported',
  endorsed_by_id uuid references public.users(id),
  endorsed_by_name text,
  created_at timestamptz not null default now()
);

create table public.athlete_content (
  id uuid primary key default gen_random_uuid(),
  athlete_id uuid not null references public.athletes(id) on delete cascade,
  type content_type not null,
  title text not null,
  description text not null default '',
  file_url text,        -- storage reference only — never a blob (architecture.md invariant #3)
  thumbnail_url text,
  moment_tag moment_type,
  like_count int not null default 0,
  comment_count int not null default 0,
  created_at timestamptz not null default now()
);

-- Backs the "Club Tools: roster confirmation" feature and the club_verified badge invariant.
-- Not yet a Dart model — required to enforce "no badge upgrade without the correct external actor".
create table public.roster_confirmations (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.users(id),
  athlete_id uuid not null references public.athletes(id) on delete cascade,
  status text not null check (status in ('current', 'past')),
  confirmed_at timestamptz not null default now(),
  unique (club_id, athlete_id)
);

-- Backs "Club Tools: assign internal scouts operating under the club account".
create table public.club_scouts (
  club_id uuid not null references public.users(id),
  scout_user_id uuid not null references public.users(id),
  assigned_at timestamptz not null default now(),
  primary key (club_id, scout_user_id)
);

-- Backs the recruiter/club verification submission flow (admin/screens/verification_screen.dart).
create table public.verification_documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  document_url text not null,
  document_type text not null,
  status verification_status not null default 'pending',
  reviewed_by uuid references public.users(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

-- Backs discover feed engagement. Today `DiscoveryRepository.getContentFeed` fakes
-- `likeCount`/`commentCount` via `content.id.hashCode % N` — replace with real counts.
create table public.content_likes (
  content_id uuid not null references public.athlete_content(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (content_id, user_id)
);

create table public.content_comments (
  id uuid primary key default gen_random_uuid(),
  content_id uuid not null references public.athlete_content(id) on delete cascade,
  user_id uuid not null references public.users(id),
  text text not null,
  created_at timestamptz not null default now()
);
-- athlete_content.like_count / comment_count columns above become denormalized counters,
-- kept in sync via triggers on content_likes / content_comments (insert/delete -> +1/-1).

-- Backs settings/screens/privacy_safety_screen.dart toggles (not in domain_types.dart today).
create table public.user_privacy_settings (
  user_id uuid primary key references public.users(id) on delete cascade,
  public_profile boolean not null default true,
  show_location boolean not null default true,
  allow_message_requests boolean not null default true,
  show_in_search boolean not null default true,
  analytics_opt_in boolean not null default true,
  updated_at timestamptz not null default now()
);
```

### 4.3 Shortlisting boundary

`Shortlist.privateNotes` is a `Map<athleteId, note>` in Dart — normalize it into a join table:

```sql
create table public.shortlists (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.users(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.shortlist_athletes (
  shortlist_id uuid not null references public.shortlists(id) on delete cascade,
  athlete_id uuid not null references public.athletes(id) on delete cascade,
  private_note text,
  added_at timestamptz not null default now(),
  primary key (shortlist_id, athlete_id)
);
```
`ShortlistRepository.getTotalShortlistedAthletes` / `getShortlistCount` become simple counts/joins.

### 4.4 Opportunities boundary

```sql
create table public.opportunities (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references public.users(id),
  creator_role account_role not null,
  title text not null,
  sport text not null,
  position text,
  location text,
  event_date timestamptz,          -- Dart: `date` (renamed — reserved-adjacent word)
  min_age int,
  max_age int,
  description text not null default '',
  capacity int not null default 0,
  application_count int not null default 0,  -- derived, see trigger in Section 8
  is_closed boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.applications (
  id uuid primary key default gen_random_uuid(),
  opportunity_id uuid not null references public.opportunities(id) on delete cascade,
  athlete_id uuid not null references public.athletes(id),
  athlete_name text not null,
  message text not null default '',
  accepted boolean not null default false,
  created_at timestamptz not null default now(),
  unique (opportunity_id, athlete_id)  -- enforces "duplicate applications blocked"
);
```

### 4.5 Messaging boundary

The app treats an accepted `MessageRequest` *as* the conversation (`Message.conversationId`
points at the request's id) — keep that shape rather than inventing a separate conversations table.

```sql
create table public.message_requests (
  id uuid primary key default gen_random_uuid(),
  from_user_id uuid not null references public.users(id),
  from_user_name text not null,
  to_user_id uuid not null references public.users(id),
  message text not null default '',
  accepted boolean not null default false,
  requires_monitoring boolean not null default false, -- set true if either party is under 18 (MessagingService rule)
  created_at timestamptz not null default now()
);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.message_requests(id) on delete cascade,
  sender_id uuid not null references public.users(id),
  text text not null,
  read boolean not null default false,
  sent_at timestamptz not null default now()
);
```

### 4.6 Notifications & Analytics boundaries

```sql
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  type notification_type not null,
  title text not null,
  body text not null,
  related_id uuid,
  read boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.analytics_events (
  id uuid primary key default gen_random_uuid(),
  athlete_id uuid not null references public.athletes(id) on delete cascade,
  viewer_id uuid references public.users(id),
  viewer_name text,
  event_type text not null check (event_type in ('view', 'shortlist')),
  occurred_at timestamptz not null default now()  -- Dart: `timestamp` (reserved word)
);
```

### 4.7 Payments boundary

`SubscriptionPlan` is a catalog (seed data); `users.subscription_tier` alone can't express grace
periods or history, so add a `subscriptions` table per architecture.md invariant #4
("payment state is the source of truth for feature access").

```sql
create table public.subscription_plans (
  tier subscription_tier primary key,
  name text not null,
  price_ugx numeric not null,
  features text[] not null default '{}',
  is_popular boolean not null default false
);

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  tier subscription_tier not null,
  status subscription_status not null default 'active',
  current_period_start timestamptz not null default now(),
  current_period_end timestamptz,
  grace_period_ends_at timestamptz,
  provider payment_provider,
  provider_subscription_ref text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.payment_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id),
  amount_ugx numeric not null,
  provider payment_provider not null,
  provider_ref text,             -- external gateway transaction id — webhook idempotency key
  description text not null,
  status payment_status not null default 'pending',
  created_at timestamptz not null default now()
);
create unique index on public.payment_transactions (provider, provider_ref) where provider_ref is not null;

create table public.post_boosts (
  id uuid primary key default gen_random_uuid(),
  content_id uuid not null references public.athlete_content(id) on delete cascade,
  user_id uuid not null references public.users(id),
  transaction_id uuid references public.payment_transactions(id),
  starts_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '7 days'),
  created_at timestamptz not null default now()
);
```

---

## 5. Storage Buckets

| Bucket | Public? | Contents | Write access |
| --- | --- | --- | --- |
| `avatars` | public read | Athlete/user profile photos | Owner only |
| `athlete-content` | public read | Compressed videos, photos, thumbnails | Athlete owner only |
| `verification-documents` | private | Recruiter/club credential uploads | Owner (insert), admin (read) |
| `profile-exports` | private | Generated PDF profile exports | Edge Function only (service role); read via signed URL |

Per architecture.md invariant #3, `athlete_content.file_url` / `thumbnail_url` and
`users`/`athletes`.`photo_url` store **storage URLs only** — never binary data in Postgres.

Example policy (`athlete-content` bucket, owner-write):
```sql
create policy "Athletes manage own content files"
on storage.objects for all
using (bucket_id = 'athlete-content' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'athlete-content' and (storage.foldername(name))[1] = auth.uid()::text);
```
(Path convention: `athlete-content/{user_id}/{content_id}/{filename}`.)

---

## 6. Row Level Security

Enable RLS on every table (`alter table ... enable row level security;`). Key policies, grouped
by the invariants in `architecture.md`:

### users
- `select`: self, or any authenticated user reading only public-safe columns via the
  `v_public_profile` view (Section 9) — do not grant broad `select` on the raw `users` table.
- `update`: self only, and never on `role`, `verification_status`, or `subscription_tier`
  (those change only via trigger / service-role Edge Function).

### athletes
- `select`: `true` if `EXISTS user_privacy_settings.public_profile = true` for that athlete's
  `user_id` (guest browsing), **or** `auth.uid() = user_id` (owner), **or**
  `auth.jwt()->>'user_role' in ('recruiter','club','admin')` (discovery/search needs to see
  profiles regardless of the guest-facing public flag — `show_in_search` only gates search
  *ranking*, not existence, per current `DiscoveryRepository` which has no privacy filtering yet).
- `insert`/`update`: owner only, **and** `profile_badge_level` / `profile_completeness` must be
  excluded from the allowed update columns (enforce via a `before update` trigger that always
  recomputes them server-side, ignoring whatever the client sent — see Section 8).

### achievements
- `insert`: owner-athlete only, and a trigger forces `badge_level = 'self_reported'` regardless
  of client input (invariant #2: badges are never self-assigned).
- `update` (badge upgrade): **no direct client UPDATE grant.** Expose an RPC function
  `upgrade_achievement_badge(achievement_id uuid)` (Section 8) that checks `auth.jwt()->>'user_role'`
  and only allows `coach`/`club` actors to advance the level — mirrors `TrustBadgeService` exactly.

### shortlists / shortlist_athletes
- All operations: `owner_id = auth.uid()` only. Private notes must never be selectable by the
  athlete they're about (architecture.md: "Private notes ... visible only to the recruiter or
  club scout who created them").

### opportunities / applications
- `opportunities` insert: `auth.jwt()->>'user_role' in ('recruiter','club')` **and**
  `verification_status = 'approved'` (invariant #6 — unverified accounts cannot post).
- `applications` insert: athlete role only, must **not** be allowed as a raw client insert if
  `is_closed = true` or `application_count >= capacity` — enforce via RPC
  `apply_to_opportunity(opportunity_id, message)` (Section 8) rather than a direct table policy,
  since capacity-check-then-increment must be atomic (invariant #5).

### message_requests / messages
- `message_requests` insert: any authenticated non-athlete role can message an athlete only if
  the sender's own `verification_status = 'approved'` **and** the target athlete's
  `user_privacy_settings.allow_message_requests = true`; an athlete may reply-insert
  only to requests already addressed to them. Set `requires_monitoring = true` at insert time if
  either party's `is_under_18 = true` (mirrors `MessagingService`'s under-18 flagging).
- `messages` insert: **only** if the parent `message_requests.accepted = true` — enforce with a
  `before insert` trigger/RPC, not just RLS, per code-standards.md ("Enforce this at the service
  layer, not just in the UI"). Also block insert if either party is under 18 and the counterpart
  is not an approved recruiter/club (invariant / Phase 6 under-18 safeguard).

### notifications
- `select`/`update (read)`: `user_id = auth.uid()` only.
- `insert`: **service role / Edge Functions / triggers only** — never client-inserted
  (code-standards.md: "Do not fire notifications directly from UI components").

### analytics_events
- `insert`: any authenticated recruiter/club (or anonymous, if you want guest views counted) via
  RPC `record_profile_view(athlete_id)` — never a raw insert, so `viewer_id` can't be spoofed.
- `select` (full identity, `viewer_id`/`viewer_name`): only if the athlete's subscription tier is
  `premium_monthly`/`premium_annual`; otherwise expose only aggregate counts through
  `get_view_count(athlete_id)` / `get_shortlist_count(athlete_id)` RPCs (mirrors
  `AnalyticsRepository.getViewCount` vs `getFullAnalytics`).

### subscriptions / payment_transactions / post_boosts
- All writes: **service role only**, applied exclusively from verified payment-provider webhooks
  (code-standards.md: "Payment state changes must only be applied via webhook ... never from
  client-side callbacks alone"). Clients get read-only `select` scoped to `user_id = auth.uid()`.

---

## 7. Views

```sql
-- Guest/public-safe athlete card — hides city when show_location = false.
create view public.v_athlete_public as
select
  a.id, a.display_name, a.photo_url, a.sports, a.positions, a.age,
  case when ups.show_location then a.city else null end as city,
  a.country, a.availability_status, a.profile_badge_level, a.profile_completeness
from public.athletes a
join public.user_privacy_settings ups on ups.user_id = a.user_id
where ups.public_profile = true;
```

---

## 8. Functions & Triggers

```sql
-- Generic updated_at bump
create or replace function public.set_updated_at()
returns trigger as $$ begin new.updated_at = now(); return new; end; $$ language plpgsql;
-- attach to: users, athletes, shortlists, subscriptions

-- Recalculate athletes.profile_completeness (mirrors ProfileRepository.calculateCompleteness)
create or replace function public.recalc_profile_completeness()
returns trigger as $$
declare filled int := 0; total int := 11;
begin
  if length(coalesce(new.display_name,'')) > 0 then filled := filled + 1; end if;
  if array_length(new.sports,1) > 0 then filled := filled + 1; end if;
  if array_length(new.positions,1) > 0 then filled := filled + 1; end if;
  if new.age is not null then filled := filled + 1; end if;
  if new.height is not null then filled := filled + 1; end if;
  if new.weight is not null then filled := filled + 1; end if;
  if length(coalesce(new.dominant_foot_hand,'')) > 0 then filled := filled + 1; end if;
  if length(coalesce(new.current_team,'')) > 0 then filled := filled + 1; end if;
  if length(coalesce(new.country,'')) > 0 then filled := filled + 1; end if;
  if length(coalesce(new.bio,'')) > 0 then filled := filled + 1; end if;
  if new.photo_url is not null then filled := filled + 1; end if;
  new.profile_completeness := filled::numeric / total;
  return new;
end;
$$ language plpgsql;
create trigger trg_completeness before insert or update on public.athletes
  for each row execute function public.recalc_profile_completeness();

-- Recalculate athletes.profile_badge_level from its achievements (highest badge wins)
create or replace function public.recalc_profile_badge()
returns trigger as $$
begin
  update public.athletes set profile_badge_level = coalesce((
    select max(badge_level) from public.achievements where athlete_id = coalesce(new.athlete_id, old.athlete_id)
  ), 'self_reported')
  where id = coalesce(new.athlete_id, old.athlete_id);
  return null;
end;
$$ language plpgsql;
create trigger trg_badge_from_achievements
  after insert or update or delete on public.achievements
  for each row execute function public.recalc_profile_badge();
-- Note: trust_badge_level enum order (self_reported < coach_endorsed < club_verified) must match
-- declaration order above so max() picks the highest tier correctly.

-- Badge upgrade RPC — the only sanctioned path to advance an achievement's badge (invariant #2)
create or replace function public.upgrade_achievement_badge(p_achievement_id uuid)
returns public.achievements as $$
declare
  actor_role account_role := (auth.jwt() ->> 'user_role')::account_role;
  achievement public.achievements;
begin
  select * into achievement from public.achievements where id = p_achievement_id;
  if achievement.badge_level = 'self_reported' and actor_role in ('coach','club') then
    update public.achievements set badge_level = 'coach_endorsed',
      endorsed_by_id = auth.uid(),
      endorsed_by_name = (select name from public.users where id = auth.uid())
      where id = p_achievement_id returning * into achievement;
  elsif achievement.badge_level = 'coach_endorsed' and actor_role = 'club' then
    update public.achievements set badge_level = 'club_verified',
      endorsed_by_id = auth.uid(),
      endorsed_by_name = (select name from public.users where id = auth.uid())
      where id = p_achievement_id returning * into achievement;
  else
    raise exception 'Invalid badge upgrade for actor role %', actor_role;
  end if;
  return achievement;
end;
$$ language plpgsql security definer;

-- Atomic apply-to-opportunity — capacity check + increment + auto-close (invariant #5)
create or replace function public.apply_to_opportunity(p_opportunity_id uuid, p_message text default '')
returns public.applications as $$
declare
  opp public.opportunities;
  athlete_row public.athletes;
  new_application public.applications;
begin
  select * into athlete_row from public.athletes where user_id = auth.uid();
  select * into opp from public.opportunities where id = p_opportunity_id for update;
  if opp.is_closed then raise exception 'This opportunity is closed.'; end if;
  if opp.application_count >= opp.capacity then raise exception 'This opportunity has reached its capacity.'; end if;

  insert into public.applications (opportunity_id, athlete_id, athlete_name, message)
  values (p_opportunity_id, athlete_row.id, athlete_row.display_name, p_message)
  returning * into new_application; -- unique constraint blocks duplicates

  update public.opportunities
  set application_count = application_count + 1,
      is_closed = (application_count + 1 >= capacity)
  where id = p_opportunity_id;

  return new_application;
end;
$$ language plpgsql security definer;

-- Enforce athlete consent gate on messages (invariant #1)
create or replace function public.check_message_consent()
returns trigger as $$
begin
  if not exists (
    select 1 from public.message_requests
    where id = new.conversation_id and accepted = true
  ) then
    raise exception 'Cannot send a message until the athlete accepts the request.';
  end if;
  return new;
end;
$$ language plpgsql;
create trigger trg_message_consent before insert on public.messages
  for each row execute function public.check_message_consent();
```

> Every RPC above uses `security definer` intentionally so it can update rows the calling
> client's RLS policies wouldn't otherwise let them touch directly — this is what makes it safe
> to *not* grant raw `UPDATE`/`INSERT` on `opportunities.application_count` or
> `achievements.badge_level` to clients at all.

---

## 9. Notification Triggers

Per code-standards.md, notifications fire from the owning boundary, never the UI. Implement as
triggers that call `notifications` insert directly (cheapest) or invoke an Edge Function via
`pg_net`/Database Webhooks for the ones that also need a push notification:

| Event | Trigger source | `notification_type` |
| --- | --- | --- |
| Profile viewed | `analytics_events` insert where `event_type = 'view'` | `profile_view` |
| Shortlisted | `shortlist_athletes` insert | `shortlisted` |
| Trial match | `apply_to_opportunity` RPC, or a matching rule on new `opportunities` insert | `trial_match` |
| Endorsement requested | new row in a to-be-added `endorsement_requests` table (athlete asks a coach) | `endorsement_request` |
| Message request sent | `message_requests` insert | `message_request` |

Configure a **Database Webhook** on `public.notifications` (`insert`) → Edge Function
`send-push-notification` → FCM, so every notification path (regardless of which trigger created
it) automatically gets push delivery for free.

---

## 10. Edge Functions

| Function | Trigger | Responsibility |
| --- | --- | --- |
| `payment-webhook` | HTTP (Pesapal/Flutterwave/Stripe callback) | Verify signature, upsert `payment_transactions` by `provider_ref` (idempotent), update `subscriptions`/`users.subscription_tier`, insert a `payment_transaction` receipt notification |
| `send-push-notification` | DB Webhook on `notifications` insert | Look up device tokens, call FCM |
| `export-athlete-pdf` | HTTP (called by recruiter "Export PDF" action) | Render athlete profile to PDF, upload to `profile-exports`, return a signed URL |
| `grace-period-sweep` | `pg_cron` schedule, hourly | Find `subscriptions` where `status = 'grace_period' and grace_period_ends_at < now()`, downgrade to `free` (test-context.md: "3 days later account downgrades to free tier") |

```sql
select cron.schedule('grace-period-sweep', '0 * * * *',
  $$ select net.http_post(url := '<edge-function-url>/grace-period-sweep') $$);
```

Video compression is explicitly **not** an Edge Function responsibility — `architecture.md`
already marks storage as "ready for Cloudinary/S3" and Edge Functions have tight execution-time
limits unsuited to video transcoding. Recommend uploading directly to Cloudinary (or Mux) from
the client and storing only the returned URL in `athlete_content.file_url`. See
[Decision 3](#12-open-decisions-needed-from-you).

---

## 11. Realtime & Search

- **Realtime**: enable replication on `messages` and `notifications` so `messages_screen.dart`
  and the unread-badge get live updates instead of polling. In Supabase: Database → Replication →
  add both tables to the `supabase_realtime` publication.
- **Search**: `DiscoveryRepository.searchAthletes` does substring matching across name/sport/
  position/city/country. Back it with `pg_trgm` GIN indexes rather than client-side filtering:

```sql
create index idx_athletes_display_name_trgm on public.athletes using gin (display_name gin_trgm_ops);
create index idx_athletes_sports on public.athletes using gin (sports);
create index idx_athletes_positions on public.athletes using gin (positions);
create index idx_athletes_city_country on public.athletes (city, country);
create index idx_athletes_availability on public.athletes (availability_status);
```

---

## 12. Open Decisions Needed From You

These are gaps between the current mock implementation and a production backend — resolve before
building the corresponding piece:

1. **Coach identity.** `TrustBadgeService.upgradeBadge` currently treats *any* non-athlete actor
   as a valid coach-endorser, which is a placeholder (flagged in `progress-tracker.md`'s open
   questions). This spec adds a `coach` role to `account_role` and an `admin` role for
   verification approval — confirm you want a distinct `coach` account type (with its own
   verification), or a lighter-weight model (e.g., an athlete nominates a coach by phone number
   / invite code without a full account).
2. **Pricing.** Only 4 of 8 `SubscriptionPlan` tiers have real prices in `mock_data.dart`
   (`free`, `premium_monthly`, `recruiter_pro`, `club_professional`). `premium_annual`,
   `recruiter_basic`, `club_grassroots`, `club_enterprise` need UGX prices before seeding
   `subscription_plans`.
3. **Video pipeline.** Confirm whether video compression/storage is Cloudinary, Mux, or
   direct-to-Supabase-Storage with a separate compression step — affects whether
   `athlete_content.file_url` points at Supabase Storage or an external CDN.
4. **Push notifications.** FCM is assumed (matches `architecture.md`); confirm and get the
   service account / server key for the `send-push-notification` Edge Function.
5. **Payment providers.** Need live/sandbox credentials for Pesapal, Flutterwave, and Stripe, and
   confirmation of which one is primary for MTN/Airtel Mobile Money vs. cards.
6. **PDF export engine.** Recruiter "export profile as PDF" needs a rendering approach inside an
   Edge Function (e.g., `puppeteer`-in-Deno is heavy; consider a hosted HTML-to-PDF API instead).
7. **Admin moderation.** `/admin` is a placeholder in the app. This spec adds `verification_documents`
   and an `admin` role to unblock recruiter/club approval, but the actual admin UI and any
   content-moderation queue are not yet designed.

---

## 13. Migration Notes

- Seed `subscription_plans` from `MockData.subscriptionPlans` once pricing (Decision 2) is final.
- The existing `MockData` lists (`users`, `athletes`, `opportunities`, etc.) can be scripted into
  `insert` statements for local/staging seeding — same shape as the tables above.
- Repository swap is mechanical: each `lib/*/repositories/*_repository.dart` keeps its public
  method signatures and return types (already Dart domain objects), only the body changes from
  in-memory `List` operations to `supabase.from(...)` / `supabase.rpc(...)` calls.
