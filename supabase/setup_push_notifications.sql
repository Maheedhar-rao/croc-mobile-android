-- ============================================
-- CROC Mobile Push Notifications Setup
-- ============================================
--
-- STEP 1: Deploy the edge function
--   supabase functions deploy notify-response
--
-- STEP 2: Set secrets in Supabase dashboard (Edge Functions > Secrets):
--   ONESIGNAL_APP_ID = your OneSignal App ID
--   ONESIGNAL_REST_API_KEY = your OneSignal REST API Key
--
-- STEP 3: Create a Database Webhook in Supabase Dashboard:
--   Go to: Database > Webhooks > Create
--   Name: notify_response_push
--   Table: email_responses
--   Events: INSERT
--   Type: Supabase Edge Function
--   Function: notify-response
--
-- That's it. When a new row is inserted into email_responses
-- with response_type APPROVED/DECLINED/STIPS_REQUIRED,
-- the edge function sends a push notification via OneSignal
-- to the device tagged with the deal owner's email.
--
-- ============================================
-- ALTERNATIVE: If you prefer a pg_net HTTP trigger instead of webhooks:
-- ============================================

-- Option A: Use Supabase Dashboard Webhooks (recommended, no SQL needed)

-- Option B: Use pg_net extension (if you want pure SQL trigger)
-- Uncomment below if using pg_net:

/*
CREATE OR REPLACE FUNCTION notify_response_push()
RETURNS TRIGGER AS $$
DECLARE
  response_type TEXT;
BEGIN
  response_type := UPPER(COALESCE(NEW.response_type, ''));

  -- Only fire for offers, declines, stips
  IF response_type NOT LIKE '%APPROV%'
     AND response_type NOT LIKE '%DECLIN%'
     AND response_type NOT LIKE '%STIP%'
     AND response_type != 'OFFER'
     AND response_type != 'CTF'
     AND response_type != 'PASS'
  THEN
    RETURN NEW;
  END IF;

  -- Call the edge function via pg_net
  PERFORM net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/notify-response',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
    ),
    body := jsonb_build_object(
      'record', row_to_json(NEW)
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_notify_response_push
  AFTER INSERT ON email_responses
  FOR EACH ROW
  EXECUTE FUNCTION notify_response_push();
*/
