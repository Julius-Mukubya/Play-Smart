'use server';

import { revalidatePath } from 'next/cache';
import { requireAdmin } from '@/lib/auth';
import { createAdminClient } from '@/lib/supabase/admin';

async function reviewDocument(documentId: string, decision: 'approved' | 'rejected') {
  const admin = await requireAdmin();
  const supabase = createAdminClient();

  const { data: doc, error: fetchError } = await supabase
    .from('verification_documents')
    .select('user_id')
    .eq('id', documentId)
    .single();
  if (fetchError || !doc) throw new Error(fetchError?.message ?? 'Document not found.');

  const { error: docError } = await supabase
    .from('verification_documents')
    .update({ status: decision, reviewed_by: admin.id, reviewed_at: new Date().toISOString() })
    .eq('id', documentId);
  if (docError) throw new Error(docError.message);

  // Mirror the decision onto the user's overall verification_status — this
  // is the field RLS/UI elsewhere gate on (context/supabase-backend.md
  // section 6: "update: self only, and never on ... verification_status").
  const { error: userError } = await supabase
    .from('users')
    .update({ verification_status: decision })
    .eq('id', doc.user_id);
  if (userError) throw new Error(userError.message);

  revalidatePath('/verification');
  revalidatePath('/users');
}

export async function approveDocument(documentId: string) {
  await reviewDocument(documentId, 'approved');
}

export async function rejectDocument(documentId: string) {
  await reviewDocument(documentId, 'rejected');
}
