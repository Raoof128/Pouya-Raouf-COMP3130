/// Edge Function: notify
/// Replaces: /api/notifications dispatch logic for the Flutter client
/// Requires: SUPABASE_SERVICE_ROLE_KEY and either FIREBASE_SERVICE_ACCOUNT_JSON or FCM_SERVER_KEY
///
/// Stores a notification row and dispatches push notifications to the user's
/// registered FCM tokens without exposing push credentials to the mobile app.

import {
  createClient,
  type User,
} from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, handleCors } from "../_shared/cors.ts";

const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
const GOOGLE_OAUTH_TOKEN_URL = "https://oauth2.googleapis.com/token";
const LEGACY_FCM_URL = "https://fcm.googleapis.com/fcm/send";

type NotificationType =
  | "deadline"
  | "exam"
  | "event"
  | "announcement"
  | "system"
  | "study_prompt";

type ServiceAccount = {
  client_email: string;
  private_key: string;
  project_id: string;
  token_uri?: string;
};

type TokenRow = {
  token: string;
  platform: string | null;
};

function jsonResponse(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function requireEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    throw new Error(`${name} is not configured`);
  }
  return value;
}

function getAdminClient() {
  return createClient(
    requireEnv("SUPABASE_URL"),
    requireEnv("SUPABASE_SERVICE_ROLE_KEY"),
  );
}

async function requireUser(
  req: Request,
  supabase = getAdminClient(),
): Promise<User> {
  const authHeader = req.headers.get("authorization");
  const token = authHeader?.startsWith("Bearer ") ? authHeader.slice(7) : null;
  if (!token) {
    throw new Error("Unauthorized");
  }

  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data.user) {
    throw new Error("Unauthorized");
  }

  return data.user;
}

function isAdmin(user: User): boolean {
  return user.app_metadata?.role === "admin" ||
    user.user_metadata?.role === "admin";
}

function normalizeString(
  value: unknown,
  label: string,
  maxLength: number,
): string {
  if (typeof value !== "string") {
    throw new Error(`${label} is required`);
  }
  const normalized = value.trim();
  if (!normalized) {
    throw new Error(`${label} is required`);
  }
  if (normalized.length > maxLength) {
    throw new Error(`${label} exceeds ${maxLength} characters`);
  }
  return normalized;
}

function normalizeOptionalString(
  value: unknown,
  maxLength: number,
): string | null {
  if (value == null) {
    return null;
  }
  if (typeof value !== "string") {
    throw new Error("Optional string field is invalid");
  }
  const normalized = value.trim();
  if (!normalized) {
    return null;
  }
  if (normalized.length > maxLength) {
    throw new Error(`Optional string field exceeds ${maxLength} characters`);
  }
  return normalized;
}

function normalizeNotificationType(value: unknown): NotificationType {
  const normalized = typeof value === "string"
    ? value.trim().toLowerCase()
    : "";
  const allowed = new Set<NotificationType>([
    "deadline",
    "exam",
    "event",
    "announcement",
    "system",
    "study_prompt",
  ]);
  if (!allowed.has(normalized as NotificationType)) {
    throw new Error("type is invalid");
  }
  return normalized as NotificationType;
}

function normalizeDataPayload(
  type: NotificationType,
  title: string,
  body: string,
  link: string | null,
  relatedId: string | null,
  data: unknown,
): Record<string, string> {
  const payload: Record<string, string> = {
    type,
    title,
    body,
  };
  if (link) {
    payload.link = link;
  }
  if (relatedId) {
    payload.relatedId = relatedId;
  }
  if (data && typeof data === "object") {
    for (
      const [key, value] of Object.entries(data as Record<string, unknown>)
    ) {
      if (value == null) {
        continue;
      }
      payload[key] = typeof value === "string" ? value : JSON.stringify(value);
    }
  }
  return payload;
}

function channelIdFor(type: NotificationType): string {
  switch (type) {
    case "deadline":
      return "deadline_reminders";
    case "exam":
      return "exam_reminders";
    case "event":
      return "event_reminders";
    case "announcement":
      return "announcements";
    case "system":
      return "system_alerts";
    case "study_prompt":
      return "study_prompts";
  }
}

