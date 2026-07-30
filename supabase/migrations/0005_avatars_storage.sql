-- Backs profile picture upload (ProfileRepository.uploadAvatar). Mirrors the
-- athlete-content bucket setup in 0003_athlete_content_rls.sql — public read,
-- owner-only write, path-scoped by auth.uid(). Per
-- context/supabase-backend.md section 5, this bucket was documented but
-- (like athlete_content's RLS) may never have actually been created.
--
-- Run this once against your project (SQL Editor, or `supabase db push`).
-- Idempotent — safe to re-run.

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- Path convention: avatars/{user_id}/{filename}.
drop policy if exists "Users manage their own avatar files" on storage.objects;
create policy "Users manage their own avatar files"
on storage.objects for all
using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "Avatar files are publicly readable" on storage.objects;
create policy "Avatar files are publicly readable"
on storage.objects for select
using (bucket_id = 'avatars');
