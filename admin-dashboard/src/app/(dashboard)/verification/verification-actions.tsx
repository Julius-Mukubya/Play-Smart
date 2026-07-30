'use client';

import { useTransition } from 'react';
import { approveDocument, rejectDocument } from './actions';

export function VerificationActions({ documentId }: { documentId: string }) {
  const [isPending, startTransition] = useTransition();

  return (
    <div className="flex items-center gap-2">
      <button
        type="button"
        disabled={isPending}
        onClick={() => startTransition(() => approveDocument(documentId))}
        className="rounded-md bg-green-100 px-3 py-1 text-xs font-medium text-green-700 transition hover:bg-green-200 disabled:opacity-50"
      >
        Approve
      </button>
      <button
        type="button"
        disabled={isPending}
        onClick={() => startTransition(() => rejectDocument(documentId))}
        className="rounded-md bg-red-100 px-3 py-1 text-xs font-medium text-red-700 transition hover:bg-red-200 disabled:opacity-50"
      >
        Reject
      </button>
    </div>
  );
}
