-- Enhance tracking: car info in drivers + passenger_end_trip RPC

alter table public.drivers add column if not exists car_plate text;
alter table public.drivers add column if not exists car_model text;
alter table public.drivers add column if not exists car_color text;

create or replace function public.passenger_end_trip(p_trip_id uuid)
returns json
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_trip record;
  v_driver_id uuid;
begin
  select id, passenger_id, driver_id, status into v_trip
  from public.trips
  where id = p_trip_id;

  if not found then
    return json_build_object('success', false, 'error', 'الرحلة غير موجودة');
  end if;

  if v_trip.passenger_id <> auth.uid() then
    return json_build_object('success', false, 'error', 'لا تملك صلاحية إنهاء هذه الرحلة');
  end if;

  if v_trip.status = 'completed' then
    return json_build_object('success', false, 'error', 'الرحلة منتهية بالفعل');
  end if;

  if v_trip.status not in ('assigned', 'started') then
    return json_build_object('success', false, 'error', 'لا يمكن إنهاء رحلة بهذه الحالة');
  end if;

  v_driver_id := v_trip.driver_id;

  update public.trips
  set status = 'completed',
      completed_at = now()
  where id = p_trip_id;

  update public.drivers
  set is_available = true
  where id = v_driver_id;

  return json_build_object('success', true);
end;
$$;

grant execute on function public.passenger_end_trip to authenticated;
