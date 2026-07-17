// Supabase Edge Function: get-admin-stats
// Returns admin dashboard statistics (alternative to DB RPC)

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req) => {
  const authHeader = req.headers.get('Authorization') || '';
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') || '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '',
    { global: { headers: { Authorization: authHeader } } },
  );

  try {
    // Verify admin
    const { data: { user } } = await supabase.auth.getUser(authHeader.replace('Bearer ', ''));
    if (!user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
    }

    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single();

    if (profile?.role !== 'admin') {
      return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403 });
    }

    const [drivers, passengers, activeTrips, completedTrips, pendingApps, revenue] =
      await Promise.all([
        supabase.from('drivers').select('id', { count: 'exact', head: true }),
        supabase.from('profiles').select('id', { count: 'exact', head: true }).eq('role', 'passenger'),
        supabase.from('trips').select('id', { count: 'exact', head: true }).eq('status', 'active'),
        supabase.from('trips').select('id', { count: 'exact', head: true }).eq('status', 'completed'),
        supabase.from('driver_applications').select('id', { count: 'exact', head: true }).eq('status', 'pending'),
        supabase.from('trips').select('driver_cut').eq('status', 'completed'),
      ]);

    const totalRevenue = (revenue.data || []).reduce(
      (sum: number, t: any) => sum + (t.driver_cut || 0), 0,
    );

    const availableDrivers = await supabase
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
      { headers: { 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : 'Unknown error' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
});