function toBase64Url(input: Uint8Array | string): string {
  const raw = typeof input === "string" ? input : String.fromCharCode(...input);
  return btoa(raw).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const normalized = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s+/g, "");
  const binary = atob(normalized);
  const bytes = new Uint8Array(binary.length);
  for (let index = 0; index < binary.length; index += 1) {
    bytes[index] = binary.charCodeAt(index);
  }
  return bytes.buffer;
}

async function signJwt(
  unsignedToken: string,
  privateKeyPem: string,
): Promise<string> {
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(privateKeyPem),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsignedToken),
  );
  return toBase64Url(new Uint8Array(signature));
}

async function getV1AccessToken(
  serviceAccount: ServiceAccount,
): Promise<string> {
  const nowSeconds = Math.floor(Date.now() / 1000);
  const header = toBase64Url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = toBase64Url(
    JSON.stringify({
      iss: serviceAccount.client_email,
      scope: FCM_SCOPE,
      aud: serviceAccount.token_uri ?? GOOGLE_OAUTH_TOKEN_URL,
      exp: nowSeconds + 3600,
      iat: nowSeconds,
    }),
  );
  const unsignedToken = `${header}.${claims}`;
  const signature = await signJwt(unsignedToken, serviceAccount.private_key);
  const assertion = `${unsignedToken}.${signature}`;

  const response = await fetch(
    serviceAccount.token_uri ?? GOOGLE_OAUTH_TOKEN_URL,
    {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion,
      }).toString(),
    },
  );

  const payload = (await response.json()) as {
    access_token?: string;
    error?: string;
  };
  if (!response.ok || !payload.access_token) {
    throw new Error(payload.error ?? "Unable to obtain Firebase access token");
  }

  return payload.access_token;
}

async function sendViaV1(
  tokens: TokenRow[],
  payload: Record<string, string>,
  type: NotificationType,
): Promise<
  { deliveredCount: number; messageIds: string[]; staleTokens: string[] }
> {
  const serviceAccount = JSON.parse(
    requireEnv("FIREBASE_SERVICE_ACCOUNT_JSON"),
  ) as ServiceAccount;
  const accessToken = await getV1AccessToken(serviceAccount);
  const endpoint =
    `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`;

  const responses = await Promise.all(
    tokens.map(async ({ token }) => {
      const response = await fetch(endpoint, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token,
            notification: {
              title: payload.title,
              body: payload.body,
            },
            data: payload,
            android: {
              notification: {
                channelId: channelIdFor(type),
              },
            },
            apns: {
              payload: {
                aps: {
                  sound: "default",
                },
              },
            },
          },
        }),
      });

      const text = await response.text();
      let json: Record<string, unknown> = {};
      try {
        json = text ? (JSON.parse(text) as Record<string, unknown>) : {};
      } catch {
        json = {};
      }
      if (response.ok) {
        return {
          delivered: true,
          messageId: typeof json.name === "string" ? json.name : null,
          stale: false,
          token,
        };
      }

      const errorPayload = json.error as
        | { status?: string; message?: string }
        | undefined;
      const stale = errorPayload?.status === "UNREGISTERED" ||
        errorPayload?.message?.includes(
          "registration token is not a valid FCM registration token",
        ) ||
        errorPayload?.message?.includes("Requested entity was not found");

      return { delivered: false, messageId: null, stale, token };
    }),
  );

  return {
    deliveredCount: responses.filter((item) => item.delivered).length,
    messageIds: responses.flatMap((
      item,
    ) => (item.messageId ? [item.messageId] : [])),
    staleTokens: responses.flatMap((item) => (item.stale ? [item.token] : [])),
  };
}

async function sendViaLegacy(
  tokens: TokenRow[],
  payload: Record<string, string>,
): Promise<
  { deliveredCount: number; messageIds: string[]; staleTokens: string[] }
