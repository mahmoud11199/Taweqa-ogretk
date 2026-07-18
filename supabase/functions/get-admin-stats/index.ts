import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Authorization, Content-Type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  const authHeader = req.headers.get('Authorization') || '';
  const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

  const authClient = createClient(supabaseUrl, serviceRoleKey, {
    global: { headers: { Authorization: authHeader } },
  });

  try {
    const { data: { user } } = await authClient.auth.getUser(authHeader.replace('Bearer ', ''));
    if (!user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey);
    const { data: profile } = await adminClient
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single();

    if (profile?.role !== 'admin') {
      return new Response(
        JSON.stringify({ error: 'Forbidden' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const [drivers, passengers, activeTrips, completedTrips, pendingApps, revenue] =
      await Promise.all([
        adminClient.from('drivers').select('id', { count: 'exact', head: true }),
        adminClient.from('profiles').select('id', { count: 'exact', head: true }).eq('role', 'passenger'),
        adminClient.from('trips').select('id', { count: 'exact', head: true }).eq('status', 'active'),
        adminClient.from('trips').select('id', { count: 'exact', head: true }).eq('status', 'completed'),
        adminClient.from('driver_applications').select('id', { count: 'exact', head: true }).eq('status', 'pending'),
        adminClient.from('trips').select('driver_cut').eq('status', 'completed'),
      ]);

    const totalRevenue = (revenue.data || []).reduce(
      (sum: number, t: any) => sum + (t.driver_cut || 0), 0,
    );

    const availableDrivers = await adminClient
      .from('drivers')
      .select('id', { count: 'exact', head: true })
      .eq('is_available', true);

    return new Response(
      JSON.stringify({
        total_drivers: drivers.count || 0,
        available_drivers: availableDrivers.count || 0,
        total_passengers: passengers.count || 0,
        active_trips: activeTrips.count || 0,
        completed_trips: completedTrips.count || 0,
        pending_applications: pendingApps.count || 0,
        total_revenue: totalRevenue,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : 'Unknown error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
