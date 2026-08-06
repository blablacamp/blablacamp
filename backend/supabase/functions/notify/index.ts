// Supabase Edge Function: notify
//
// Sends a notification through OneSignal (push + optional email) to one or more
// users, targeted by their external id (which the app sets to the Supabase
// user id via OneSignal.login).
//
// Secrets (set with `supabase secrets set ...`):
//   ONESIGNAL_APP_ID        — your OneSignal app id
//   ONESIGNAL_REST_API_KEY  — OneSignal REST API key (SERVER SIDE ONLY)
//
// Request body:
//   {
//     "userIds": ["<supabase-uuid>", ...],   // external ids to target
//     "title":   "Нова заявка",
//     "message": "Тарас хоче приєднатися до «Говерла на світанку»",
//     "email":   false,                       // also send via email channel
//     "data":    { "hikeId": "..." }          // optional deep-link payload
//   }
//
// Typical caller: a Postgres trigger / webhook on hike_participants insert, or
// the client right after a successful join request.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const ONESIGNAL_APP_ID = Deno.env.get("ONESIGNAL_APP_ID");
const ONESIGNAL_REST_API_KEY = Deno.env.get("ONESIGNAL_REST_API_KEY");

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface NotifyBody {
  userIds: string[];
  title: string;
  message: string;
  email?: boolean;
  data?: Record<string, unknown>;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (!ONESIGNAL_APP_ID || !ONESIGNAL_REST_API_KEY) {
    return json({ error: "OneSignal secrets are not configured" }, 500);
  }

  let body: NotifyBody;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const { userIds, title, message, email, data } = body;
  if (!Array.isArray(userIds) || userIds.length === 0 || !title || !message) {
    return json({ error: "userIds, title and message are required" }, 400);
  }

  const channels = email ? ["push", "email"] : ["push"];

  const payload = {
    app_id: ONESIGNAL_APP_ID,
    include_aliases: { external_id: userIds },
    target_channel: undefined as unknown, // set per request below
    headings: { en: title, uk: title },
    contents: { en: message, uk: message },
    data: data ?? {},
  };

  // OneSignal wants one request per channel when using include_aliases.
  const results: Record<string, unknown> = {};
  for (const channel of channels) {
    const res = await fetch("https://api.onesignal.com/notifications", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Key ${ONESIGNAL_REST_API_KEY}`,
      },
      body: JSON.stringify({ ...payload, target_channel: channel }),
    });
    results[channel] = await res.json();
  }

  return json({ ok: true, results }, 200);
});

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
