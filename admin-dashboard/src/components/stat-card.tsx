import type { ReactNode } from 'react';

export function StatCard({
  label,
  value,
  icon,
  trend,
}: {
  label: string;
  value: string | number;
  icon?: ReactNode;
  trend?: string;
}) {
  return (
    <div className="flex items-center gap-4 rounded-2xl border border-neutral-700 bg-neutral-900 p-4 shadow-[0_4px_12px_rgba(0,0,0,0.02)] transition hover:shadow-md">
      <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-neutral-800 text-blue-600 shadow-sm">
        {icon || (
          <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
          </svg>
        )}
      </div>
      <div>
        <p className="text-xs font-bold text-neutral-500 uppercase tracking-wider">{label}</p>
        <div className="flex items-baseline gap-2 mt-0.5">
          <p className="text-xl font-extrabold text-neutral-300">{value}</p>
          {trend && (
            <span className="text-[10px] font-bold text-green-500">{trend}</span>
          )}
        </div>
      </div>
    </div>
  );
}
