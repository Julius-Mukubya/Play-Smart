// Edge Function: send-push-notification
//
// Triggered by a Database Webhook on `public.notifications` INSERT (see
// supabase/migrations/0002_push_notification_tokens.sql for the dashboard
// wiring step — that part isn't expressible in SQL/migrations).
//
// Looks up every device token registered for the notification's `user_id`
// and sends a push via the FCM HTTP v1 API (OAuth2 service-account auth,
// not the deprecated legacy server-key API).
//
// Required secrets (Project Settings -> Edge Functions -> Secrets):
//   SUPABASE_URL                 (auto-provided)
//   SUPABASE_SERVICE_ROLE_KEY    (auto-provided)
//   FCM_PROJECT_ID               Firebase project id
//   FCM_SERVICE_ACCOUNT_JSON     Full service account JSON (as a single-line string)

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface NotificationRow {
  id: string;
  user_id: string;
  type: string;
  title: string;
  body: string;
  related_id: string | null;
}

interface WebhookPayload {
  type: 'INSERT';
  table: string;
  record: NotificationRow;
}

const supabaseAdmin = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

// --- Google OAuth2 (service account, RS256 JWT) -----------------------------

let cachedAccessToken: { token: string; expiresAt: number } | null = null;

async function getAccessToken(): Promise<string> {
  if (cachedAccessToken && cachedAccessToken.expiresAt > Date.now() + 60_000) {
    return cachedAccessToken.token;
  }

  const serviceAccount = JSON.parse(Deno.env.get('FCM_SERVICE_ACCOUNT_JSON')!);
  const now = Math.floor(Date.now() / 1000);

  const header = { alg: 'RS256', typ: 'JWT' };
  const claims = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };

  const encode = (obj: unknown) =>
    btoa(JSON.stringify(obj)).replace(/=+$/, '').replace(/\+/g, '-').replace(/\//g, '_');

  const unsigned = `${encode(header)}.${encode(claims)}`;
  const key = await importPrivateKey(serviceAccount.private_key);
  const signature = await crypto.subtle.sign(
    { name: 'RSASSA-PKCS1-v1_5' },
    key,
    new TextEncoder().encode(unsigned),
  );
  const encodedSignature = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=+$/, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');

  const jwt = `${unsigned}.${encodedSignature}`;

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  if (!response.ok) {
    throw new Error(`Failed to exchange service account JWT: ${await response.text()}`);
  }

  const data = await response.json();
  cachedAccessToken = { token: data.access_token, expiresAt: now * 1000 + data.expires_in * 1000 };
  return data.access_token;
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const pemContents = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s+/g, '');
  const binaryDer = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey(
    'pkcs8',
    binaryDer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
}

// --- FCM send -----------------------------------------------------------

async function sendToToken(accessToken: string, token: string, notification: NotificationRow) {
  const projectId = Deno.env.get('FCM_PROJECT_ID')!;
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title: notification.title, body: notification.body },
          data: {
            type: notification.type,
            related_id: notification.related_id ?? '',
            notification_id: notification.id,
          },
        },
      }),
    },
  );

  if (!response.ok) {
    const errorBody = await response.text();
    // NOT_FOUND / UNREGISTERED means the token is stale — clean it up so we
    // stop trying to deliver to a device that no longer has the app.
    if (errorBody.includes('UNREGISTERED') || errorBody.includes('NOT_FOUND')) {
      await supabaseAdmin.from('device_tokens').delete().eq('token', token);
    }
    console.error(`FCM send failed for token ${token}: ${errorBody}`);
  }
}

Deno.serve(async (req) => {
  try {
    const payload: WebhookPayload = await req.json();
    const notification = payload.record;

    const { data: tokens, error } = await supabaseAdmin
      .from('device_tokens')
      .select('token')
      .eq('user_id', notification.user_id);

    if (error) throw error;
    if (!tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ sent: 0 }), { status: 200 });
    }

    const accessToken = await getAccessToken();
    await Promise.all(tokens.map((t) => sendToToken(accessToken, t.token, notification)));

    return new Response(JSON.stringify({ sent: tokens.length }), { status: 200 });
  } catch (e) {
    console.error(e);
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});
