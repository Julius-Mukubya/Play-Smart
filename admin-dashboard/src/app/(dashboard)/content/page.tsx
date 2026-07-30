import { createAdminClient } from '@/lib/supabase/admin';
import { Badge } from '@/components/badge';
import { ContentActions } from './content-actions';
import { StatCard } from '@/components/stat-card';
import type { AthleteContentRow } from '@/lib/types';

export default async function ContentPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; flagged?: string }>;
}) {
  const { q = '', flagged } = await searchParams;
  const safeQ = q.replace(/[,()]/g, '').trim();
  const flaggedOnly = flagged === '1';

  const admin = createAdminClient();

  const [
    { count: totalCount },
    { count: flaggedCount },
    { data: contentData, error }
  ] = await Promise.all([
    admin.from('athlete_content').select('*', { count: 'exact', head: true }),
    admin.from('athlete_content').select('*', { count: 'exact', head: true }).eq('flagged', true),
    admin
      .from('athlete_content')
      .select('id, athlete_id, type, title, description, file_url, thumbnail_url, flagged, like_count, comment_count, created_at, athletes(display_name, user_id)')
      .ilike('title', safeQ ? `%${safeQ}%` : '%%')
      .eq(flaggedOnly ? 'flagged' : 'flagged', flaggedOnly ? true : false || true)
      .order('created_at', { ascending: false })
      .limit(200),
  ]);

  const items = (contentData ?? []) as unknown as AthleteContentRow[];
  const cleanCount = Number(totalCount) - Number(flaggedCount);

  return (
    <div className="flex flex-col gap-6">
      {/* Stat Cards Grid */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <StatCard label="Total Content" value={totalCount ?? 0} />
        <StatCard label="Flagged Content" value={flaggedCount ?? 0} />
        <StatCard label="Approved Content" value={cleanCount} />
      </div>

      <div>
        <h1 className="text-xl font-bold text-neutral-300">Content</h1>
        <p className="mt-1 text-sm text-neutral-400">
          {items.length} item{items.length === 1 ? '' : 's'}
          {flaggedOnly ? ' (flagged only)' : ''}
          {safeQ ? ` matching "${safeQ}"` : ''}.
        </p>

        <form method="get" className="mt-4 flex flex-wrap items-center gap-3">
          <input
            type="text"
            name="q"
            defaultValue={q}
            placeholder="Search by title…"
            className="w-full max-w-sm rounded-md border border-neutral-700 bg-neutral-900 px-3 py-2 text-sm text-neutral-300 outline-none focus:border-blue-500"
          />
          <label className="flex items-center gap-2 text-sm text-neutral-400">
            <input type="checkbox" name="flagged" value="1" defaultChecked={flaggedOnly} />
            Flagged only
          </label>
          <button
            type="submit"
            className="rounded-md bg-neutral-800 px-3 py-2 text-sm text-white hover:bg-neutral-700"
          >
            Apply
          </button>
        </form>

        {error && <p className="mt-4 text-sm text-red-400">Error loading content: {error.message}</p>}

        <div className="mt-4 overflow-x-auto rounded-xl border border-neutral-700">
          <table className="w-full text-left text-sm">
            <thead className="bg-neutral-800 text-neutral-400">
              <tr>
                <th className="px-4 py-3 font-medium">Title</th>
                <th className="px-4 py-3 font-medium">Athlete</th>
                <th className="px-4 py-3 font-medium">Type</th>
                <th className="px-4 py-3 font-medium">Status</th>
                <th className="px-4 py-3 font-medium">Uploaded</th>
                <th className="px-4 py-3 font-medium">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-700">
              {items.map((item) => (
                <tr key={item.id}>
                  <td className="max-w-xs truncate px-4 py-3 text-neutral-300">{item.title}</td>
                  <td className="px-4 py-3 text-neutral-400">
                    {item.athletes?.display_name ?? '—'}
                  </td>
                  <td className="px-4 py-3 text-neutral-400">{item.type}</td>
                  <td className="px-4 py-3">
                    {item.flagged ? (
                      <Badge tone="red">Flagged</Badge>
                    ) : (
                      <Badge tone="neutral">OK</Badge>
                    )}
                  </td>
                  <td className="px-4 py-3 text-neutral-500">
                    {new Date(item.created_at).toLocaleDateString()}
                  </td>
                  <td className="px-4 py-3">
                    <ContentActions content={item} />
                  </td>
                </tr>
              ))}
              {items.length === 0 && !error && (
                <tr>
                  <td colSpan={6} className="px-4 py-8 text-center text-neutral-500">
                    No content found.
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
