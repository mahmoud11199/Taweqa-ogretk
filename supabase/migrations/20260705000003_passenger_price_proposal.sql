-- Phase 2: Passenger price proposal
alter table if exists public.trips
  add column if not exists passenger_proposed_fare double precision,
  add column if not exists passenger_adjustment_note text,
  add column if not exists passenger_price_accepted boolean default false;

-- Passenger proposes a new price
create or replace function public.propose_trip_price(p_trip_id uuid, p_proposed_fare double precision, p_note text default '')
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_trip record;
begin
  select * into v_trip from public.trips where id = p_trip_id;
  if not found then
    return json_build_object('success', false, 'error', 'Trip not found');
  end if;
  if v_trip.passenger_id <> auth.uid() then
    return json_build_object('success', false, 'error', 'Not your trip');
  end if;
  if p_proposed_fare < 0 or p_proposed_fare > 100000 then
    return json_build_object('success', false, 'error', 'Invalid fare amount');
  end if;

  update public.trips
  set passenger_proposed_fare = p_proposed_fare,
      passenger_adjustment_note = p_note,
      passenger_price_accepted = false
  where id = p_trip_id;

  insert into public.trip_events (trip_id, actor_id, event_type, payload)
  values (p_trip_id::text, auth.uid(), 'price_proposed',
    jsonb_build_object('proposed_fare', p_proposed_fare, 'note', p_note));

  return json_build_object('success', true);
end;
$$;

-- Driver accepts passenger's proposed price
create or replace function public.accept_passenger_price(p_trip_id uuid)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_trip record;
begin
  select * into v_trip from public.trips where id = p_trip_id;
  if not found then
    return json_build_object('success', false, 'error', 'Trip not found');
  end if;
  if v_trip.driver_id <> auth.uid() then
    return json_build_object('success', false, 'error', 'Not your trip');
  end if;
  if v_trip.passenger_proposed_fare is null then
    return json_build_object('success', false, 'error', 'No pending proposal');
  end if;

  update public.trips
  set total_fare = passenger_proposed_fare,
      passenger_proposed_fare = null,
      passenger_adjustment_note = null,
      passenger_price_accepted = true,
      price_adjusted = true
  where id = p_trip_id;

  insert into public.trip_events (trip_id, actor_id, event_type, payload)
  values (p_trip_id::text, auth.uid(), 'passenger_price_accepted',
    jsonb_build_object('final_fare', v_trip.passenger_proposed_fare));

  return json_build_object('success', true, 'new_fare', v_trip.passenger_proposed_fare);
end;
$$;

-- Driver rejects passenger's proposed price
create or replace function public.reject_passenger_price(p_trip_id uuid)
returns json
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.trips
  set passenger_proposed_fare = null,
      passenger_adjustment_note = null
  where id = p_trip_id and driver_id = auth.uid();

  insert into public.trip_events (trip_id, actor_id, event_type, payload)
  values (p_trip_id::text, auth.uid(), 'passenger_price_rejected', '{}'::jsonb);

  return json_build_object('success', true);
end;
$$;

-- Add new event types to trip_events check constraint
alter table if exists public.trip_events drop constraint if exists trip_events_event_type_check;
alter table if exists public.trip_events add constraint trip_events_event_type_check
  check (event_type in ('started', 'location', 'pause', 'resume', 'passenger_joined',
    'passenger_left', 'manual_distance', 'completed', 'cancelled', 'price_adjusted',
    'price_proposed', 'passenger_price_accepted', 'passenger_price_rejected'));
