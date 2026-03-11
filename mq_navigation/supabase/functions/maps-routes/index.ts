/// Edge Function: maps-routes
/// Replaces: /api/maps/routes for the Flutter client
/// Requires: SUPABASE_SERVICE_ROLE_KEY, GOOGLE_ROUTES_API_KEY
///
/// Authenticated Google Routes proxy with per-user rate limiting.

import {
  createClient,
  type User,
} from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, handleCors } from "../_shared/cors.ts";

const GOOGLE_ROUTES_URL =
  "https://routes.googleapis.com/directions/v2:computeRoutes";
const RATE_LIMIT_WINDOW_MS = 60_000;
const RATE_LIMIT_MAX_REQUESTS = 60;
const ROUTE_FIELD_MASK =
  "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.legs.steps";

type CoordinatePayload = {
  latitude: number;
  longitude: number;
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

function parseCoordinate(value: unknown, label: string): CoordinatePayload {
  if (!value || typeof value !== "object") {
    throw new Error(`${label} is required`);
  }

  const latitude = Number((value as Record<string, unknown>).latitude);
  const longitude = Number((value as Record<string, unknown>).longitude);
  if (!Number.isFinite(latitude) || latitude < -90 || latitude > 90) {
    throw new Error(`${label}.latitude is invalid`);
  }
  if (!Number.isFinite(longitude) || longitude < -180 || longitude > 180) {
    throw new Error(`${label}.longitude is invalid`);
  }

  return { latitude, longitude };
}

function parseTravelMode(value: unknown): string {
  const normalized = typeof value === "string" ? value.toUpperCase() : "WALK";
  const allowed = new Set(["WALK", "DRIVE", "BICYCLE", "TRANSIT"]);
  if (!allowed.has(normalized)) {
    throw new Error("travelMode must be WALK, DRIVE, BICYCLE, or TRANSIT");
  }
  return normalized;
}

async function enforceRateLimit(userId: string, supabase = getAdminClient()) {
  const key = `maps-routes:${userId}`;
  const nowMs = Date.now();

  const { data: existing, error: selectError } = await supabase
    .from("rate_limits")
    .select("key,count,reset_time_ms,created_at")
    .eq("key", key)
    .maybeSingle();

  if (selectError) {
    throw selectError;
  }

  const resetTimeMs = Number(existing?.reset_time_ms ?? 0);
  const activeWindow = existing && resetTimeMs > nowMs;
  const currentCount = Number(existing?.count ?? 0);

  if (activeWindow && currentCount >= RATE_LIMIT_MAX_REQUESTS) {
    const retryAfterMs = resetTimeMs - nowMs;
    return {
      allowed: false,
      retryAfterSeconds: Math.max(1, Math.ceil(retryAfterMs / 1000)),
    };
  }

  const nextResetTimeMs = activeWindow
    ? resetTimeMs
    : nowMs + RATE_LIMIT_WINDOW_MS;
  const nextCount = activeWindow ? currentCount + 1 : 1;
  const timestamp = new Date(nowMs).toISOString();

  const { error: upsertError } = await supabase.from("rate_limits").upsert(
    {
      key,
      count: nextCount,
      reset_time_ms: nextResetTimeMs,
      created_at: existing?.created_at ?? timestamp,
      updated_at: timestamp,
    },
    { onConflict: "key" },
  );

  if (upsertError) {
    throw upsertError;
  }

  return { allowed: true, retryAfterSeconds: 0 };
}

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    const user = await requireUser(req);
    const rateLimit = await enforceRateLimit(user.id);
    if (!rateLimit.allowed) {
      return jsonResponse(
        {
          error: "Rate limit exceeded",
          retryAfterSeconds: rateLimit.retryAfterSeconds,
        },
        429,
      );
    }

    const apiKey = requireEnv("GOOGLE_ROUTES_API_KEY");
    const body = await req.json();
    const origin = parseCoordinate(body.origin, "origin");
    const destination = parseCoordinate(body.destination, "destination");
    const travelMode = parseTravelMode(body.travelMode);

    const upstream = await fetch(GOOGLE_ROUTES_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": apiKey,
        "X-Goog-FieldMask": ROUTE_FIELD_MASK,
      },
      body: JSON.stringify({
        origin: {
          location: {
            latLng: { latitude: origin.latitude, longitude: origin.longitude },
          },
        },
        destination: {
          location: {
            latLng: {
              latitude: destination.latitude,
              longitude: destination.longitude,
            },
          },
        },
        travelMode,
        computeAlternativeRoutes: false,
        languageCode: typeof body.languageCode === "string"
          ? body.languageCode
          : "en",
        units: "METRIC",
      }),
    });

    const upstreamText = await upstream.text();
    let upstreamJson: Record<string, unknown> | null = null;
    try {
      upstreamJson = JSON.parse(upstreamText) as Record<string, unknown>;
    } catch {
      upstreamJson = null;
    }

    if (!upstream.ok) {
      return jsonResponse(
        {
          error: (upstreamJson?.error as { message?: string } | undefined)
            ?.message ??
            "Google Routes API error",
        },
        upstream.status,
      );
    }

    return jsonResponse(upstreamJson ?? { raw: upstreamText });
  } catch (err) {
    const message = (err as Error).message;
    const status = message === "Unauthorized" ? 401 : 500;
    return jsonResponse({ error: message }, status);
  }
});
