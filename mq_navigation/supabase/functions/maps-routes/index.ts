/// Edge Function: maps-routes
/// Shared campus/google routing proxy for the Flutter dual-map client.
/// Supports anon access with IP-based throttling and upgrades to user-based
/// throttling when a valid Supabase access token is present.

import {
  createClient,
  type User,
} from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  handleCors,
  jsonCorsHeaders,
} from "../_shared/cors.ts";

const GOOGLE_ROUTES_URL =
  "https://routes.googleapis.com/directions/v2:computeRoutes";
const ORS_BASE_URL = Deno.env.get("ORS_BASE_URL") ??
  "https://api.openrouteservice.org/v2/directions/foot-walking/geojson";
const RATE_LIMIT_WINDOW_MS = 60_000;
const RATE_LIMIT_MAX_REQUESTS = 60;
const GOOGLE_ROUTES_FIELD_MASK = [
  "routes.distanceMeters",
  "routes.duration",
  "routes.polyline.encodedPolyline",
  "routes.legs.steps.distanceMeters",
  "routes.legs.steps.staticDuration",
  "routes.legs.steps.travelMode",
  "routes.legs.steps.navigationInstruction.instructions",
  "routes.legs.steps.transitDetails",
].join(",");

type CoordinatePayload = {
  latitude: number;
  longitude: number;
};

type RouteRenderer = "campus" | "google";

type NormalizedStep = {
  instruction: string;
  distanceMeters: number;
  durationSeconds: number;
  maneuver?: string;
  travelMode?: string;
  transitLineName?: string;
  transitHeadsign?: string;
  transitStopCount?: number;
};

type NormalizedRoute = {
  renderer: RouteRenderer;
  mode: string;
  distanceMeters: number;
  durationSeconds: number;
  encodedPolyline: string;
  points: Array<{ lat: number; lng: number }>;
  steps: NormalizedStep[];
  arrivalEstimate: string;
};

class RequestValidationError extends Error {
  status: number;

  constructor(message: string, status = 400) {
    super(message);
    this.name = "RequestValidationError";
    this.status = status;
  }
}

function requireEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    throw new Error(`${name} is not configured`);
  }
  return value;
}

function getAllowedWebOrigins(): string[] {
  return (Deno.env.get("ALLOWED_WEB_ORIGINS") ?? "")
    .split(",")
    .map((origin) => origin.trim())
    .filter((origin) => origin.length > 0);
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

async function maybeUser(
  req: Request,
  supabase = getAdminClient(),
): Promise<User | null> {
  const authHeader = req.headers.get("authorization");
  const token = authHeader?.startsWith("Bearer ") ? authHeader.slice(7) : null;
  if (!token) {
    return null;
  }

  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data.user) {
    return null;
  }

  return data.user;
}

function parseRenderer(value: unknown): RouteRenderer {
  if (value === "campus" || value === "google") {
    return value;
  }
  throw new RequestValidationError("renderer must be campus or google");
}

function parseCoordinate(value: unknown, label: string): CoordinatePayload {
  if (!value || typeof value !== "object") {
    throw new Error(`${label} is required`);
  }

  const record = value as Record<string, unknown>;
  const latitude = Number(record.latitude ?? record.lat);
  const longitude = Number(record.longitude ?? record.lng);

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
    throw new RequestValidationError(
      "travelMode must be WALK, DRIVE, BICYCLE, or TRANSIT",
    );
  }
  return normalized;
}

function assertCampusTravelModeSupported(travelMode: string): void {
  if (travelMode !== "WALK") {
    throw new RequestValidationError(
      "Campus routing currently supports WALK only. Switch to the Google renderer for drive, bicycle, or transit routes.",
    );
  }
}

