'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import type { ReactNode } from 'react';

export function NavLink({ href, children }: { href: string; children: ReactNode }) {
  const pathname = usePathname();
  const active = href === '/' ? pathname === '/' : pathname.startsWith(href);

  return (
    <Link
      href={href}
      className={`relative flex items-center py-2.5 pl-6 font-medium transition ${
        active
          ? 'font-bold text-neutral-300'
          : 'text-neutral-500 hover:text-neutral-300'
      }`}
    >
      <span className="text-sm">{children}</span>
      {active && (
        <div className="absolute right-0 top-1/2 h-8 w-1 -translate-y-1/2 rounded-l-full bg-blue-600" />
      )}
    </Link>
  );
}
