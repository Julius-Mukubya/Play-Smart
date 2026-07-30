-- Backs the new admin-dashboard: user ban/suspend, content flagging, and
-- recruiter/club verification review. context/supabase-backend.md documents
-- `verification_documents` (section 4.2) but it's never referenced by any
-- Dart repository, so it may not exist live — created defensively here.
--
-- Run this once against your project (SQL Editor, or `supabase db push`).
-- Idempotent — safe to re-run.

-- ---------------------------------------------------------------------------
-- 1. Moderation columns
-- ---------------------------------------------------------------------------

alter table public.users add column if not exists is_banned boolean not null default false;
alter table public.athlete_content add column if not exists flagged boolean not null default false;

-- Both columns are privileged (same class as role/verification_status per
-- section 6 of the design doc) — only the admin dashboard, which writes
-- with the service role key, may change them. A normal authenticated user's
-- own update to their `users`/`athlete_content` row must not be able to
-- smuggle a ban/flag change through, so pin these columns to their existing
-- value unless the request comes in via the service role.

create or replace function public.protect_is_banned()
returns trigger as $$
begin
  if auth.role() <> 'service_role' and new.is_banned is distinct from old.is_banned then
    new.is_banned := old.is_banned;
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_protect_is_banned on public.users;
create trigger trg_protect_is_banned
  before update on public.users
  for each row execute function public.protect_is_banned();

create or replace function public.protect_content_flagged()
returns trigger as $$
begin
  if auth.role() <> 'service_role' and new.flagged is distinct from old.flagged then
    new.flagged := old.flagged;
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_protect_content_flagged on public.athlete_content;
create trigger trg_protect_content_flagged
  before update on public.athlete_content
  for each row execute function public.protect_content_flagged();

-- ---------------------------------------------------------------------------
-- 2. Verification documents (recruiter/club submission review queue)
-- ---------------------------------------------------------------------------

create table if not exists public.verification_documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  document_url text not null,
  document_type text not null,
  status verification_status not null default 'pending',
  reviewed_by uuid references public.users(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_verification_documents_user_id on public.verification_documents (user_id);
create index if not exists idx_verification_documents_status on public.verification_documents (status);

alter table public.verification_documents enable row level security;

drop policy if exists "Users manage their own verification submissions" on public.verification_documents;
create policy "Users manage their own verification submissions"
on public.verification_documents for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Reviewing (approve/reject) is admin-dashboard only, via service role,
-- which bypasses RLS entirely — no separate admin policy needed here.