async function enforceRateLimit(
  identity: string,
  supabase = getAdminClient(),
) {
  const key = `maps-routes:${identity}`;
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

function parseDurationSeconds(value: unknown): number {
  if (typeof value === "number") {
    return value;
  }

  if (typeof value === "string") {
    const parsed = Number.parseFloat(value.replace("s", ""));
    return Number.isFinite(parsed) ? Math.round(parsed) : 0;
  }

  return 0;
}

function decodePolyline(encoded: string): Array<{ lat: number; lng: number }> {
  let index = 0;
  let lat = 0;
  let lng = 0;
  const coordinates: Array<{ lat: number; lng: number }> = [];

  while (index < encoded.length) {
    let result = 0;
    let shift = 0;
    let byte = 0;

    do {
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);

    lat += (result & 1) !== 0 ? ~(result >> 1) : result >> 1;

    result = 0;
    shift = 0;

    do {
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);

    lng += (result & 1) !== 0 ? ~(result >> 1) : result >> 1;

    coordinates.push({
      lat: lat / 1e5,
      lng: lng / 1e5,
    });
  }

  return coordinates;
}

function toArrivalEstimate(durationSeconds: number): string {
  return new Date(Date.now() + durationSeconds * 1000).toISOString();
}

function normaliseGoogleRoute(
  renderer: RouteRenderer,
  travelMode: string,
  route: Record<string, unknown>,
): NormalizedRoute {
  const legs = (route.legs as Array<Record<string, unknown>> | undefined) ?? [];
  const steps = legs.flatMap((leg) =>
    ((leg.steps as Array<Record<string, unknown>> | undefined) ?? []).map(
      (step) => ({
        instruction:
          (step.navigationInstruction as { instructions?: string } | undefined)
            ?.instructions ?? "Continue",
        distanceMeters: Number(step.distanceMeters ?? 0),
        durationSeconds: parseDurationSeconds(step.staticDuration),
        travelMode: step.travelMode as string | undefined,
        transitLineName: (step.transitDetails as {
          transitLine?: { nameShort?: string; name?: string };
        } | undefined)?.transitLine?.nameShort ??
          (step.transitDetails as {
            transitLine?: { nameShort?: string; name?: string };
          } | undefined)?.transitLine?.name,
        transitHeadsign:
          (step.transitDetails as { headsign?: string } | undefined)?.headsign,
        transitStopCount:
          (step.transitDetails as { stopCount?: number } | undefined)
            ?.stopCount,
      }),
    )
  );
  const encodedPolyline =
    (route.polyline as { encodedPolyline?: string } | undefined)
      ?.encodedPolyline ?? "";

  return {
    renderer,
    mode: travelMode,
    distanceMeters: Number(route.distanceMeters ?? 0),
    durationSeconds: parseDurationSeconds(route.duration),
    encodedPolyline,
    points: encodedPolyline ? decodePolyline(encodedPolyline) : [],
    steps,
    arrivalEstimate: toArrivalEstimate(parseDurationSeconds(route.duration)),
  };
}

function generateDemoCampusRoute(
  origin: CoordinatePayload,
  destination: CoordinatePayload,
): {
  coordinates: [number, number][];
  distanceMeters: number;
  durationSeconds: number;
} {
  const KM_PER_DEGREE_LAT = 111.32;
  const KM_PER_DEGREE_LNG = 111.32 * Math.cos((-33.775 * Math.PI) / 180);
  const latDiff = destination.latitude - origin.latitude;
  const lngDiff = destination.longitude - origin.longitude;
  const distanceKm = Math.sqrt(
    Math.pow(latDiff * KM_PER_DEGREE_LAT, 2) +
      Math.pow(lngDiff * KM_PER_DEGREE_LNG, 2),
  );
  const distanceMeters = distanceKm * 1000;
  const durationSeconds = (distanceKm / 5) * 3600;
  const numPoints = Math.max(5, Math.min(20, Math.ceil(distanceMeters / 50)));
  const coordinates: [number, number][] = [];

  for (let i = 0; i <= numPoints; i += 1) {
    const t = i / numPoints;
    coordinates.push([
      origin.longitude + lngDiff * t,
      origin.latitude + latDiff * t,
    ]);
  }

  return { coordinates, distanceMeters, durationSeconds };
}

function normaliseCampusRoute(
  travelMode: string,
  orsData: Record<string, unknown>,
): NormalizedRoute {
  const features = (orsData.features as Array<Record<string, unknown>>) ?? [];
  const feature = features[0] ?? {};
  const geometry = (feature.geometry as Record<string, unknown>) ?? {};
  const coordinates =
    (geometry.coordinates as Array<[number, number]> | undefined) ?? [];
  const properties = (feature.properties as Record<string, unknown>) ?? {};
  const summary = (properties.summary as Record<string, unknown>) ?? {};
  const segments =
    (properties.segments as Array<Record<string, unknown>> | undefined) ?? [];
  const steps = segments.flatMap((segment) =>
    ((segment.steps as Array<Record<string, unknown>> | undefined) ?? []).map(
      (step) => ({
        instruction: (step.instruction as string | undefined) ?? "Continue",
        distanceMeters: Number(step.distance ?? 0),
        durationSeconds: Number(step.duration ?? 0),
        maneuver: String(step.type ?? ""),
      }),
    )
  );

  const points = coordinates.map(([lng, lat]) => ({ lat, lng }));
  const durationSeconds = Number(summary.duration ?? 0);

  return {
    renderer: "campus",
    mode: travelMode,
    distanceMeters: Number(summary.distance ?? 0),
    durationSeconds,
    encodedPolyline: "",
    points,
    steps,
    arrivalEstimate: toArrivalEstimate(durationSeconds),
  };
}

async function fetchGoogleRoute(
  renderer: RouteRenderer,
  origin: CoordinatePayload,
  destination: CoordinatePayload,
  travelMode: string,
  languageCode: string,
): Promise<NormalizedRoute> {
  const apiKey = requireEnv("GOOGLE_ROUTES_API_KEY");
  const body: Record<string, unknown> = {
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
    languageCode,
    units: "METRIC",
  };

  if (travelMode === "DRIVE") {
    body.routingPreference = "TRAFFIC_AWARE";
  }

  if (travelMode === "TRANSIT") {
    body.departureTime = new Date().toISOString();
  }

  const upstream = await fetch(GOOGLE_ROUTES_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": apiKey,
      "X-Goog-FieldMask": GOOGLE_ROUTES_FIELD_MASK,
    },
    body: JSON.stringify(body),
  });

  const upstreamText = await upstream.text();
  let upstreamJson: Record<string, unknown> | null = null;
  try {
    upstreamJson = JSON.parse(upstreamText) as Record<string, unknown>;
  } catch {
    upstreamJson = null;
  }

  if (!upstream.ok) {
    throw new Error(
      (upstreamJson?.error as { message?: string } | undefined)?.message ??
        "Google Routes API error",
    );
  }

  const routes = (upstreamJson?.routes as Array<Record<string, unknown>>) ?? [];
  if (routes.length === 0) {
    throw new Error("No Google routes were returned");
  }

  return normaliseGoogleRoute(renderer, travelMode, routes[0]);
}

