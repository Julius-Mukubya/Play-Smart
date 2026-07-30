import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

export type AdminUser = {
  id: string;
  name: string;
  email: string;
  role: string;
};

/**
 * Returns the signed-in user's `public.users` row if — and only if — they
 * are an admin. Returns null for anonymous, non-admin, or banned users.
 *
 * Every dashboard page/layout AND every Server Action must call this (or
 * `requireAdmin`) itself. proxy.ts only does a fast cookie-presence check
 * for redirect UX — Next.js Server Functions are reachable directly via
 * POST regardless of proxy matchers, so this is the real gate.
 */
export async function getAdminUser(): Promise<AdminUser | null> {
  const supabase = await createClient();
  const {
    data: { user: authUser },
  } = await supabase.auth.getUser();
  if (!authUser) return null;

  const { data: profile } = await supabase
    .from('users')
    .select('id, name, email, role, is_banned')
    .eq('id', authUser.id)
    .maybeSingle();

  if (!profile || profile.role !== 'admin' || profile.is_banned) return null;

  return { id: profile.id, name: profile.name, email: profile.email, role: profile.role };
}

/** Same as `getAdminUser`, but redirects to /login instead of returning null. */
export async function requireAdmin(): Promise<AdminUser> {
  const admin = await getAdminUser();
  if (!admin) redirect('/login');
  return admin;
}
