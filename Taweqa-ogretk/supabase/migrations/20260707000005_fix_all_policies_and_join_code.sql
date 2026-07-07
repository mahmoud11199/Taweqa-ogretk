-- Comprehensive fix: passenger RLS policies, join_code uniqueness, payment fixes

-- 1. Add UNIQUE constraint on trips.join_code
alter table if exists public.trips add constraint trips_join_code_key unique (join_code);

-- 2. RLS policies for passengers on ride_requests
drop policy if exists "Passengers can insert own requests" on public.ride_requests;
create policy "Passengers can insert own requests"
on public.ride_requests for insert to authenticated
with check (passenger_id = auth.uid());

drop policy if exists "Passengers can view own requests" on public.ride_requests;
create policy "Passengers can view own requests"
on public.ride_requests for select to authenticated
using (passenger_id = auth.uid());

drop policy if exists "Passengers can update own pending requests" on public.ride_requests;
create policy "Passengers can update own pending requests"
on public.ride_requests for update to authenticated
using (passenger_id = auth.uid() and status = 'pending')
with check (passenger_id = auth.uid());

-- 3. Add rescue policy: admins can do anything
drop policy if exists "Admins can manage ride_requests" on public.ride_requests;
create policy "Admins can manage ride_requests"
on public.ride_requests for all to authenticated
using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'))
with check (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

-- 4. Fix passenger_end_trip to process wallet payment automatically
create or replace function public.passenger_end_trip(p_trip_id uuid)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_trip record;
  v_fare numeric;
begin
  select * into v_trip from trips where id = p_trip_id and passenger_id = auth.uid();
  if not found then
    return json_build_object('success', false, 'error', 'الرحلة غير موجودة');
  end if;
  if v_trip.status = 'completed' then
    return json_build_object('success', false, 'error', 'الرحلة منتهية بالفعل');
  end if;
  update trips set status = 'completed', completed_at = now()
  where id = p_trip_id and status <> 'completed';
  v_fare := coalesce(v_trip.total_fare, 0);
  if v_trip.payment_method = 'wallet' and v_fare > 0 and (v_trip.payment_status is null or v_trip.payment_status = 'unpaid') then
    perform apply_wallet_charge(v_trip.passenger_id, -v_fare);
    perform apply_wallet_charge(v_trip.driver_id, v_fare);
    update trips set payment_status = 'paid_wallet' where id = p_trip_id;
  end if;
  update drivers set is_available = true where id = v_trip.driver_id;
  return json_build_object('success', true);
end;
$$;