async function fetchCampusRoute(
  origin: CoordinatePayload,
  destination: CoordinatePayload,
  travelMode: string,
): Promise<NormalizedRoute> {
  const orsApiKey = Deno.env.get("ORS_API_KEY");

  if (!orsApiKey) {
    const demo = generateDemoCampusRoute(origin, destination);
    return normaliseCampusRoute(travelMode, {
      features: [
        {
          geometry: {
            coordinates: demo.coordinates,
          },
          properties: {
            summary: {
              distance: demo.distanceMeters,
              duration: demo.durationSeconds,
            },
            segments: [
              {
                steps: [
                  {
                    type: 11,
                    instruction: "Head towards your destination",
                    distance: demo.distanceMeters * 0.4,
                    duration: demo.durationSeconds * 0.4,
                  },
                  {
                    type: 4,
                    instruction: "Continue on the campus pathway",
                    distance: demo.distanceMeters * 0.4,
                    duration: demo.durationSeconds * 0.4,
                  },
                  {
                    type: 10,
                    instruction: "Arrive at your destination",
                    distance: demo.distanceMeters * 0.2,
                    duration: demo.durationSeconds * 0.2,
                  },
                ],
              },
            ],
          },
        },
      ],
    });
  }

  const upstream = await fetch(ORS_BASE_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: orsApiKey,
    },
    body: JSON.stringify({
      coordinates: [
        [origin.longitude, origin.latitude],
        [destination.longitude, destination.latitude],
      ],
      instructions: true,
    }),
    signal: AbortSignal.timeout(10_000),
  });

  const upstreamText = await upstream.text();
  let upstreamJson: Record<string, unknown> | null = null;
  try {
    upstreamJson = JSON.parse(upstreamText) as Record<string, unknown>;
  } catch {
    upstreamJson = null;
  }

  if (!upstream.ok || upstreamJson == null) {
    throw new Error("Campus routing service error");
  }

  return normaliseCampusRoute(travelMode, upstreamJson);
}

Deno.serve(async (req) => {
  const allowedOrigins = getAllowedWebOrigins();
  const cors = handleCors(req, { allowedOrigins });
  if (cors) return cors;

  try {
    const user = await maybeUser(req);
    const identity = user != null
      ? `user:${user.id}`
      : `ip:${getClientIp(req)}`;
    const rateLimit = await enforceRateLimit(identity);
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
    const renderer = parseRenderer(body.renderer);
    const origin = parseCoordinate(body.origin, "origin");
    const destination = parseCoordinate(body.destination, "destination");
    const travelMode = parseTravelMode(body.travelMode);
    const languageCode = typeof body.languageCode === "string"
      ? body.languageCode
      : "en-AU";

    if (renderer === "campus") {
      assertCampusTravelModeSupported(travelMode);
    }

    const route = renderer === "campus"
      ? await fetchCampusRoute(origin, destination, travelMode)
      : await fetchGoogleRoute(
        renderer,
        origin,
        destination,
        travelMode,
        languageCode,
      );

    return new Response(JSON.stringify(route), {
      headers: {
        ...jsonCorsHeaders(req, { allowedOrigins }),
        "Content-Type": "application/json",
      },
    });
  } catch (err) {
    const error = err as Error & { status?: number };
    return new Response(JSON.stringify({ error: error.message }), {
      status: error.status ?? 500,
      headers: {
        ...jsonCorsHeaders(req, { allowedOrigins }),
        "Content-Type": "application/json",
      },
    });
  }
});
