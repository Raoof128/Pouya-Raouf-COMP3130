/// Edge Function: maps-places
/// Google Places Autocomplete proxy for the Flutter search fallback.
/// Returns place suggestions when campus building search yields no strong matches.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { handleCors, jsonCorsHeaders } from "../_shared/cors.ts";

const RATE_LIMIT_WINDOW_MS = 60_000;
const RATE_LIMIT_MAX_REQUESTS = 30;
const CACHE_TTL_MS = 24 * 60 * 60 * 1000;

type CachePayload = {
  suggestions: Array<{
    placeId: string;
    description: string;
  }>;
};

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

function getClientIp(req: Request): string {
  const forwardedFor = req.headers.get("x-forwarded-for");
  if (forwardedFor) {
    return forwardedFor.split(",")[0].trim();
  }

  return req.headers.get("cf-connecting-ip") ??
    req.headers.get("x-real-ip") ??
    "unknown";
}

function getAllowedWebOrigins(): string[] {
  return (Deno.env.get("ALLOWED_WEB_ORIGINS") ?? "")
    .split(",")
    .map((origin) => origin.trim())
    .filter((origin) => origin.length > 0);
}

async function enforceRateLimit(identity: string) {
  const supabase = getAdminClient();
  const key = `maps-places:${identity}`;
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
    return {
      allowed: false,
      retryAfterSeconds: Math.max(1, Math.ceil((resetTimeMs - nowMs) / 1000)),
    };
  }

  const timestamp = new Date(nowMs).toISOString();
  const { error: upsertError } = await supabase.from("rate_limits").upsert(
    {
      key,
      count: activeWindow ? currentCount + 1 : 1,
      reset_time_ms: activeWindow ? resetTimeMs : nowMs + RATE_LIMIT_WINDOW_MS,
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

function normalizeCacheKey(
  query: string,
  latitude: number | null,
  longitude: number | null,
): string {
  const lat = Number.isFinite(latitude) ? latitude!.toFixed(3) : "none";
  const lng = Number.isFinite(longitude) ? longitude!.toFixed(3) : "none";
  return `maps-places:${query.trim().toLowerCase()}:${lat}:${lng}`;
}

async function getCachedResponse(cacheKey: string): Promise<CachePayload | null> {
  const supabase = getAdminClient();
  const now = new Date().toISOString();
  const { data, error } = await supabase
    .from("edge_response_cache")
    .select("payload,expires_at")
    .eq("key", cacheKey)
    .gt("expires_at", now)
    .maybeSingle();

  if (error) {
    throw error;
  }

  return (data?.payload as CachePayload | null) ?? null;
}

async function cacheResponse(cacheKey: string, payload: CachePayload) {
  const supabase = getAdminClient();
  const now = new Date().toISOString();
  const expiresAt = new Date(Date.now() + CACHE_TTL_MS).toISOString();
  const { error } = await supabase.from("edge_response_cache").upsert(
    {
      key: cacheKey,
      payload,
      expires_at: expiresAt,
      created_at: now,
      updated_at: now,
    },
    { onConflict: "key" },
  );

  if (error) {
    throw error;
  }
}

Deno.serve(async (req) => {
  const allowedOrigins = getAllowedWebOrigins();
  const cors = handleCors(req, { allowedOrigins });
  if (cors) return cors;

  try {
    const apiKey = Deno.env.get("GOOGLE_ROUTES_API_KEY");
    if (!apiKey) {
      return new Response(
        JSON.stringify(
          { error: "Google Places API key is not configured" },
        ),
        {
          status: 503,
          headers: {
            ...jsonCorsHeaders(req, { allowedOrigins }),
            "Content-Type": "application/json",
          },
        },
      );
    }

    const rateLimit = await enforceRateLimit(`ip:${getClientIp(req)}`);
    if (!rateLimit.allowed) {
      return new Response(
        JSON.stringify({
          error: "Rate limit exceeded",
          retryAfterSeconds: rateLimit.retryAfterSeconds,
        }),
        {
          status: 429,
          headers: {
            ...jsonCorsHeaders(req, { allowedOrigins }),
            "Content-Type": "application/json",
            "Retry-After": String(rateLimit.retryAfterSeconds),
          },
        },
      );
    }

    const body = await req.json();
    const query = typeof body.query === "string" ? body.query.trim() : "";

    if (query.length < 2) {
      return new Response(JSON.stringify({ suggestions: [] }), {
        headers: {
          ...jsonCorsHeaders(req, { allowedOrigins }),
          "Content-Type": "application/json",
        },
      });
    }

    const latitude = Number(body.latitude);
    const longitude = Number(body.longitude);
    const cacheKey = normalizeCacheKey(
      query,
      Number.isFinite(latitude) ? latitude : null,
      Number.isFinite(longitude) ? longitude : null,
    );

    const cached = await getCachedResponse(cacheKey);
    if (cached != null) {
      return new Response(JSON.stringify(cached), {
        headers: {
          ...jsonCorsHeaders(req, { allowedOrigins }),
          "Content-Type": "application/json",
          "Cache-Control": "private, max-age=300",
          "X-Cache": "HIT",
        },
      });
    }

    const params = new URLSearchParams({
      input: query,
      key: apiKey,
      components: "country:au",
    });

    if (Number.isFinite(latitude) && Number.isFinite(longitude)) {
      params.set("location", `${latitude},${longitude}`);
      params.set("radius", "5000");
    }

    const url =
      `https://maps.googleapis.com/maps/api/place/autocomplete/json?${params}`;

    const upstream = await fetch(url, {
      signal: AbortSignal.timeout(10_000),
    });

    if (!upstream.ok) {
      return new Response(JSON.stringify({ suggestions: [] }), {
        headers: {
          ...jsonCorsHeaders(req, { allowedOrigins }),
          "Content-Type": "application/json",
        },
      });
    }

    const data = (await upstream.json()) as {
      predictions?: Array<{
        place_id?: string;
        description?: string;
      }>;
    };

    const payload: CachePayload = {
      suggestions: (data.predictions ?? [])
        .filter((p) => p.place_id && p.description)
        .map((p) => ({
          placeId: p.place_id!,
          description: p.description!,
        })),
    };

    await cacheResponse(cacheKey, payload);

    return new Response(JSON.stringify(payload), {
      headers: {
        ...jsonCorsHeaders(req, { allowedOrigins }),
        "Content-Type": "application/json",
        "Cache-Control": "private, max-age=300",
        "X-Cache": "MISS",
      },
    });
  } catch (err) {
    console.error("maps-places failed", err);
    return new Response(JSON.stringify({ suggestions: [] }), {
      headers: {
        ...jsonCorsHeaders(req, { allowedOrigins }),
        "Content-Type": "application/json",
      },
    });
  }
});
