'use client';

import { useTransition } from 'react';
import { deleteSubscriptionPlan } from './actions';
import type { SubscriptionTier } from '@/lib/types';

export function PlanActions({ tier }: { tier: SubscriptionTier }) {
  const [isPending, startTransition] = useTransition();

  return (
    <button
      type="button"
      disabled={isPending}
      onClick={() => {
        if (!window.confirm(`Delete plan for tier "${tier}"?`)) return;
        startTransition(() => deleteSubscriptionPlan(tier));
      }}
      className="rounded-md bg-red-100 px-2 py-1 text-xs font-medium text-red-700 transition hover:bg-red-200 disabled:opacity-50"
    >
      Delete
    </button>
  );
}
