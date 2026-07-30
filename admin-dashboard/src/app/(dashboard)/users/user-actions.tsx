'use client';

import { useTransition } from 'react';
import { updateUserRole, setUserBanned } from './actions';
import type { AccountRole, UserRow } from '@/lib/types';

const ROLES: AccountRole[] = ['athlete', 'recruiter', 'club', 'coach', 'admin'];

export function UserActions({ user }: { user: UserRow }) {
  const [isPending, startTransition] = useTransition();

  return (
    <div className="flex items-center gap-2">
      <select
        defaultValue={user.role}
        disabled={isPending}
        onChange={(e) =>
          startTransition(() => updateUserRole(user.id, e.target.value as AccountRole))
        }
        className="rounded-md border border-neutral-700 bg-neutral-900 px-2 py-1 text-xs text-neutral-300 outline-none disabled:opacity-50"
      >
        {ROLES.map((role) => (
          <option key={role} value={role}>
            {role}
          </option>
        ))}
      </select>

      <button
        type="button"
        disabled={isPending}
        onClick={() => startTransition(() => setUserBanned(user.id, !user.is_banned))}
        className={`rounded-md px-2 py-1 text-xs font-medium transition disabled:opacity-50 ${
          user.is_banned
            ? 'bg-green-100 text-green-700 hover:bg-green-200'
            : 'bg-red-100 text-red-700 hover:bg-red-200'
        }`}
      >
        {user.is_banned ? 'Unban' : 'Ban'}
      </button>
    </div>
  );
}
