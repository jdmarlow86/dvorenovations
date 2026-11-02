// Username-based Supabase Auth login.
// The private alias table is read only by this server-side function.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const reply = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return reply({ error: "Method not allowed." }, 405);

  try {
    const url = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    if (!url || !serviceKey || !anonKey) return reply({ error: "Login service is not configured." }, 500);

    const body = await req.json();
    const username = String(body.username || "").trim().toLowerCase();
    const password = String(body.password || "");
    if (!/^[a-z0-9._-]{3,32}$/.test(username) || !password || password.length > 256) {
      return reply({ error: "Username or password is incorrect." }, 401);
    }

    const admin = createClient(url, serviceKey, { auth: { persistSession: false } });
    const { data: alias } = await admin.from("auth_login_aliases")
      .select("auth_email").eq("username", username).maybeSingle();

    // Use the same outward error for unknown usernames and incorrect passwords.
    if (!alias?.auth_email) return reply({ error: "Username or password is incorrect." }, 401);

    const authResponse = await fetch(url + "/auth/v1/token?grant_type=password", {
      method: "POST",
      headers: { "Content-Type": "application/json", apikey: anonKey },
      body: JSON.stringify({ email: alias.auth_email, password }),
    });
    const authData = await authResponse.json();
    if (!authResponse.ok || !authData.access_token || !authData.refresh_token) {
      return reply({ error: "Username or password is incorrect." }, 401);
    }

    return reply({
      access_token: authData.access_token,
      refresh_token: authData.refresh_token,
      token_type: authData.token_type,
      expires_in: authData.expires_in,
      user: authData.user,
    });
  } catch {
    return reply({ error: "Login could not be completed. Please try again." }, 500);
  }
});
