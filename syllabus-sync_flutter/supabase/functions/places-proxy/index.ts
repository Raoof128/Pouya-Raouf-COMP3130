/// Edge Function: places-proxy
/// Replaces: /api/maps/place-search, /api/maps/place-details
/// Requires: GOOGLE_ROUTES_API_KEY (also grants Places access)
///
/// Proxies place search and detail requests to the Google Places API (New),
/// keeping the billing API key server-side.

import { corsHeaders, handleCors } from "../_shared/cors.ts";

const PLACES_SEARCH_URL = "https://places.googleapis.com/v1/places:searchText";
const PLACES_DETAIL_URL = "https://places.googleapis.com/v1/places";

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    const apiKey = Deno.env.get("GOOGLE_ROUTES_API_KEY");
    if (!apiKey) {
      return new Response(JSON.stringify({ error: "API key not configured" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = await req.json();
    const { action } = body;

    if (action === "search") {
      const { query, locationBias } = body;
      if (!query) {
        return new Response(JSON.stringify({ error: "query is required" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const searchRequest: Record<string, unknown> = { textQuery: query, maxResultCount: 10 };
      if (locationBias) {
        searchRequest.locationBias = {
          circle: { center: locationBias, radius: 2000.0 },
        };
      }

      const fieldMask = "places.displayName,places.formattedAddress,places.location,places.id";
      const res = await fetch(PLACES_SEARCH_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Goog-Api-Key": apiKey,
          "X-Goog-FieldMask": fieldMask,
        },
        body: JSON.stringify(searchRequest),
      });

      const data = await res.json();
      return new Response(JSON.stringify(data), {
        status: res.ok ? 200 : res.status,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (action === "details") {
      const { placeId } = body;
      if (!placeId) {
        return new Response(JSON.stringify({ error: "placeId is required" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const fieldMask = "displayName,formattedAddress,location,rating,types,websiteUri,currentOpeningHours";
      const res = await fetch(`${PLACES_DETAIL_URL}/${placeId}`, {
        method: "GET",
        headers: {
          "X-Goog-Api-Key": apiKey,
          "X-Goog-FieldMask": fieldMask,
        },
      });

      const data = await res.json();
      return new Response(JSON.stringify(data), {
        status: res.ok ? 200 : res.status,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ error: 'action must be "search" or "details"' }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: (err as Error).message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
