-- Backs push notification delivery (lib/core/push/push_notification_service.dart
-- + supabase/functions/send-push-notification). A user can have multiple
-- tokens (one per installed device).
--
-- Run this once against your project (SQL Editor, or `supabase db push`).
-- Idempotent — safe to re-run.

create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  token text not null unique,
  platform text not null check (platform in ('ios', 'android', 'web')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_device_tokens_user_id on public.device_tokens (user_id);

alter table public.device_tokens enable row level security;

-- Owner manages their own device's tokens; the Edge Function reads tokens
-- with the service role key, which bypasses RLS entirely.
create policy "Users manage their own device tokens"
on public.device_tokens for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create trigger trg_device_tokens_updated_at
  before update on public.device_tokens
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Wiring the Edge Function (manual dashboard step — not expressible in SQL
-- unless you also enable pg_net and hardcode the function URL/secret here):
--
-- Supabase Dashboard -> Database -> Webhooks -> Create a new webhook
--   Table: public.notifications        Events: Insert
--   Type:  Supabase Edge Function      Function: send-push-notification
--
-- This fires send-push-notification for every notification row, regardless
-- of which trigger created it (shortlisted, message_request, etc.) — see
-- context/supabase-backend.md section 9.
-- ---------------------------------------------------------------------------
