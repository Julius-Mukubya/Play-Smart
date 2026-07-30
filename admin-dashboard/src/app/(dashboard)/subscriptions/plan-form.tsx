'use client';

import { useTransition, useState } from 'react';
import { createSubscriptionPlan } from './actions';
import type { SubscriptionTier } from '@/lib/types';

const TIERS: SubscriptionTier[] = [
  'free',
  'premium_monthly',
  'premium_annual',
  'recruiter_basic',
  'recruiter_pro',
  'club_grassroots',
  'club_professional',
  'club_enterprise',
];

export function PlanForm() {
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setError(null);
    const form = e.currentTarget;
    const formData = new FormData(form);

    startTransition(async () => {
      try {
        await createSubscriptionPlan(formData);
        form.reset();
      } catch (err: any) {
        setError(err.message || 'Failed to create plan.');
      }
    });
  };

  return (
    <form onSubmit={handleSubmit} className="mt-4 flex flex-col gap-4 max-w-lg rounded-xl border border-neutral-700 bg-neutral-900 p-6 shadow-sm">
      <h3 className="text-md font-semibold text-neutral-300">Add New Subscription Plan</h3>
      
      {error && (
        <p className="rounded-md bg-red-100 px-3 py-2 text-sm text-red-700">{error}</p>
      )}

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div className="flex flex-col gap-1">
          <label htmlFor="tier" className="text-xs font-medium text-neutral-400">
            Subscription Tier
          </label>
          <select
            id="tier"
            name="tier"
            required
            disabled={isPending}
            className="rounded-md border border-neutral-700 bg-neutral-900 px-3 py-2 text-sm text-neutral-300 outline-none focus:border-blue-500 disabled:opacity-50"
          >
            {TIERS.map((tier) => (
              <option key={tier} value={tier}>
                {tier}
              </option>
            ))}
          </select>
        </div>

        <div className="flex flex-col gap-1">
          <label htmlFor="name" className="text-xs font-medium text-neutral-400">
            Plan Name
          </label>
          <input
            id="name"
            name="name"
            type="text"
            required
            placeholder="e.g. Premium Monthly"
            disabled={isPending}
            className="rounded-md border border-neutral-700 bg-neutral-900 px-3 py-2 text-sm text-neutral-300 outline-none focus:border-blue-500 disabled:opacity-50"
          />
        </div>

        <div className="flex flex-col gap-1">
          <label htmlFor="price_ugx" className="text-xs font-medium text-neutral-400">
            Price (UGX)
          </label>
          <input
            id="price_ugx"
            name="price_ugx"
            type="number"
            required
            placeholder="e.g. 15000"
            disabled={isPending}
            className="rounded-md border border-neutral-700 bg-neutral-900 px-3 py-2 text-sm text-neutral-300 outline-none focus:border-blue-500 disabled:opacity-50"
          />
        </div>

        <div className="flex flex-col gap-1">
          <label htmlFor="features" className="text-xs font-medium text-neutral-400">
            Features (comma-separated)
          </label>
          <input
            id="features"
            name="features"
            type="text"
            placeholder="e.g. Unlimited Search, PDF Export"
            disabled={isPending}
            className="rounded-md border border-neutral-700 bg-neutral-900 px-3 py-2 text-sm text-neutral-300 outline-none focus:border-blue-500 disabled:opacity-50"
          />
        </div>
      </div>

      <div className="flex items-center gap-2">
        <input
          id="is_popular"
          name="is_popular"
          type="checkbox"
          disabled={isPending}
          className="rounded border-neutral-700 bg-neutral-900 focus:ring-blue-500"
        />
        <label htmlFor="is_popular" className="text-sm font-medium text-neutral-300">
          Mark as Popular
        </label>
      </div>

      <button
        type="submit"
        disabled={isPending}
        className="self-start rounded-md bg-blue-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-blue-700 disabled:opacity-50"
      >
        {isPending ? 'Adding plan...' : 'Add Plan'}
      </button>
    </form>
  );
}
