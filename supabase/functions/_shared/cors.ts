const DEFAULT_ALLOW_HEADERS =
  "authorization, x-client-info, apikey, content-type, x-app-check-token";
const DEFAULT_ALLOW_METHODS = "GET, POST, OPTIONS";

/// Shared CORS headers for Edge Functions that are not origin-restricted.
export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": DEFAULT_ALLOW_HEADERS,
  "Access-Control-Allow-Methods": DEFAULT_ALLOW_METHODS,
};

type CorsOptions = {
  allowedOrigins?: readonly string[];
};

function buildCorsHeaders(origin: string | null, options?: CorsOptions) {
  const allowedOrigins = options?.allowedOrigins ?? [];
  const allowOrigin = origin && allowedOrigins.includes(origin) ? origin : "*";
  return {
    "Access-Control-Allow-Origin": allowOrigin,
    "Access-Control-Allow-Headers": DEFAULT_ALLOW_HEADERS,
    "Access-Control-Allow-Methods": DEFAULT_ALLOW_METHODS,
    Vary: "Origin",
  };
}

/// Returns a CORS preflight response or rejects disallowed browser origins.
///
/// Non-browser clients such as the Flutter mobile app typically do not send an
/// `Origin` header, so allowlisting only applies when an origin is present.
export function handleCors(req: Request, options?: CorsOptions): Response | null {
  const origin = req.headers.get("origin");
  const allowedOrigins = options?.allowedOrigins ?? [];
  const hasOriginRestriction = allowedOrigins.length > 0;

  if (origin && hasOriginRestriction && !allowedOrigins.includes(origin)) {
    return new Response("forbidden", {
      status: 403,
      headers: buildCorsHeaders(origin, options),
    });
  }

  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: buildCorsHeaders(origin, options),
    });
  }
  return null;
}

export function jsonCorsHeaders(req: Request, options?: CorsOptions) {
  return buildCorsHeaders(req.headers.get("origin"), options);
}
