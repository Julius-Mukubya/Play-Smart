# Play Smart Admin Dashboard

Internal web dashboard for managing the Play Smart platform — separate from
the Flutter app, sharing the same Supabase project. Covers:

- **Users** — search, change role, ban/unban.
- **Content** — review uploaded photos/videos/posts, flag or remove.
- **Verification** — approve/reject recruiter & club credential submissions.
- **Subscriptions** — read-only view of active subscriptions and payment
  transactions.
- **Overview** — platform-wide counts and revenue.

## How this is wired up

Every privileged read/write (role changes, bans, content moderation,
verification decisions, and all the list views) goes through the Supabase
**service role key**, server-side only — never sent to the browser. This is
intentional: your Flutter app's RLS policies correctly lock most of this data
down from a normal user session (see `context/supabase-backend.md` section
6), so the admin dashboard needs the service role to do its job. `requireAdmin()`
(`src/lib/auth.ts`) is the actual gate — it's called by every page and every
Server Action, independent of the `proxy.ts` redirect, per Next.js's own
guidance that Server Functions are reachable directly and must verify auth
themselves.

## Setup

1. **Apply the migration** the dashboard depends on (adds `users.is_banned`,
   `athlete_content.flagged`, and ensures `verification_documents` exists):

   ```
   supabase/migrations/0004_admin_dashboard_support.sql
   ```

   Run it in the Supabase SQL Editor (same project as the Flutter app), or
   `supabase db push` if you have the CLI linked.

2. **Copy the env file** and fill in your project's values (Supabase
   Dashboard → Project Settings → API):

   ```bash
   cp .env.local.example .env.local
   ```

   `SUPABASE_SERVICE_ROLE_KEY` is the "service_role" secret key — **not**
   the anon key. Never commit `.env.local` or expose this key to a browser
   bundle.

3. **Promote your first admin.** There's no self-serve way to become an
   admin (by design — `account_role` includes `admin` but nothing in the app
   lets a user pick it at sign-up). Sign up normally through the Flutter app
   with the account you want to use, then run this once in the Supabase SQL
   Editor:

   ```sql
   update public.users set role = 'admin' where email = 'you@example.com';
   ```

4. **Install and run:**

   ```bash
   npm install
   npm run dev
   ```

   Open [http://localhost:3000](http://localhost:3000) and sign in with the
   account you promoted.

## Deploying

Any Node.js host works (Vercel is the path of least resistance for Next.js).
Set the same three env vars from `.env.local.example` in your host's
dashboard — `SUPABASE_SERVICE_ROLE_KEY` must be a **server-side-only**
secret, not a public/build-time variable.
