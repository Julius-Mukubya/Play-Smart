import { createAdminClient } from '@/lib/supabase/admin';
import { Badge } from '@/components/badge';
import { UserActions } from './user-actions';
import { StatCard } from '@/components/stat-card';
import type { UserRow, VerificationStatus } from '@/lib/types';

const VERIFICATION_TONE: Record<VerificationStatus, 'green' | 'yellow' | 'red'> = {
  approved: 'green',
  pending: 'yellow',
  rejected: 'red',
};

export default async function UsersPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string }>;
}) {
  const { q = '' } = await searchParams;
  // .or() takes a raw PostgREST filter string — strip characters that would
  // break the filter DSL. Not a security boundary (this client already has
  // full read access via the service role), just avoids a malformed-query 400.
  const safeQ = q.replace(/[,()]/g, '').trim();

  const admin = createAdminClient();

  const [
    { count: totalCount },
    { count: athleteCount },
    { count: recruiterCount },
    { count: clubCount },
    { count: bannedCount },
    { data: usersData, error }
  ] = await Promise.all([
    admin.from('users').select('*', { count: 'exact', head: true }),
    admin.from('users').select('*', { count: 'exact', head: true }).eq('role', 'athlete'),
    admin.from('users').select('*', { count: 'exact', head: true }).eq('role', 'recruiter'),
    admin.from('users').select('*', { count: 'exact', head: true }).eq('role', 'club'),
    admin.from('users').select('*', { count: 'exact', head: true }).eq('is_banned', true),
    admin
      .from('users')
      .select('id, name, email, role, verification_status, subscription_tier, is_banned, created_at')
      .or(safeQ ? `name.ilike.%${safeQ}%,email.ilike.%${safeQ}%` : 'id.not.is.null')
      .order('created_at', { ascending: false })
      .limit(200),
  ]);

  const users = (usersData ?? []) as UserRow[];

  return (
    <div className="flex flex-col gap-6">
      {/* Stat Cards Grid */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-5">
        <StatCard label="Total Users" value={totalCount ?? 0} />
        <StatCard label="Athletes" value={athleteCount ?? 0} />
        <StatCard label="Recruiters" value={recruiterCount ?? 0} />
        <StatCard label="Clubs" value={clubCount ?? 0} />
        <StatCard label="Banned" value={bannedCount ?? 0} />
      </div>

      <div>
        <h1 className="text-xl font-bold text-neutral-300">Users</h1>
        <p className="mt-1 text-sm text-neutral-400">
          {users.length} user{users.length === 1 ? '' : 's'}
          {safeQ ? ` matching "${safeQ}"` : ''}.
        </p>

      <form method="get" className="mt-4">
        <input
          type="text"
          name="q"
          defaultValue={q}
          placeholder="Search by name or email…"
          className="w-full max-w-sm rounded-md border border-neutral-700 bg-neutral-900 px-3 py-2 text-sm text-neutral-300 outline-none focus:border-blue-500"
        />
      </form>

      {error && <p className="mt-4 text-sm text-red-400">Error loading users: {error.message}</p>}

      <div className="mt-4 overflow-x-auto rounded-xl border border-neutral-700">
        <table className="w-full text-left text-sm">
          <thead className="bg-neutral-800 text-neutral-400">
            <tr>
              <th className="px-4 py-3 font-medium">Name</th>
              <th className="px-4 py-3 font-medium">Email</th>
              <th className="px-4 py-3 font-medium">Verification</th>
              <th className="px-4 py-3 font-medium">Plan</th>
              <th className="px-4 py-3 font-medium">Status</th>
              <th className="px-4 py-3 font-medium">Joined</th>
              <th className="px-4 py-3 font-medium">Role & moderation</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-neutral-700">
            {users.map((user) => (
              <tr key={user.id}>
                <td className="px-4 py-3 text-neutral-300">{user.name}</td>
                <td className="px-4 py-3 text-neutral-400">{user.email}</td>
                <td className="px-4 py-3">
                  <Badge tone={VERIFICATION_TONE[user.verification_status]}>
                    {user.verification_status}
                  </Badge>
                </td>
                <td className="px-4 py-3 text-neutral-400">{user.subscription_tier}</td>
                <td className="px-4 py-3">
                  {user.is_banned ? (
                    <Badge tone="red">Banned</Badge>
                  ) : (
                    <Badge tone="green">Active</Badge>
                  )}
                </td>
                <td className="px-4 py-3 text-neutral-500">
                  {new Date(user.created_at).toLocaleDateString()}
                </td>
                <td className="px-4 py-3">
                  <UserActions user={user} />
                </td>
              </tr>
            ))}
            {users.length === 0 && !error && (
              <tr>
                <td colSpan={7} className="px-4 py-8 text-center text-neutral-500">
                  No users found.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
      </div>
    </div>
  );
}
