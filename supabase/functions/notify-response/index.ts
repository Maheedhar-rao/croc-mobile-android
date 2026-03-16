// Supabase Edge Function: notify-response
// Triggered by database webhook on email_responses INSERT
// Sends push notification via OneSignal for offers, declines, and stips

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const ONESIGNAL_APP_ID = Deno.env.get("ONESIGNAL_APP_ID")!;
const ONESIGNAL_REST_API_KEY = Deno.env.get("ONESIGNAL_REST_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

serve(async (req) => {
  try {
    const payload = await req.json();
    const record = payload.record;

    if (!record) {
      return new Response(JSON.stringify({ error: "No record" }), { status: 400 });
    }

    // Only notify on offers, declines, stips
    const responseType = (record.response_type || "").toUpperCase();
    const isOffer = responseType.includes("APPROV") || responseType === "OFFER" || responseType === "CTF";
    const isDecline = responseType.includes("DECLIN") || responseType === "PASS";
    const isStips = responseType.includes("STIP");

    if (!isOffer && !isDecline && !isStips) {
      return new Response(JSON.stringify({ skipped: true, reason: "Not offer/decline/stips" }), { status: 200 });
    }

    const dealId = record.deal_id;
    const lenderName = record.lender_name || record.from_email || "A lender";

    // Look up the deal owner (user_id) to target the push
    const dealRes = await fetch(
      `${SUPABASE_URL}/rest/v1/deals?id=eq.${dealId}&select=user_id,business_name,subject`,
      {
        headers: {
          "apikey": SUPABASE_SERVICE_ROLE_KEY,
          "Authorization": `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        },
      }
    );
    const deals = await dealRes.json();
    if (!deals || deals.length === 0) {
      return new Response(JSON.stringify({ error: "Deal not found" }), { status: 404 });
    }

    const deal = deals[0];
    const userEmail = deal.user_id;
    const businessName = deal.business_name || deal.subject || `Deal #${dealId}`;

    if (!userEmail) {
      return new Response(JSON.stringify({ error: "No user_id on deal" }), { status: 400 });
    }

    // Build notification
    let heading = "";
    let content = "";

    if (isOffer) {
      heading = `${lenderName} — OFFER`;
      content = `${businessName} received an offer!`;
    } else if (isDecline) {
      heading = `${lenderName} — DECLINED`;
      content = `${businessName} was declined.`;
    } else if (isStips) {
      heading = `${lenderName} — STIPS REQUESTED`;
      content = `${businessName} has stips requested.`;
    }

    // Send via OneSignal — target by user_email tag
    const osResponse = await fetch("https://onesignal.com/api/v1/notifications", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Basic ${ONESIGNAL_REST_API_KEY}`,
      },
      body: JSON.stringify({
        app_id: ONESIGNAL_APP_ID,
        filters: [
          { field: "tag", key: "user_email", value: userEmail },
        ],
        headings: { en: heading },
        contents: { en: content },
        data: {
          deal_id: dealId,
          response_type: responseType,
          lender_name: lenderName,
        },
      }),
    });

    const osResult = await osResponse.json();
    console.log("OneSignal response:", JSON.stringify(osResult));

    return new Response(
      JSON.stringify({ success: true, notification: heading, target: userEmail }),
      { status: 200 }
    );
  } catch (err) {
    console.error("Error:", err);
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
});
