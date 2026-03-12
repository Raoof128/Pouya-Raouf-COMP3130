/// Edge Function: maps-places
/// Google Places Autocomplete proxy for the Flutter search fallback.
/// Returns place suggestions when campus building search yields no strong matches.

import { corsHeaders, handleCors } from "../_shared/cors.ts";

function jsonResponse(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  const apiKey = Deno.env.get("GOOGLE_ROUTES_API_KEY");
  if (!apiKey) {
    return jsonResponse(
      { error: "Google Places API key is not configured" },
      503,
    );
  }

  try {
    const body = await req.json();
    const query = typeof body.query === "string" ? body.query.trim() : "";

    if (query.length < 2) {
      return jsonResponse({ suggestions: [] });
    }

    const params = new URLSearchParams({
      input: query,
      key: apiKey,
      components: "country:au",
    });

    const latitude = Number(body.latitude);
    const longitude = Number(body.longitude);
    if (Number.isFinite(latitude) && Number.isFinite(longitude)) {
      params.set("location", `${latitude},${longitude}`);
      params.set("radius", "5000");
    }

    const url = `https://maps.googleapis.com/maps/api/place/autocomplete/json?${params}`;

    const upstream = await fetch(url, {
      signal: AbortSignal.timeout(10_000),
    });

    if (!upstream.ok) {
      return jsonResponse({ suggestions: [] });
    }

    const data = (await upstream.json()) as {
      predictions?: Array<{
        place_id?: string;
        description?: string;
      }>;
    };

    const suggestions = (data.predictions ?? [])
      .filter((p) => p.place_id && p.description)
      .map((p) => ({
        placeId: p.place_id,
        description: p.description,
      }));

    return jsonResponse({ suggestions });
  } catch {
    return jsonResponse({ suggestions: [] });
  }
});
