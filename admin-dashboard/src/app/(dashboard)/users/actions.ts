'use server';

import { revalidatePath } from 'next/cache';
import { requireAdmin } from '@/lib/auth';
import { createAdminClient } from '@/lib/supabase/admin';
import type { AccountRole } from '@/lib/types';

const VALID_ROLES: AccountRole[] = ['athlete', 'recruiter', 'club', 'coach', 'admin'];

export async function updateUserRole(userId: string, role: AccountRole) {
  await requireAdmin();
  if (!VALID_ROLES.includes(role)) throw new Error('Invalid role.');

  const admin = createAdminClient();
  const { error } = await admin.from('users').update({ role }).eq('id', userId);
  if (error) throw new Error(error.message);

  revalidatePath('/users');
}

export async function setUserBanned(userId: string, banned: boolean) {
  await requireAdmin();

  const admin = createAdminClient();
  const { error } = await admin.from('users').update({ is_banned: banned }).eq('id', userId);
  if (error) throw new Error(error.message);

  revalidatePath('/users');
}
