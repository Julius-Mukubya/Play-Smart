'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

export type LoginState = { error: string } | null;

export async function signIn(_prevState: LoginState, formData: FormData): Promise<LoginState> {
  const email = String(formData.get('email') ?? '').trim();
  const password = String(formData.get('password') ?? '');

  if (!email || !password) {
    return { error: 'Enter your email and password.' };
  }

  const supabase = await createClient();
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });

  if (error || !data.user) {
    return { error: 'Invalid email or password.' };
  }

  const { data: profile } = await supabase
    .from('users')
    .select('role, is_banned')
    .eq('id', data.user.id)
    .maybeSingle();

  if (!profile || profile.role !== 'admin' || profile.is_banned) {
    await supabase.auth.signOut();
    return { error: 'This account does not have admin access.' };
  }

  redirect('/');
}
