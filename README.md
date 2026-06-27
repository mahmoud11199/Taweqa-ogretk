# Taweqa-ogretk
​الفكرة العامة: تطبيق يتيح للمستخدمين (أو المناديب والعملاء) حساب وتوقع تكلفة مشوار التوصيل أو الرحلة بدقة قبل البدء أو أثناء الرحلة بناءً على مسار الـ GPS الفعلي، مما يضمن شفافية كاملة في التسعير.

## Production hardening

The app includes Supabase production hardening assets:

- `supabase/migrations/20260627000000_harden_trip_security.sql` adds trip audit tables, live location tables, driver applications, indexes, and RLS policies.
- `supabase/functions/trip-events/index.ts` centralizes start/sync/complete trip writes through a Supabase Edge Function instead of writing trip state directly from the browser.

Deploy order:

1. Apply the migration in Supabase SQL editor or via the Supabase CLI.
2. Deploy the Edge Function named `trip-events`.
3. Ensure the Edge Function has access to `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY`.
