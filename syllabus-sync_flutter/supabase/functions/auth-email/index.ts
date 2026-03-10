/// Edge Function: auth-email
/// Replaces: /api/auth/email/send-verification, resend-verification, verify
/// Requires: RESEND_API_KEY, SUPABASE_SERVICE_ROLE_KEY
///
/// Handles email verification flows that need server-side Resend API key.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, handleCors } from "../_shared/cors.ts";

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { action, email, token } = await req.json();

    switch (action) {
      case "send-verification": {
        // Generate verification token and store in email_verifications table
        const code = crypto.randomUUID().slice(0, 8).toUpperCase();
        const { error: dbError } = await supabase
          .from("email_verifications")
          .insert({ email, token: code, expires_at: new Date(Date.now() + 3600_000).toISOString() });

        if (dbError) throw dbError;

        // Send email via Resend
        const resendKey = Deno.env.get("RESEND_API_KEY");
        const fromEmail = Deno.env.get("VERIFICATION_EMAIL_FROM") ?? "noreply@syllabussync.io";
        const res = await fetch("https://api.resend.com/emails", {
          method: "POST",
          headers: { Authorization: `Bearer ${resendKey}`, "Content-Type": "application/json" },
          body: JSON.stringify({
            from: fromEmail,
            to: email,
            subject: "Verify your Syllabus Sync email",
            html: `<p>Your verification code is: <strong>${code}</strong></p><p>This code expires in 1 hour.</p>`,
          }),
        });

        if (!res.ok) throw new Error(`Resend API error: ${res.status}`);

        return new Response(JSON.stringify({ sent: true }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      case "resend-verification": {
        // Delete old tokens and resend
        await supabase.from("email_verifications").delete().eq("email", email);
        // Recursively call send-verification logic
        const code = crypto.randomUUID().slice(0, 8).toUpperCase();
        const { error: dbError } = await supabase
          .from("email_verifications")
          .insert({ email, token: code, expires_at: new Date(Date.now() + 3600_000).toISOString() });

        if (dbError) throw dbError;

        const resendKey = Deno.env.get("RESEND_API_KEY");
        const fromEmail = Deno.env.get("VERIFICATION_EMAIL_FROM") ?? "noreply@syllabussync.io";
        const res = await fetch("https://api.resend.com/emails", {
          method: "POST",
          headers: { Authorization: `Bearer ${resendKey}`, "Content-Type": "application/json" },
          body: JSON.stringify({
            from: fromEmail,
            to: email,
            subject: "Verify your Syllabus Sync email",
            html: `<p>Your verification code is: <strong>${code}</strong></p><p>This code expires in 1 hour.</p>`,
          }),
        });

        if (!res.ok) throw new Error(`Resend API error: ${res.status}`);

        return new Response(JSON.stringify({ sent: true }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      case "verify": {
        // Validate token against email_verifications table
        const { data, error } = await supabase
          .from("email_verifications")
          .select()
          .eq("email", email)
          .eq("token", token)
          .gt("expires_at", new Date().toISOString())
          .single();

        if (error || !data) {
          return new Response(JSON.stringify({ verified: false, error: "Invalid or expired code" }), {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          });
        }

        // Mark email as verified via admin API
        const { data: users } = await supabase.auth.admin.listUsers();
        const user = users.users.find((u) => u.email === email);
        if (user) {
          await supabase.auth.admin.updateUserById(user.id, { email_confirm: true });
        }

        // Clean up used token
        await supabase.from("email_verifications").delete().eq("email", email);

        return new Response(JSON.stringify({ verified: true }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      default:
        return new Response(JSON.stringify({ error: `Unknown action: ${action}` }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
    }
  } catch (err) {
    return new Response(JSON.stringify({ error: (err as Error).message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
