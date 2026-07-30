import { createAdminClient } from '@/lib/supabase/admin';
import { Badge } from '@/components/badge';
import { VerificationActions } from './verification-actions';
import { StatCard } from '@/components/stat-card';
import type { VerificationDocumentRow, VerificationStatus } from '@/lib/types';

const STATUS_TONE: Record<VerificationStatus, 'green' | 'yellow' | 'red'> = {
  approved: 'green',
  pending: 'yellow',
  rejected: 'red',
};

export default async function VerificationPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string }>;
}) {
  const { status } = await searchParams;
  const filterStatus: VerificationStatus = (['pending', 'approved', 'rejected'] as const).includes(
    status as VerificationStatus,
  )
    ? (status as VerificationStatus)
    : 'pending';

  const admin = createAdminClient();

  const [
    { count: pendingCount },
    { count: approvedCount },
    { count: rejectedCount },
    { data, error }
  ] = await Promise.all([
    admin.from('verification_documents').select('*', { count: 'exact', head: true }).eq('status', 'pending'),
    admin.from('verification_documents').select('*', { count: 'exact', head: true }).eq('status', 'approved'),
    admin.from('verification_documents').select('*', { count: 'exact', head: true }).eq('status', 'rejected'),
    admin
      .from('verification_documents')
      .select('id, user_id, document_url, document_type, status, reviewed_by, reviewed_at, created_at, users!user_id(name, email, role)')
      .eq('status', filterStatus)
      .order('created_at', { ascending: true })
      .limit(200),
  ]);

  const docs = (data ?? []) as unknown as VerificationDocumentRow[];

  return (
    <div className="flex flex-col gap-6">
      {/* Stat Cards Grid */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <StatCard label="Pending" value={pendingCount ?? 0} />
        <StatCard label="Approved" value={approvedCount ?? 0} />
        <StatCard label="Rejected" value={rejectedCount ?? 0} />
      </div>

      <div>
        <h1 className="text-xl font-bold text-neutral-300">Verification</h1>
        <p className="mt-1 text-sm text-neutral-400">
          Recruiter/club credential submissions awaiting review.
        </p>

      <div className="mt-4 flex gap-2">
        {(['pending', 'approved', 'rejected'] as const).map((s) => (
          <a
            key={s}
            href={`/verification?status=${s}`}
            className={`rounded-md px-3 py-1.5 text-sm font-medium transition ${
              filterStatus === s
                ? 'bg-blue-600 text-white'
                : 'bg-neutral-900 text-neutral-400 hover:text-neutral-300'
            }`}
          >
            {s[0].toUpperCase() + s.slice(1)}
          </a>
        ))}
      </div>

      {error && (
        <p className="mt-4 text-sm text-red-400">Error loading submissions: {error.message}</p>
      )}

      <div className="mt-4 overflow-x-auto rounded-xl border border-neutral-700">
        <table className="w-full text-left text-sm">
          <thead className="bg-neutral-800 text-neutral-400">
            <tr>
              <th className="px-4 py-3 font-medium">Applicant</th>
              <th className="px-4 py-3 font-medium">Role</th>
              <th className="px-4 py-3 font-medium">Document</th>
              <th className="px-4 py-3 font-medium">Status</th>
              <th className="px-4 py-3 font-medium">Submitted</th>
              <th className="px-4 py-3 font-medium">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-neutral-700">
            {docs.map((doc) => (
              <tr key={doc.id}>
                <td className="px-4 py-3 text-neutral-300">
                  {doc.users?.name ?? '—'}
                  <div className="text-xs text-neutral-500">{doc.users?.email}</div>
                </td>
                <td className="px-4 py-3 text-neutral-400">{doc.users?.role ?? '—'}</td>
                <td className="px-4 py-3">
                  <a
                    href={doc.document_url}
                    target="_blank"
                    rel="noreferrer"
                    className="text-blue-600 hover:underline"
                  >
                    {doc.document_type}
                  </a>
                </td>
                <td className="px-4 py-3">
                  <Badge tone={STATUS_TONE[doc.status]}>{doc.status}</Badge>
                </td>
                <td className="px-4 py-3 text-neutral-500">
                  {new Date(doc.created_at).toLocaleDateString()}
                </td>
                <td className="px-4 py-3">
                  {doc.status === 'pending' ? (
                    <VerificationActions documentId={doc.id} />
                  ) : (
                    <span className="text-xs text-neutral-500">
                      Reviewed {doc.reviewed_at ? new Date(doc.reviewed_at).toLocaleDateString() : ''}
                    </span>
                  )}
                </td>
              </tr>
            ))}
            {docs.length === 0 && !error && (
              <tr>
                <td colSpan={6} className="px-4 py-8 text-center text-neutral-500">
                  No {filterStatus} submissions.
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
