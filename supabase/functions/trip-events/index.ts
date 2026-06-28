import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

type TripAction = 'start' | 'sync' | 'complete';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function clampNumber(value: unknown, min: number, max: number, fallback: number): number {
  const n = Number(value);
  if (!Number.isFinite(n)) return fallback;
  return Math.min(max, Math.max(min, n));
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function parsePassengers(value: unknown): Array<Record<string, unknown>> {
  return Array.isArray(value) ? value as Array<Record<string, unknown>> : [];
}

function calculateServerFare(meter: Record<string, unknown>): number {
  const tripType = meter.tripType === 'makhsoos' ? 'makhsoos' : 'afrad';
  const bandira = clampNumber(meter.bandira, 0, 1000, 5);
  const minFare = clampNumber(meter.minFare, 0, 1000, 10);
  const totalDistance = clampNumber(meter.totalDistance, 0, 1000, 0);
  const totalDurationMinutes = clampNumber(meter.totalDurationMinutes, 0, 1440, 0);
  const totalWaitMinutes = clampNumber(Number(meter.totalWaitSeconds) / 60, 0, 1440, 0);
  const kmPrice = clampNumber(meter.kmPrice, 1, 50, 5);
  const durationPrice = clampNumber(meter.durationPrice, 0, 10, 0.5);
  const waitPrice = clampNumber(meter.waitPrice, 0, 20, 1);

  if (tripType === 'makhsoos') {
    const total = bandira + (totalDistance * kmPrice) +
      (totalDurationMinutes * durationPrice) + (totalWaitMinutes * waitPrice);
    return clampNumber(Math.max(minFare, total), 0, 100000, 0);
  }

  const passengers = parsePassengers(meter.passengersData);
  const totalRevenue = passengers.reduce((sum, passenger) => {
    const startDistance = clampNumber(passenger.startDistance, 0, 1000, 0);
    const passengerDistance = Math.max(0, totalDistance - startDistance);
    const isInside = passenger.isInside !== false;
    const isInitial = passenger.isInitial !== false;
    if (!isInside) return sum + clampNumber(passenger.individualFare, 0, 100000, 0);
    if (!isInitial) return sum + (passengerDistance * kmPrice);

    const passengerDuration = Math.max(
      0,
      totalDurationMinutes - clampNumber(passenger.startDuration, 0, 1440, 0),
    );
    const passengerWait = Math.max(
      0,
      totalWaitMinutes - clampNumber(passenger.startWait, 0, 1440, 0),
    );
    return sum + bandira + (passengerDistance * kmPrice) +
      (passengerDuration * durationPrice) + (passengerWait * waitPrice);
  }, 0);
  return clampNumber(totalRevenue, 0, 100000, 0);
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

  const body = await req.json().catch(() => null) as {
    action?: TripAction;
    tripId?: string | null;
    meter?: Record<string, unknown>;
    location?: { lat?: number; lng?: number; accuracy?: number; speedKmh?: number };
  } | null;

  if (!body?.action || !body.meter) return jsonResponse({ error: 'Invalid payload' }, 400);

  const userId = authData.user.id;
  const meter = body.meter;
  const status = body.action === 'complete' ? 'completed' : 'started';
  const serverFare = calculateServerFare(meter);
  const payload = {
    driver_id: userId,
    status,
    classification: meter.tripType === 'makhsoos' ? 'private' : 'shared',
    distance_km: clampNumber(meter.totalDistance, 0, 1000, 0),
    duration_min: clampNumber(meter.totalDurationMinutes, 0, 1440, 0),
    wait_minutes: clampNumber(Number(meter.totalWaitSeconds) / 60, 0, 1440, 0),
    total_fare: serverFare,
    meter_start_fee: clampNumber(meter.bandira, 0, 1000, 5),
    km_price_used: clampNumber(meter.kmPrice, 1, 50, 5),
    wait_price_used: clampNumber(meter.waitPrice, 0, 20, 1),
    join_code: String(meter.shareCode || ''),
    passenger_count: Math.round(clampNumber(meter.passengerCount, 0, 20, 1)),
    passenger_breakdown: JSON.stringify(meter.passengersData || []),
    completed_at: body.action === 'complete' ? new Date().toISOString() : null,
    last_synced_at: new Date().toISOString(),
    last_lat: body.location?.lat ?? null,
    last_lng: body.location?.lng ?? null,
    server_calculated: true,
  };

  let tripId = body.tripId || null;
  if (body.action === 'start') {
    const { data, error } = await admin.from('trips').insert(payload).select('id').single();
    if (error) return jsonResponse({ error: error.message }, 400);
    tripId = data.id;
  } else {
    if (!tripId) return jsonResponse({ error: 'tripId is required' }, 400);
    const updatePayload = { ...payload };
    delete (updatePayload as Partial<typeof updatePayload>).driver_id;
    const { error } = await admin
      .from('trips')
      .update(updatePayload)
      .eq('id', tripId)
      .eq('driver_id', userId);
    if (error) return jsonResponse({ error: error.message }, 400);
  }

  await admin.from('trip_events').insert({
    trip_id: String(tripId),
    actor_id: userId,
    event_type: body.action === 'complete' ? 'completed' : body.action === 'start' ? 'started' : 'location',
    payload: { meter, serverFare, location: body.location || null },
  });

  if (body.location?.lat != null && body.location?.lng != null) {
    await admin.from('trip_locations').insert({
      trip_id: String(tripId),
      actor_id: userId,
      lat: clampNumber(body.location.lat, -90, 90, 0),
      lng: clampNumber(body.location.lng, -180, 180, 0),
      accuracy_m: body.location.accuracy == null ? null : clampNumber(body.location.accuracy, 0, 500, 0),
      speed_kmh: body.location.speedKmh == null ? null : clampNumber(body.location.speedKmh, 0, 120, 0),
    });
  }

  return jsonResponse({ tripId });
});
