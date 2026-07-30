'use server';

import { revalidatePath } from 'next/cache';
import { requireAdmin } from '@/lib/auth';
import { createAdminClient } from '@/lib/supabase/admin';
import type { SubscriptionTier } from '@/lib/types';

export async function createSubscriptionPlan(formData: FormData) {
  await requireAdmin();

  const tier = formData.get('tier') as SubscriptionTier;
  const name = formData.get('name') as string;
  const priceUgx = Number(formData.get('price_ugx'));
  const featuresInput = formData.get('features') as string;
  const isPopular = formData.get('is_popular') === 'on';

  if (!tier || !name || isNaN(priceUgx)) {
    throw new Error('Missing or invalid fields.');
  }

  const features = featuresInput
    ? featuresInput
        .split(',')
        .map((f) => f.trim())
        .filter(Boolean)
    : [];

  const admin = createAdminClient();
  const { error } = await admin.from('subscription_plans').insert({
    tier,
    name,
    price_ugx: priceUgx,
    features,
    is_popular: isPopular,
  });

  if (error) {
    throw new Error(error.message);
  }

  revalidatePath('/subscriptions');
}

export async function deleteSubscriptionPlan(tier: SubscriptionTier) {
  await requireAdmin();

  const admin = createAdminClient();
  const { error } = await admin.from('subscription_plans').delete().eq('tier', tier);

  if (error) {
    throw new Error(error.message);
  }

  revalidatePath('/subscriptions');
}
