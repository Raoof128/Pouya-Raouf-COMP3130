// deno-lint-ignore-file
// @ts-nocheck — This file runs in the Supabase/Deno runtime, not in the
// project's TypeScript context.  IDE type errors for Deno globals and
// .ts imports are expected and harmless.

/// Edge Function: directions-proxy
/// A simple CORS-friendly proxy for the Google Directions API.
/// Used by the Flutter web client which cannot call the Directions API
/// directly due to browser CORS restrictions.
///
/// No authentication required — the API key is stored server-side.

import { corsHeaders, handleCors } from "../_shared/cors.ts";

const GOOGLE_DIRECTIONS_URL =
  "https://maps.googleapis.com/maps/api/directions/json";

function jsonResponse(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request): Promise<Response> => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    const body = await req.json();
    const { origin, destination, mode, language, units } = body as {
      origin: string;
      destination: string;
      mode?: string;
      language?: string;
      units?: string;
    };

    if (!origin || !destination) {
      return jsonResponse({ error: "origin and destination are required" }, 400);
    }

    const apiKey = Deno.env.get("GOOGLE_ROUTES_API_KEY") ??
      Deno.env.get("GOOGLE_MAPS_API_KEY");
    if (!apiKey) {
      return jsonResponse(
        { error: "Google API key is not configured on the server" },
        500,
      );
    }

    const params = new URLSearchParams({
      origin,
      destination,
      mode: mode ?? "walking",
      language: language ?? "en",
      units: units ?? "metric",
      key: apiKey,
    });

    const upstream = await fetch(`${GOOGLE_DIRECTIONS_URL}?${params}`);
    const upstreamText = await upstream.text();

    let upstreamJson: unknown;
    try {
      upstreamJson = JSON.parse(upstreamText);
    } catch (_e) {
      upstreamJson = { raw: upstreamText };
    }

    return jsonResponse(upstreamJson, upstream.status);
  } catch (err) {
    const message = (err as Error).message ?? "Internal server error";
    return jsonResponse({ error: message }, 500);
  }
});

