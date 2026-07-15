-- Enables Supabase Realtime (Postgres Changes) on the tables the mobile app
-- now subscribes to: lib/messaging/repositories/messaging_repository.dart
-- and lib/notifications/repositories/notification_repository.dart.
--
-- Run this once against your project (SQL Editor, or `supabase db push` if
-- you adopt the Supabase CLI for migrations). It is idempotent — safe to
-- re-run.
--
-- Postgres Changes respects each table's RLS SELECT policies per-subscriber
-- (see https://supabase.com/docs/guides/realtime/postgres-changes#security),
-- so no additional policy changes are needed here — the same RLS rules that
-- govern `select` also govern what a subscriber receives over the socket.

alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.notifications;

-- Included so the "pending requests" / "conversations" lists in
-- MessagingNotifier update live too (e.g. accepting a request on one device
-- updates the list on another) rather than just the notification badge.
alter publication supabase_realtime add table public.message_requests;
