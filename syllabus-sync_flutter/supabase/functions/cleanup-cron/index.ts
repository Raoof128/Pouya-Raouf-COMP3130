/// Edge Function: cleanup-cron
/// Replaces: /api/security/rate-limit/cleanup
/// Requires: SUPABASE_SERVICE_ROLE_KEY, CRON_SECRET
///
/// Scheduled cleanup of expired rate-limit records and stale audit logs.
/// Intended to be invoked by pg_cron or an external scheduler.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, handleCors } from "../_shared/cors.ts";

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    // Verify cron secret
    const cronSecret = Deno.env.get("CRON_SECRET");
    const authHeader = req.headers.get("authorization");
    if (cronSecret && authHeader !== `Bearer ${cronSecret}`) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const now = new Date().toISOString();

    // Clean expired rate-limit windows
    const { count: rateLimitCount } = await supabase
      .from("rate_limits")
      .delete()
      .lt("window_end", now);

    // Clean audit logs older than 180 days
    const retentionDate = new Date(Date.now() - 180 * 86400_000).toISOString();
    const { count: auditCount } = await supabase
      .from("audit_logs")
      .delete()
      .lt("created_at", retentionDate);

    return new Response(
      JSON.stringify({
        cleaned: {
          rate_limits: rateLimitCount ?? 0,
          audit_logs: auditCount ?? 0,
        },
        timestamp: now,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err) {
    return new Response(JSON.stringify({ error: (err as Error).message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
