-- Create get_public_stats function (was missing from schema cache)
create or replace function public.get_public_stats()
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_users_total int;
  v_users_drivers int;
  v_users_passengers int;
  v_trips_total int;
  v_trips_completed int;
  v_trips_cancelled int;
  v_trips_today int;
  v_trips_week int;
  v_trips_month int;
  v_total_fare double precision;
  v_total_dist double precision;
  v_active_drivers int;
  v_available_now int;
  v_avg_rating double precision;
  v_ratings_total int;
  v_ref_total int;
  v_ref_successful int;
begin
  select count(*) into v_users_total from public.profiles;
  select count(*) into v_users_drivers from public.profiles where role = 'driver';
  select count(*) into v_users_passengers from public.profiles where role = 'passenger';
  select count(*) into v_trips_total from public.trips;
  select count(*) into v_trips_completed from public.trips where status = 'completed';
  select count(*) into v_trips_cancelled from public.trips where status = 'cancelled';
  select count(*) into v_trips_today from public.trips where created_at >= current_date;
  select count(*) into v_trips_week from public.trips where created_at >= now() - interval '7 days';
  select count(*) into v_trips_month from public.trips where created_at >= now() - interval '30 days';
  select coalesce(sum(total_fare), 0) into v_total_fare from public.trips where status = 'completed';
  select coalesce(sum(distance_km), 0) into v_total_dist from public.trips where status = 'completed';
  select count(*) into v_active_drivers from public.drivers;
  select count(*) into v_available_now from public.drivers where is_available = true;
  select coalesce(avg(score), 0) into v_avg_rating from public.ratings;
  select count(*) into v_ratings_total from public.ratings;
  select count(*) into v_ref_total from public.referrals;
  select count(*) into v_ref_successful from public.referrals where status in ('completed', 'rewarded');
  return json_build_object(
    'users', json_build_object('total', v_users_total, 'drivers', v_users_drivers, 'passengers', v_users_passengers),
    'trips', json_build_object('total', v_trips_total, 'completed', v_trips_completed, 'cancelled', v_trips_cancelled,
      'today', v_trips_today, 'this_week', v_trips_week, 'this_month', v_trips_month,
      'total_fare', v_total_fare, 'avg_fare', case when v_trips_completed > 0 then v_total_fare / v_trips_completed else 0 end,
      'total_distance_km', v_total_dist),
    'drivers', json_build_object('active', v_active_drivers, 'available_now', v_available_now),
    'ratings', json_build_object('avg_score', round(v_avg_rating::numeric, 1), 'total', v_ratings_total),
    'referrals', json_build_object('total', v_ref_total, 'successful', v_ref_successful)
  );
end;
$$;

grant execute on function public.get_public_stats to anon, authenticated;
