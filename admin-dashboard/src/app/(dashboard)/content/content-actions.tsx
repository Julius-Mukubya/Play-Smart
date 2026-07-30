'use client';

import { useTransition } from 'react';
import { setContentFlagged, deleteContent } from './actions';
import type { AthleteContentRow } from '@/lib/types';

export function ContentActions({ content }: { content: AthleteContentRow }) {
  const [isPending, startTransition] = useTransition();

  return (
    <div className="flex items-center gap-2">
      <button
        type="button"
        disabled={isPending}
        onClick={() => startTransition(() => setContentFlagged(content.id, !content.flagged))}
        className={`rounded-md px-2 py-1 text-xs font-medium transition disabled:opacity-50 ${
          content.flagged
            ? 'bg-neutral-200 text-neutral-800 hover:bg-neutral-300'
            : 'bg-yellow-100 text-yellow-800 hover:bg-yellow-200'
        }`}
      >
        {content.flagged ? 'Unflag' : 'Flag'}
      </button>

      <button
        type="button"
        disabled={isPending}
        onClick={() => {
          if (!window.confirm(`Delete "${content.title}"? This cannot be undone.`)) return;
          startTransition(() => deleteContent(content.id));
        }}
        className="rounded-md bg-red-100 px-2 py-1 text-xs font-medium text-red-700 transition hover:bg-red-200 disabled:opacity-50"
      >
        Delete
      </button>
    </div>
  );
}
