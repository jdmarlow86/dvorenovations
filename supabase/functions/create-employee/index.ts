// Supabase Edge Function: create-employee
// Deploy with: supabase functions deploy create-employee
// Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY as function secrets.
// The service-role key must NEVER be placed in index.html or GitHub.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405, headers: cors });

  const url = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const authHeader = req.headers.get("Authorization") || "";
  const admin = createClient(url, serviceKey);
  const callerClient = createClient(url, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: authHeader } },
  });

  try {
    const { data: { user }, error: authError } = await callerClient.auth.getUser();
    if (authError || !user) return new Response(JSON.stringify({ error: "Sign in required." }), { status: 401, headers: { ...cors, "Content-Type": "application/json" } });

    const { data: caller, error: profileError } = await admin.from("profiles")
      .select("role,active").eq("id", user.id).single();
    if (profileError || caller?.role !== "employer" || caller?.active !== true) {
      return new Response(JSON.stringify({ error: "Employer access required." }), { status: 403, headers: { ...cors, "Content-Type": "application/json" } });
    }

    const body = await req.json();
    const username = String(body.username || "").trim().toLowerCase();
    const displayName = String(body.name || "").trim();
    const password = String(body.password || "");
    if (!/^[a-z0-9._-]{3,32}$/.test(username) || !displayName || password.length < 8) {
      return new Response(JSON.stringify({ error: "Use a 3–32 character username (letters, numbers, . _ -), a name, and a password of at least 8 characters." }), { status: 400, headers: { ...cors, "Content-Type": "application/json" } });
    }

    const email = username + "@vanornumrenovations.com";
    const { data: existing } = await admin.from("profiles").select("id").eq("username", username).maybeSingle();
    if (existing) return new Response(JSON.stringify({ error: "That username is already in use." }), { status: 409, headers: { ...cors, "Content-Type": "application/json" } });

    const { data: created, error: createError } = await admin.auth.admin.createUser({
      email, password, email_confirm: true,
      user_metadata: { username, display_name: displayName, role: "employee" },
    });
    if (createError || !created.user) throw createError || new Error("Could not create employee.");
    const { error: insertError } = await admin.from("profiles").insert({
      id: created.user.id, username, display_name: displayName, role: "employee",
      active: true, must_change_password: true,
    });
    if (insertError) {
      await admin.auth.admin.deleteUser(created.user.id);
      throw insertError;
    }
    return new Response(JSON.stringify({ id: created.user.id, username, name: displayName }), { status: 200, headers: { ...cors, "Content-Type": "application/json" } });
  } catch (error) {
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : "Unexpected server error." }), { status: 400, headers: { ...cors, "Content-Type": "application/json" } });
  }
});
