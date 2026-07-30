import { createAdminClient } from '@/lib/supabase/admin';
import { StatCard } from '@/components/stat-card';
import { Badge } from '@/components/badge';

export default async function OverviewPage() {
  const admin = createAdminClient();

  const [
    { count: totalUsers },
    { count: athleteCount },
    { count: recruiterCount },
    { count: clubCount },
    { count: bannedCount },
    { count: totalContent },
    { count: flaggedContent },
    { count: pendingVerification },
    { data: revenueRows },
    { data: recentUsers },
  ] = await Promise.all([
    admin.from('users').select('*', { count: 'exact', head: true }),
    admin.from('users').select('*', { count: 'exact', head: true }).eq('role', 'athlete'),
    admin.from('users').select('*', { count: 'exact', head: true }).eq('role', 'recruiter'),
    admin.from('users').select('*', { count: 'exact', head: true }).eq('role', 'club'),
    admin.from('users').select('*', { count: 'exact', head: true }).eq('is_banned', true),
    admin.from('athlete_content').select('*', { count: 'exact', head: true }),
    admin.from('athlete_content').select('*', { count: 'exact', head: true }).eq('flagged', true),
    admin.from('verification_documents').select('*', { count: 'exact', head: true }).eq('status', 'pending'),
    admin.from('payment_transactions').select('amount_ugx').eq('status', 'success'),
    admin.from('users').select('name, email, role, created_at').order('created_at', { ascending: false }).limit(5),
  ]);

  const totalRevenue = (revenueRows ?? []).reduce((sum, r) => sum + Number(r.amount_ugx), 0);

  // Compute percentages for Pie Chart
  const athletesPct = totalUsers ? Math.round((Number(athleteCount) / totalUsers) * 100) : 0;
  const recruitersPct = totalUsers ? Math.round((Number(recruiterCount) / totalUsers) * 100) : 0;
  const clubsPct = totalUsers ? Math.round((Number(clubCount) / totalUsers) * 100) : 0;

  return (
    <div className="flex flex-col gap-6">
      {/* Stat Cards Grid */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          label="Total Revenue"
          value={`UGX ${totalRevenue.toLocaleString()}`}
          trend="+4.8%"
          icon={
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          }
        />
        <StatCard
          label="Platform Users"
          value={totalUsers ?? 0}
          trend="+12%"
          icon={
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
            </svg>
          }
        />
        <StatCard
          label="Flagged Content"
          value={flaggedContent ?? 0}
          icon={
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
          }
        />
        <StatCard
          label="Pending Documents"
          value={pendingVerification ?? 0}
          icon={
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
            </svg>
          }
        />
      </div>

      {/* Charts / Mid Section */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        {/* Spend / Earnings Wavy Line Chart Card */}
        <div className="lg:col-span-2 rounded-2xl border border-neutral-700 bg-neutral-900 p-6 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-bold text-neutral-500 uppercase tracking-wider">Revenue Analytics</p>
              <h3 className="text-2xl font-bold text-neutral-300 mt-1">UGX {totalRevenue.toLocaleString()}</h3>
            </div>
            <span className="rounded-lg bg-green-100 px-2.5 py-1 text-xs font-bold text-green-700 flex items-center gap-1">
              <svg className="h-3.5 w-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 10l7-7 7 7M12 3v18" />
              </svg>
              On Track
            </span>
          </div>

          <div className="mt-6 h-56 w-full">
            <svg viewBox="0 0 500 200" className="w-full h-full overflow-visible">
              {/* Grid Lines */}
              <line x1="0" y1="50" x2="500" y2="50" stroke="#E9EDF7" strokeWidth="1" strokeDasharray="5,5" />
              <line x1="0" y1="100" x2="500" y2="100" stroke="#E9EDF7" strokeWidth="1" strokeDasharray="5,5" />
              <line x1="0" y1="150" x2="500" y2="150" stroke="#E9EDF7" strokeWidth="1" strokeDasharray="5,5" />
              
              {/* Gradient defs */}
              <defs>
                <linearGradient id="blueGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#4318FF" stopOpacity="0.25" />
                  <stop offset="100%" stopColor="#4318FF" stopOpacity="0.0" />
                </linearGradient>
                <linearGradient id="cyanGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#00F2FE" stopOpacity="0.2" />
                  <stop offset="100%" stopColor="#00F2FE" stopOpacity="0.0" />
                </linearGradient>
              </defs>

              {/* Cyan Line & Area */}
              <path
                d="M 0 170 C 80 150, 120 180, 200 130 C 280 80, 320 160, 400 110 C 450 80, 480 100, 500 90 L 500 200 L 0 200 Z"
                fill="url(#cyanGradient)"
              />
              <path
                d="M 0 170 C 80 150, 120 180, 200 130 C 280 80, 320 160, 400 110 C 450 80, 480 100, 500 90"
                fill="none"
                stroke="#00F2FE"
                strokeWidth="3.5"
              />

              {/* Indigo Line & Area */}
              <path
                d="M 0 140 C 80 120, 120 160, 200 100 C 280 40, 320 130, 400 80 C 450 50, 480 80, 500 70 L 500 200 L 0 200 Z"
                fill="url(#blueGradient)"
              />
              <path
                d="M 0 140 C 80 120, 120 160, 200 100 C 280 40, 320 130, 400 80 C 450 50, 480 80, 500 70"
                fill="none"
                stroke="#4318FF"
                strokeWidth="4"
              />

              {/* Highlighting dot */}
              <circle cx="200" cy="100" r="5" fill="#4318FF" stroke="#FFFFFF" strokeWidth="2.5" />
              <rect x="175" y="65" width="50" height="20" rx="6" fill="#1B254B" />
              <text x="200" y="78" fill="#FFFFFF" fontSize="9" fontWeight="bold" textAnchor="middle">UGX 15M</text>

              {/* Labels */}
              <text x="10" y="195" fill="#A3AED0" fontSize="9">SEP</text>
              <text x="110" y="195" fill="#A3AED0" fontSize="9">OCT</text>
              <text x="210" y="195" fill="#A3AED0" fontSize="9">NOV</text>
              <text x="310" y="195" fill="#A3AED0" fontSize="9">DEC</text>
              <text x="410" y="195" fill="#A3AED0" fontSize="9">JAN</text>
            </svg>
          </div>
        </div>

        {/* Roles Distribution Pie Chart */}
        <div className="rounded-2xl border border-neutral-700 bg-neutral-900 p-6 shadow-sm flex flex-col justify-between">
          <div>
            <p className="text-xs font-bold text-neutral-500 uppercase tracking-wider">User Breakdown</p>
            <h4 className="text-lg font-extrabold text-neutral-300 mt-1">Role Distribution</h4>
          </div>

          <div className="flex justify-center items-center my-6 h-40">
            <svg viewBox="0 0 36 36" className="w-36 h-36">
              {/* Circular Background */}
              <circle cx="18" cy="18" r="15.915" fill="none" stroke="#E9EDF7" strokeWidth="3" />
              
              {/* Athletes Pct Slice (Indigo Blue) */}
              <circle
                cx="18"
                cy="18"
                r="15.915"
                fill="none"
                stroke="#4318FF"
                strokeWidth="3.5"
                strokeDasharray={`${athletesPct} ${100 - athletesPct}`}
                strokeDashoffset="25"
              />

              {/* Recruiters Pct Slice (Cyan) */}
              <circle
                cx="18"
                cy="18"
                r="15.915"
                fill="none"
                stroke="#00F2FE"
                strokeWidth="3.5"
                strokeDasharray={`${recruitersPct} ${100 - recruitersPct}`}
                strokeDashoffset={25 - athletesPct}
              />
            </svg>
          </div>

          <div className="grid grid-cols-3 gap-2 border-t border-neutral-700 pt-4">
            <div className="text-center">
              <span className="inline-block h-2 w-2 rounded-full bg-blue-600 mr-1.5" />
              <span className="text-[10px] text-neutral-500 font-bold uppercase">Athletes</span>
              <p className="text-sm font-bold text-neutral-300 mt-0.5">{athletesPct}%</p>
            </div>
            <div className="text-center border-l border-neutral-700">
              <span className="inline-block h-2 w-2 rounded-full bg-cyan-400 mr-1.5" />
              <span className="text-[10px] text-neutral-500 font-bold uppercase">Recruiters</span>
              <p className="text-sm font-bold text-neutral-300 mt-0.5">{recruitersPct}%</p>
            </div>
            <div className="text-center border-l border-neutral-700">
              <span className="inline-block h-2 w-2 rounded-full bg-neutral-300 mr-1.5" />
              <span className="text-[10px] text-neutral-500 font-bold uppercase">Clubs</span>
              <p className="text-sm font-bold text-neutral-300 mt-0.5">{clubsPct}%</p>
            </div>
          </div>
        </div>
      </div>

      {/* Bottom Section - Check Table */}
      <div className="rounded-2xl border border-neutral-700 bg-neutral-900 p-6 shadow-sm">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h3 className="text-md font-bold text-neutral-300">Recently Joined Users</h3>
            <p className="text-xs text-neutral-500">Overview of the last 5 registered accounts</p>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="text-[10px] text-neutral-500 uppercase font-bold border-b border-neutral-700 pb-3">
              <tr>
                <th className="pb-3 pr-4">Name</th>
                <th className="pb-3 pr-4">Email</th>
                <th className="pb-3 pr-4">Role</th>
                <th className="pb-3">Registered</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-700">
              {(recentUsers ?? []).map((user, idx) => (
                <tr key={idx} className="hover:bg-neutral-850 transition">
                  <td className="py-3 font-semibold text-neutral-300 pr-4">{user.name}</td>
                  <td className="py-3 text-neutral-500 pr-4">{user.email}</td>
                  <td className="py-3 pr-4">
                    <Badge tone={user.role === 'athlete' ? 'blue' : user.role === 'recruiter' ? 'green' : 'yellow'}>
                      {user.role}
                    </Badge>
                  </td>
                  <td className="py-3 text-neutral-500">
                    {new Date(user.created_at).toLocaleDateString()}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
