import { createClient as createSupabaseClient } from '@supabase/supabase-js';

/**
 * Service-role Supabase client — bypasses Row Level Security entirely.
 *
 * SERVER-ONLY. Only import this from Server Actions/Route Handlers (files
 * with `'use server'`, or that are never bundled for the client). Never
 * import this from a Client Component or anything under `'use client'` —
 * the service role key must never reach the browser.
 *
 * This is what lets the dashboard change a user's role, ban/unban, moderate
 * content, and approve verification — actions your Flutter app's RLS
 * policies intentionally block from a normal authenticated session (see
 * context/supabase-backend.md section 6 and the protective triggers in
 * supabase/migrations/0004_admin_dashboard_support.sql).
 */
export function createAdminClient() {
  return createSupabaseClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    },
  );
}