> {
  const serverKey = requireEnv("FCM_SERVER_KEY");
  const responses = await Promise.all(
    tokens.map(async ({ token }) => {
      const response = await fetch(LEGACY_FCM_URL, {
        method: "POST",
        headers: {
          Authorization: `key=${serverKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          to: token,
          priority: "high",
          notification: {
            title: payload.title,
            body: payload.body,
          },
          data: payload,
        }),
      });

      const json = (await response.json()) as {
        results?: Array<{ message_id?: string; error?: string }>;
      };
      const result = json.results?.[0];
      const stale = result?.error === "NotRegistered" ||
        result?.error === "InvalidRegistration";

      return {
        delivered: response.ok && !!result?.message_id,
        messageId: result?.message_id ?? null,
        stale,
        token,
      };
    }),
  );

  return {
    deliveredCount: responses.filter((item) => item.delivered).length,
    messageIds: responses.flatMap((
      item,
    ) => (item.messageId ? [item.messageId] : [])),
    staleTokens: responses.flatMap((item) => (item.stale ? [item.token] : [])),
  };
}

async function sendPushNotifications(
  tokens: TokenRow[],
  payload: Record<string, string>,
  type: NotificationType,
): Promise<{
  configured: boolean;
  deliveredCount: number;
  messageIds: string[];
  staleTokens: string[];
}> {
  if (tokens.length === 0) {
    return {
      configured: true,
      deliveredCount: 0,
      messageIds: [],
      staleTokens: [],
    };
  }

  if (Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON")) {
    const result = await sendViaV1(tokens, payload, type);
    return { configured: true, ...result };
  }

  if (Deno.env.get("FCM_SERVER_KEY")) {
    const result = await sendViaLegacy(tokens, payload);
    return { configured: true, ...result };
  }

  return {
    configured: false,
    deliveredCount: 0,
    messageIds: [],
    staleTokens: [],
  };
}

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    const supabase = getAdminClient();
    const caller = await requireUser(req, supabase);
    const body = await req.json();

    const userId = normalizeString(body.userId, "userId", 64);
    if (caller.id !== userId && !isAdmin(caller)) {
      return jsonResponse({ error: "Forbidden" }, 403);
    }

    const type = normalizeNotificationType(body.type);
    const title = normalizeString(body.title, "title", 120);
    const message = normalizeString(body.body, "body", 500);
    const link = normalizeOptionalString(body.link, 256);
    if (link && !link.startsWith("/")) {
      throw new Error("link must be an in-app path");
    }
    const relatedId = normalizeOptionalString(
      body.relatedId ?? body.related_id,
      64,
    );
    const dataPayload = normalizeDataPayload(
      type,
      title,
      message,
      link,
      relatedId,
      body.data,
    );

    const { data: insertedNotification, error: insertError } = await supabase
      .from("notifications")
      .insert({
        user_id: userId,
        type,
        title,
        message,
        link,
        related_id: relatedId,
        read: false,
      })
      .select("id")
      .single();

    if (insertError) {
      throw insertError;
    }

    let pushEnabled = true;
    try {
      const { data: preference } = await supabase
        .from("notification_preferences")
        .select("enabled")
        .eq("user_id", userId)
        .eq("type", type)
        .maybeSingle();
      pushEnabled = preference?.enabled !== false;
    } catch {
      pushEnabled = true;
    }

    const { data: tokenRows, error: tokensError } = await supabase
      .from("user_fcm_tokens")
      .select("token,platform")
      .eq("user_id", userId);

    if (tokensError) {
      throw tokensError;
    }

    const tokens = (tokenRows as TokenRow[] | null) ?? [];
    if (!pushEnabled || tokens.length === 0) {
      return jsonResponse({
        success: true,
        notificationId: insertedNotification.id,
        deliveredCount: 0,
        messageIds: [],
        pushEnabled,
      });
    }

    const sendResult = await sendPushNotifications(tokens, dataPayload, type);
    if (sendResult.staleTokens.length > 0) {
      await supabase
        .from("user_fcm_tokens")
        .delete()
        .eq("user_id", userId)
        .in("token", sendResult.staleTokens);
    }

    const status = sendResult.configured ? 200 : 202;
    return jsonResponse(
      {
        success: true,
        notificationId: insertedNotification.id,
        deliveredCount: sendResult.deliveredCount,
        messageIds: sendResult.messageIds,
        pushEnabled,
        pushConfigured: sendResult.configured,
      },
      status,
    );
  } catch (err) {
    const message = (err as Error).message;
    const status = message === "Unauthorized"
      ? 401
      : message === "Forbidden"
      ? 403
      : 500;
    return jsonResponse({ error: message }, status);
  }
});
