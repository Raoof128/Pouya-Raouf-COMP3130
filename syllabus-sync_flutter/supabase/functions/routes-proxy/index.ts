/// Edge Function: routes-proxy
/// Replaces: /api/navigate, /api/maps/routes
/// Requires: GOOGLE_ROUTES_API_KEY
///
/// Proxies routing requests to the Google Routes API, keeping the
/// billing API key server-side. Both web and mobile clients call this
/// function instead of hitting Google directly.

import { corsHeaders, handleCors } from "../_shared/cors.ts";

const GOOGLE_ROUTES_URL = "https://routes.googleapis.com/directions/v2:computeRoutes";

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    const apiKey = Deno.env.get("GOOGLE_ROUTES_API_KEY");
    if (!apiKey) {
      return new Response(JSON.stringify({ error: "GOOGLE_ROUTES_API_KEY not configured" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = await req.json();

    // Validate required fields
    const { origin, destination, travelMode } = body;
    if (!origin || !destination) {
      return new Response(JSON.stringify({ error: "origin and destination are required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Build Google Routes API request
    const routeRequest = {
      origin: { location: { latLng: origin } },
      destination: { location: { latLng: destination } },
      travelMode: travelMode ?? "WALK",
      computeAlternativeRoutes: false,
      routeModifiers: { avoidTolls: false, avoidHighways: false, avoidFerries: false },
      languageCode: body.languageCode ?? "en",
      units: "METRIC",
    };

    const fieldMask = "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.legs.steps";

    const res = await fetch(GOOGLE_ROUTES_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": apiKey,
        "X-Goog-FieldMask": fieldMask,
      },
      body: JSON.stringify(routeRequest),
    });

    const data = await res.json();

    if (!res.ok) {
      return new Response(JSON.stringify({ error: data.error?.message ?? "Google Routes API error" }), {
        status: res.status,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: (err as Error).message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
