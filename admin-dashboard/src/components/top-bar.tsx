'use client';

import { usePathname } from 'next/navigation';
import { signOutAction } from '@/app/(dashboard)/actions';

const ROUTE_MAP: Record<string, { category: string; title: string }> = {
  '/': { category: 'Pages / Dashboard', title: 'Main Dashboard' },
  '/users': { category: 'Pages / Users', title: 'User Management' },
  '/content': { category: 'Pages / Content', title: 'Content Moderation' },
  '/verification': { category: 'Pages / Verification', title: 'Credential Verifications' },
  '/subscriptions': { category: 'Pages / Subscriptions', title: 'Subscriptions & Payments' },
};

export function TopBar({ email }: { email: string }) {
  const pathname = usePathname();
  const info = ROUTE_MAP[pathname] || { category: 'Pages / Dashboard', title: 'Play Smart Admin' };

  return (
    <header className="mb-6 flex flex-col justify-between gap-4 md:flex-row md:items-center">
      <div>
        <p className="text-xs font-semibold text-neutral-500">{info.category}</p>
        <h2 className="text-2xl font-bold text-neutral-300 mt-0.5">{info.title}</h2>
      </div>

      <div className="flex items-center gap-3 rounded-full bg-neutral-900 border border-neutral-700 px-4 py-2.5 shadow-sm max-w-md w-full md:w-auto">
        <div className="flex items-center gap-2 border-r border-neutral-700 pr-3 flex-1 md:flex-initial">
          <svg
            className="h-4 w-4 text-neutral-500"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
            />
          </svg>
          <input
            type="text"
            placeholder="Search..."
            className="bg-transparent text-xs text-neutral-300 outline-none w-full md:w-32 placeholder:text-neutral-500"
          />
        </div>

        <button className="text-neutral-500 hover:text-neutral-300 transition">
          <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"
            />
          </svg>
        </button>

        <button className="text-neutral-500 hover:text-neutral-300 transition">
          <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"
            />
          </svg>
        </button>

        <button className="text-neutral-500 hover:text-neutral-300 transition">
          <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
        </button>

        <div className="relative group">
          <button className="flex h-7 w-7 items-center justify-center rounded-full bg-blue-600 font-bold text-xs text-white">
            {email.slice(0, 2).toUpperCase()}
          </button>
          
          <div className="absolute right-0 mt-2 hidden group-hover:block w-48 bg-neutral-900 border border-neutral-700 rounded-lg shadow-lg p-2 z-10">
            <p className="truncate text-xs text-neutral-500 px-2 py-1">{email}</p>
            <form action={signOutAction}>
              <button
                type="submit"
                className="w-full text-left rounded-md px-2 py-1.5 text-xs text-red-400 hover:bg-neutral-800 transition"
              >
                Sign out
              </button>
            </form>
          </div>
        </div>
      </div>
    </header>
  );
}
