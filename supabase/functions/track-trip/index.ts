import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return jsonResponse({ error: 'Method not allowed' }, 405);

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const authHeader = req.headers.get('Authorization') || '';
  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse({ error: 'Server is not configured' }, 500);
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: authData, error: authError } = await admin.auth.getUser(
    authHeader.replace('Bearer ', ''),
  );
  if (authError || !authData.user) return jsonResponse({ error: 'Unauthorized' }, 401);

  const body = await req.json().catch(() => null) as { code?: string } | null;
  const code = String(body?.code || '').replace(/\D/g, '').slice(0, 6);
  if (code.length < 4) return jsonResponse({ error: 'Invalid tracking code' }, 400);

  const { data: trips, error: tripError } = await admin
    .from('trips')
    .select('id, status, driver_id, total_fare, distance_km, duration_min, wait_minutes, classification, passenger_count, join_code, created_at, last_lat, last_lng')
    .eq('join_code', code)
    .order('created_at', { ascending: false })
    .limit(1);

  if (tripError) return jsonResponse({ error: tripError.message }, 400);
  if (!trips?.length) return jsonResponse({ error: 'Trip not found' }, 404);

  const trip = trips[0];
  const { data: driver } = await admin
    .from('profiles')
    .select('full_name')
    .eq('id', trip.driver_id)
    .single();

  const { data: locations } = await admin
    .from('trip_locations')
    .select('lat, lng, created_at')
    .eq('trip_id', String(trip.id))
    .order('created_at', { ascending: true })
    .limit(200);

  return jsonResponse({
    trip: {
      status: trip.status,
      driver_name: driver?.full_name || 'سائق',
      total_fare: trip.total_fare,
      distance_km: trip.distance_km,
      duration_min: trip.duration_min,
      wait_minutes: trip.wait_minutes,
      classification: trip.classification,
      passenger_count: trip.passenger_count,
      join_code: trip.join_code,
      last_lat: trip.last_lat,
      last_lng: trip.last_lng,
    },
    locations: locations || [],
  });
});
