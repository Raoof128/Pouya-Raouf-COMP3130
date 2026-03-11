/// Edge Function: auth-cleanup
/// Replaces: /api/auth/password/cleanup, /api/auth/email/cleanup
/// Requires: SUPABASE_SERVICE_ROLE_KEY, CRON_SECRET
///
/// Scheduled cleanup of expired password reset tokens and email verifications.
/// Intended to be invoked by a Supabase cron trigger or external scheduler.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, handleCors } from "../_shared/cors.ts";

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    // Verify cron secret to prevent unauthorized invocations
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

    // Clean expired email verification tokens
    const { count: emailCount } = await supabase
      .from("email_verifications")
      .delete()
      .lt("expires_at", now);

    // Clean expired password reset tokens
    const { count: passwordCount } = await supabase
      .from("password_resets")
      .delete()
      .lt("expires_at", now);

    // Clean expired backup codes older than 90 days unused
    const ninetyDaysAgo = new Date(Date.now() - 90 * 86400_000).toISOString();
    const { count: backupCount } = await supabase
      .from("backup_codes")
      .delete()
      .eq("used", true)
      .lt("used_at", ninetyDaysAgo);

    return new Response(
      JSON.stringify({
        cleaned: {
          email_verifications: emailCount ?? 0,
          password_resets: passwordCount ?? 0,
          used_backup_codes: backupCount ?? 0,
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
