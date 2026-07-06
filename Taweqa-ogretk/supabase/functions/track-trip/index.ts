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

  const body = await req.json().catch(() => null) as { code?: string; trip_id?: string; include_driver_location?: boolean } | null;
  let query = admin.from('trips').select('id, status, driver_id, passenger_id, total_fare, distance_km, duration_min, wait_minutes, classification, passenger_count, join_code, created_at, last_lat, last_lng, waypoints, completed_at');

  if (body?.trip_id) {
    query = query.eq('id', body.trip_id);
  } else {
    const code = String(body?.code || '').replace(/\D/g, '').slice(0, 6);
    if (code.length < 4) return jsonResponse({ error: 'Invalid tracking code' }, 400);
    query = query.eq('join_code', code);
  }

  const { data: trips, error: tripError } = await query.order('created_at', { ascending: false }).limit(1);

  if (tripError) return jsonResponse({ error: tripError.message }, 400);
  if (!trips?.length) return jsonResponse({ error: 'Trip not found' }, 404);

  const trip = trips[0];

  // Driver profile + car info
  let driverInfo: Record<string, unknown> = { full_name: 'سائق', phone: null, avatar_url: null, car_plate: null, car_model: null, car_color: null, avg_rating: null, total_ratings: 0, current_lat: null, current_lng: null };
  if (trip.driver_id) {
    const { data: profile } = await admin
      .from('profiles')
      .select('full_name, phone, avatar_url')
      .eq('id', trip.driver_id)
      .single();
    if (profile) {
      driverInfo.full_name = profile.full_name || 'سائق';
      driverInfo.phone = profile.phone;
      driverInfo.avatar_url = profile.avatar_url;
    }

    const { data: driverRow } = await admin
      .from('drivers')
      .select('car_plate, car_model, car_color, current_lat, current_lng')
      .eq('id', trip.driver_id)
      .single();
    if (driverRow) {
      driverInfo.car_plate = driverRow.car_plate;
      driverInfo.car_model = driverRow.car_model;
      driverInfo.car_color = driverRow.car_color;
      driverInfo.current_lat = driverRow.current_lat;
      driverInfo.current_lng = driverRow.current_lng;
    }

    const { data: ratingAgg } = await admin
      .from('ratings')
      .select('score')
      .eq('driver_id', trip.driver_id);
    if (ratingAgg && ratingAgg.length > 0) {
      const sum = ratingAgg.reduce((a: number, r: { score: number }) => a + r.score, 0);
      driverInfo.avg_rating = Math.round((sum / ratingAgg.length) * 10) / 10;
      driverInfo.total_ratings = ratingAgg.length;
    }
  }

  const { data: locations } = await admin
    .from('trip_locations')
    .select('lat, lng, created_at')
    .eq('trip_id', String(trip.id))
    .order('created_at', { ascending: true })
    .limit(200);

  return jsonResponse({
    trip_id: trip.id,
    driver_id: trip.driver_id,
    passenger_id: trip.passenger_id,
    trip: {
      id: trip.id,
      status: trip.status,
      driver_id: trip.driver_id,
      passenger_id: trip.passenger_id,
      driver_name: driverInfo.full_name as string,
      total_fare: trip.total_fare,
      distance_km: trip.distance_km,
      duration_min: trip.duration_min,
      wait_minutes: trip.wait_minutes,
      classification: trip.classification,
      passenger_count: trip.passenger_count,
      join_code: trip.join_code,
      last_lat: trip.last_lat,
      last_lng: trip.last_lng,
      waypoints: trip.waypoints,
      completed_at: trip.completed_at,
    },
    driver: driverInfo,
    locations: locations || [],
  });
});
