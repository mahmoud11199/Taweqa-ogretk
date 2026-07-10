-- Add 'arrived' and 'ongoing' statuses to trips
alter table public.trips drop constraint if exists trips_status_check;
alter table public.trips add constraint trips_status_check
  check (status in ('assigned', 'arrived', 'ongoing', 'started', 'completed', 'cancelled'));

-- Update passenger_end_trip to accept new statuses
create or replace function public.passenger_end_trip(p_trip_id uuid)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_trip record;
  v_fare numeric;
  v_deduct json;
begin
  select * into v_trip from trips where id = p_trip_id and passenger_id = auth.uid();
  if not found then
    return json_build_object('success', false, 'error', 'لا توجد رحلة بهذا المعرف');
  end if;
  if v_trip.status not in ('assigned', 'arrived', 'ongoing', 'started') then
    return json_build_object('success', false, 'error', 'الرحلة غير نشطة ولا يمكن إنهاؤها');
  end if;
  update trips set status = 'completed', completed_at = now()
  where id = p_trip_id and status <> 'completed';
  v_fare := coalesce(v_trip.total_fare, 0);
  if v_trip.payment_method = 'wallet' and v_fare > 0 and (v_trip.payment_status is null or v_trip.payment_status = 'unpaid') then
    select apply_wallet_charge(v_trip.passenger_id, -v_fare) into v_deduct;
    if (v_deduct->>'success')::boolean then
      perform apply_wallet_charge(v_trip.driver_id, v_fare);
      update trips set payment_status = 'paid_wallet' where id = p_trip_id;
    end if;
  end if;
  update drivers set is_available = true where id = v_trip.driver_id;
  return json_build_object('success', true);
end;
$$;

-- Update sync_active_trips_count to include new statuses
create or replace function public.sync_active_trips_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    update public.drivers set active_trips_count = (
      select count(*)::int from public.trips where driver_id = new.driver_id and status IN ('assigned', 'arrived', 'ongoing', 'started')
    ) where id = new.driver_id;
    return new;
  elsif tg_op = 'DELETE' then
    update public.drivers set active_trips_count = (
      select count(*)::int from public.trips where driver_id = old.driver_id and status IN ('assigned', 'arrived', 'ongoing', 'started')
    ) where id = old.driver_id;
    return old;
  else
    update public.drivers set active_trips_count = (
      select count(*)::int from public.trips where driver_id = new.driver_id and status IN ('assigned', 'arrived', 'ongoing', 'started')
    ) where id = new.driver_id;
    return new;
  end if;
end;
$$;
