/// Edge Function: security-utils
/// Replaces: /api/security/check-password-breach
///
/// Checks passwords against the Have I Been Pwned API using k-anonymity
/// (only the first 5 chars of the SHA-1 hash are sent). No secrets needed;
/// JWT verification is disabled for this function so it can be called
/// during signup before authentication.

import { corsHeaders, handleCors } from "../_shared/cors.ts";

async function sha1Hex(text: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(text);
  const hash = await crypto.subtle.digest("SHA-1", data);
  return Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("")
    .toUpperCase();
}

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    const { password } = await req.json();
    if (!password || typeof password !== "string") {
      return new Response(JSON.stringify({ error: "password is required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const hash = await sha1Hex(password);
    const prefix = hash.slice(0, 5);
    const suffix = hash.slice(5);

    // k-anonymity: only send first 5 hex chars
    const res = await fetch(`https://api.pwnedpasswords.com/range/${prefix}`, {
      headers: { "Add-Padding": "true" },
    });

    if (!res.ok) {
      return new Response(JSON.stringify({ error: "HIBP API unavailable" }), {
        status: 502,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = await res.text();
    const breached = body
      .split("\n")
      .some((line) => {
        const [hashSuffix] = line.split(":");
        return hashSuffix.trim() === suffix;
      });

    return new Response(JSON.stringify({ breached }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: (err as Error).message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
