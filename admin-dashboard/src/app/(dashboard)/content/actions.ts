'use server';

import { revalidatePath } from 'next/cache';
import { requireAdmin } from '@/lib/auth';
import { createAdminClient } from '@/lib/supabase/admin';

export async function setContentFlagged(contentId: string, flagged: boolean) {
  await requireAdmin();

  const admin = createAdminClient();
  const { error } = await admin.from('athlete_content').update({ flagged }).eq('id', contentId);
  if (error) throw new Error(error.message);

  revalidatePath('/content');
}

/**
 * Deletes the content row only — mirrors the Flutter app's own
 * ContentRepository.deleteContent, which likewise doesn't clean up the
 * underlying storage object. Keeping behavior consistent rather than
 * introducing a dashboard-only storage-cleanup path.
 */
export async function deleteContent(contentId: string) {
  await requireAdmin();

  const admin = createAdminClient();
  const { error } = await admin.from('athlete_content').delete().eq('id', contentId);
  if (error) throw new Error(error.message);

  revalidatePath('/content');
}
