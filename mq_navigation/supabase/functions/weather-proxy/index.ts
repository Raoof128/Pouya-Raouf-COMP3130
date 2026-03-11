/// Edge Function: weather-proxy
/// Replaces: /api/weather
/// Requires: GOOGLE_WEATHER_API_KEY
///
/// Proxies weather requests to the Google Weather API, keeping the
/// billing API key server-side. Returns current conditions for campus.

import { corsHeaders, handleCors } from "../_shared/cors.ts";

// Macquarie University campus coordinates
const CAMPUS_LAT = -33.7738;
const CAMPUS_LNG = 151.1126;

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    const apiKey = Deno.env.get("GOOGLE_WEATHER_API_KEY");
    if (!apiKey) {
      return new Response(JSON.stringify({ error: "GOOGLE_WEATHER_API_KEY not configured" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const url = new URL(req.url);
    const lat = parseFloat(url.searchParams.get("lat") ?? String(CAMPUS_LAT));
    const lng = parseFloat(url.searchParams.get("lng") ?? String(CAMPUS_LNG));

    const weatherUrl = `https://weather.googleapis.com/v1/currentConditions:lookup?key=${apiKey}`;
    const res = await fetch(weatherUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        location: { latitude: lat, longitude: lng },
      }),
    });

    const data = await res.json();

    if (!res.ok) {
      return new Response(JSON.stringify({ error: data.error?.message ?? "Weather API error" }), {
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
