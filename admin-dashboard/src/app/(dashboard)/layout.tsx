import type { ReactNode } from 'react';
import { requireAdmin } from '@/lib/auth';
import { NavLink } from './nav-link';
import { TopBar } from '@/components/top-bar';

const NAV_ITEMS = [
  { href: '/', label: 'Overview' },
  { href: '/users', label: 'Users' },
  { href: '/content', label: 'Content' },
  { href: '/verification', label: 'Verification' },
  { href: '/subscriptions', label: 'Subscriptions' },
];

export default async function DashboardLayout({ children }: { children: ReactNode }) {
  const admin = await requireAdmin();

  return (
    <div className="flex min-h-screen bg-neutral-950 text-neutral-300">
      {/* Sidebar */}
      <aside className="flex w-64 shrink-0 flex-col border-r border-neutral-700 bg-neutral-900 py-6">
        {/* Brand Logo */}
        <div className="mb-8 px-6">
          <h1 className="text-xl font-bold tracking-tight text-neutral-300">PLAY SMART</h1>
          <p className="text-[10px] uppercase font-bold tracking-widest text-neutral-500 mt-0.5">Admin dashboard</p>
        </div>

        {/* Navigation links */}
        <nav className="flex flex-col gap-0.5 pr-4">
          {NAV_ITEMS.map((item) => (
            <NavLink key={item.href} href={item.href}>
              {item.label}
            </NavLink>
          ))}
        </nav>
      </aside>

      {/* Main Content Area */}
      <div className="flex flex-1 flex-col overflow-y-auto min-h-screen">
        <main className="flex-1 p-8">
          <TopBar email={admin.email} />
          {children}
        </main>
      </div>
    </div>
  );
}
