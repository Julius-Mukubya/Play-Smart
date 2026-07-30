-- Fixes: "new row violates row-level security policy for table
-- athlete_content" (PostgrestException 42501) on upload.
--
-- context/supabase-backend.md's RLS section (6) never actually listed a
-- policy for public.athlete_content — only for the *storage bucket* of the
-- same name. RLS is on by default on Supabase-dashboard-created tables with
-- zero policies, so every insert was denied. Ownership flows through
-- athlete_content.athlete_id -> athletes.user_id = auth.uid().
--
-- Run this once against your project (SQL Editor, or `supabase db push`).
-- Idempotent — safe to re-run.

alter table public.athlete_content enable row level security;

drop policy if exists "Athlete content is publicly readable" on public.athlete_content;
create policy "Athlete content is publicly readable"
on public.athlete_content for select
using (true);

drop policy if exists "Athletes manage their own content rows" on public.athlete_content;
create policy "Athletes manage their own content rows"
on public.athlete_content for insert
with check (
  exists (
    select 1 from public.athletes a
    where a.id = athlete_content.athlete_id and a.user_id = auth.uid()
  )
);

drop policy if exists "Athletes update their own content rows" on public.athlete_content;
create policy "Athletes update their own content rows"
on public.athlete_content for update
using (
  exists (
    select 1 from public.athletes a
    where a.id = athlete_content.athlete_id and a.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.athletes a
    where a.id = athlete_content.athlete_id and a.user_id = auth.uid()
  )
);

drop policy if exists "Athletes delete their own content rows" on public.athlete_content;
create policy "Athletes delete their own content rows"
on public.athlete_content for delete
using (
  exists (
    select 1 from public.athletes a
    where a.id = athlete_content.athlete_id and a.user_id = auth.uid()
  )
);

-- Storage bucket policy from context/supabase-backend.md section 5 — the
-- object-storage half of the same fix, needed if the bucket policy was
-- never applied either. Path convention: athlete-content/{user_id}/{content_id}/{filename}.
drop policy if exists "Athletes manage own content files" on storage.objects;
create policy "Athletes manage own content files"
on storage.objects for all
using (bucket_id = 'athlete-content' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'athlete-content' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "Athlete content files are publicly readable" on storage.objects;
create policy "Athlete content files are publicly readable"
on storage.objects for select
using (bucket_id = 'athlete-content');
