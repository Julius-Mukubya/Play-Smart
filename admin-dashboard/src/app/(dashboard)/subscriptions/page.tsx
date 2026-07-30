import { createAdminClient } from '@/lib/supabase/admin';
import { Badge } from '@/components/badge';
import { PlanForm } from './plan-form';
import { PlanActions } from './plan-actions';
import type {
  PaymentTransactionRow,
  PaymentStatus,
  SubscriptionRow,
  SubscriptionStatus,
  SubscriptionPlanRow,
} from '@/lib/types';

const SUB_TONE: Record<SubscriptionStatus, 'green' | 'yellow' | 'red' | 'neutral'> = {
  active: 'green',
  grace_period: 'yellow',
  expired: 'red',
  cancelled: 'neutral',
};

const PAYMENT_TONE: Record<PaymentStatus, 'green' | 'yellow' | 'red' | 'neutral'> = {
  success: 'green',
  pending: 'yellow',
  failed: 'red',
  refunded: 'neutral',
};

export default async function SubscriptionsPage() {
  const admin = createAdminClient();

  const [
    { data: plansData, error: plansError },
    { data: subsData, error: subsError },
    { data: txData, error: txError }
  ] = await Promise.all([
    admin
      .from('subscription_plans')
      .select('*')
      .order('price_ugx', { ascending: true }),
    admin
      .from('subscriptions')
      .select('id, user_id, tier, status, current_period_start, current_period_end, provider, created_at, users(name, email)')
      .order('created_at', { ascending: false })
      .limit(100),
    admin
      .from('payment_transactions')
      .select('id, user_id, amount_ugx, provider, description, status, created_at, users(name, email)')
      .order('created_at', { ascending: false })
      .limit(100),
  ]);

  const plans = (plansData ?? []) as unknown as SubscriptionPlanRow[];
  const subs = (subsData ?? []) as unknown as SubscriptionRow[];
  const transactions = (txData ?? []) as unknown as PaymentTransactionRow[];

  return (
    <div>
      <h1 className="text-2xl font-semibold text-neutral-300">Subscriptions & Payments</h1>
      <p className="mt-1 text-sm text-neutral-400">Manage pricing tiers and review client activity.</p>

      {/* Subscription Plans Management */}
      <h2 className="mt-8 text-lg font-semibold text-neutral-300">Subscription Plans</h2>
      {plansError && (
        <p className="mt-2 text-sm text-red-400">Error loading plans: {plansError.message}</p>
      )}
      
      <div className="mt-3 overflow-x-auto rounded-xl border border-neutral-700">
        <table className="w-full text-left text-sm">
          <thead className="bg-neutral-800 text-neutral-400">
            <tr>
              <th className="px-4 py-3 font-medium">Tier</th>
              <th className="px-4 py-3 font-medium">Name</th>
              <th className="px-4 py-3 font-medium">Price (UGX)</th>
              <th className="px-4 py-3 font-medium">Features</th>
              <th className="px-4 py-3 font-medium">Popular</th>
              <th className="px-4 py-3 font-medium">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-neutral-700">
            {plans.map((plan) => (
              <tr key={plan.tier}>
                <td className="px-4 py-3 font-medium text-neutral-300">{plan.tier}</td>
                <td className="px-4 py-3 text-neutral-400">{plan.name}</td>
                <td className="px-4 py-3 text-neutral-400">UGX {plan.price_ugx.toLocaleString()}</td>
                <td className="px-4 py-3 text-neutral-500 max-w-xs truncate" title={plan.features.join(', ')}>
                  {plan.features.join(', ') || '—'}
                </td>
                <td className="px-4 py-3">
                  {plan.is_popular ? (
                    <Badge tone="blue">Popular</Badge>
                  ) : (
                    <span className="text-xs text-neutral-500">No</span>
                  )}
                </td>
                <td className="px-4 py-3">
                  <PlanActions tier={plan.tier} />
                </td>
              </tr>
            ))}
            {plans.length === 0 && !plansError && (
              <tr>
                <td colSpan={6} className="px-4 py-8 text-center text-neutral-500">
                  No subscription plans created yet. Add one below.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* Plan Creation Form */}
      <PlanForm />

      <h2 className="mt-8 text-lg font-semibold text-neutral-300">Active subscriptions</h2>
      {subsError && (
        <p className="mt-2 text-sm text-red-400">Error loading subscriptions: {subsError.message}</p>
      )}
      <div className="mt-3 overflow-x-auto rounded-xl border border-neutral-700">
        <table className="w-full text-left text-sm">
          <thead className="bg-neutral-800 text-neutral-400">
            <tr>
              <th className="px-4 py-3 font-medium">User</th>
              <th className="px-4 py-3 font-medium">Tier</th>
              <th className="px-4 py-3 font-medium">Status</th>
              <th className="px-4 py-3 font-medium">Provider</th>
              <th className="px-4 py-3 font-medium">Period ends</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-neutral-700">
            {subs.map((sub) => (
              <tr key={sub.id}>
                <td className="px-4 py-3 text-neutral-300">
                  {sub.users?.name ?? '—'}
                  <div className="text-xs text-neutral-500">{sub.users?.email}</div>
                </td>
                <td className="px-4 py-3 text-neutral-400">{sub.tier}</td>
                <td className="px-4 py-3">
                  <Badge tone={SUB_TONE[sub.status]}>{sub.status}</Badge>
                </td>
                <td className="px-4 py-3 text-neutral-400">{sub.provider ?? '—'}</td>
                <td className="px-4 py-3 text-neutral-500">
                  {sub.current_period_end
                    ? new Date(sub.current_period_end).toLocaleDateString()
                    : '—'}
                </td>
              </tr>
            ))}
            {subs.length === 0 && !subsError && (
              <tr>
                <td colSpan={5} className="px-4 py-8 text-center text-neutral-500">
                  No subscriptions yet.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      <h2 className="mt-8 text-lg font-semibold text-neutral-300">Recent transactions</h2>
      {txError && (
        <p className="mt-2 text-sm text-red-400">Error loading transactions: {txError.message}</p>
      )}
      <div className="mt-3 overflow-x-auto rounded-xl border border-neutral-700">
        <table className="w-full text-left text-sm">
          <thead className="bg-neutral-800 text-neutral-400">
            <tr>
              <th className="px-4 py-3 font-medium">User</th>
              <th className="px-4 py-3 font-medium">Amount</th>
              <th className="px-4 py-3 font-medium">Provider</th>
              <th className="px-4 py-3 font-medium">Status</th>
              <th className="px-4 py-3 font-medium">Date</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-neutral-700">
            {transactions.map((tx) => (
              <tr key={tx.id}>
                <td className="px-4 py-3 text-neutral-300">
                  {tx.users?.name ?? '—'}
                  <div className="text-xs text-neutral-500">{tx.description}</div>
                </td>
                <td className="px-4 py-3 text-neutral-400">
                  UGX {Number(tx.amount_ugx).toLocaleString()}
                </td>
                <td className="px-4 py-3 text-neutral-400">{tx.provider}</td>
                <td className="px-4 py-3">
                  <Badge tone={PAYMENT_TONE[tx.status]}>{tx.status}</Badge>
                </td>
                <td className="px-4 py-3 text-neutral-500">
                  {new Date(tx.created_at).toLocaleDateString()}
                </td>
              </tr>
            ))}
            {transactions.length === 0 && !txError && (
              <tr>
                <td colSpan={5} className="px-4 py-8 text-center text-neutral-500">
                  No transactions yet.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
