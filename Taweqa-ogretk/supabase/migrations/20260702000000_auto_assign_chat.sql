-- Auto-assign to nearest driver + trip chat + auto-cancel

-- 1. Add offered_to tracking to ride_requests
alter table if exists public.ride_requests
  add column if not exists offered_to uuid,
  add column if not exists offered_at timestamptz,
  add column if not exists offered_drivers jsonb default '[]'::jsonb;

create index if not exists idx_ride_requests_offered_to on public.ride_requests(offered_to);

-- 2. Function: find nearest available driver by haversine distance
create or replace function public.find_nearest_available_driver(
  pickup_lat double precision,
  pickup_lng double precision,
  exclude_ids uuid[] default '{}'
) returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  driver_record record;
begin
  select d.id, p.full_name,
    (6371 * acos(
      cos(radians(pickup_lat)) * cos(radians(d.current_lat)) *
      cos(radians(d.current_lng) - radians(pickup_lng)) +
      sin(radians(pickup_lat)) * sin(radians(d.current_lat))
    )) as distance_km
  into driver_record
  from drivers d
  join profiles p on p.id = d.id
  where d.is_available = true
    and d.current_lat is not null
    and d.current_lng is not null
    and d.id != all(coalesce(exclude_ids, '{}'))
    and (6371 * acos(
      cos(radians(pickup_lat)) * cos(radians(d.current_lat)) *
      cos(radians(d.current_lng) - radians(pickup_lng)) +
      sin(radians(pickup_lat)) * sin(radians(d.current_lat))
    )) < 10
  order by distance_km
  limit 1;

  if driver_record.id is null then
    return json_build_object('found', false);
  end if;

  return json_build_object(
    'found', true,
    'driver_id', driver_record.id,
    'driver_name', driver_record.full_name,
    'distance_km', round(driver_record.distance_km::numeric, 2)
  );
end;
$$;

-- 3. Trip chat messages table
create table if not exists public.trip_chat_messages (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  sender_role text not null check (sender_role in ('driver', 'passenger')),
  message text not null,
  created_at timestamptz default now()
);

create index if not exists idx_chat_trip_id on public.trip_chat_messages(trip_id, created_at);

alter table if exists public.trip_chat_messages enable row level security;

drop policy if exists "Users can read messages of their trips" on public.trip_chat_messages;
create policy "Users can read messages of their trips"
on public.trip_chat_messages for select
to authenticated
using (
  exists (
    select 1 from public.trips
    where id = trip_id and (driver_id = auth.uid() or passenger_id = auth.uid())
  )
);

drop policy if exists "Users can insert messages in their trips" on public.trip_chat_messages;
create policy "Users can insert messages in their trips"
on public.trip_chat_messages for insert
to authenticated
with check (
  sender_id = auth.uid()
  and exists (
    select 1 from public.trips
    where id = trip_id and (driver_id = auth.uid() or passenger_id = auth.uid())
  )
);

-- 4. Update ride_requests RLS: drivers only see offered requests
drop policy if exists "Drivers can view pending requests" on public.ride_requests;
create policy "Drivers can view pending requests"
on public.ride_requests for select
to authenticated
using (
  status = 'pending'
  and driver_id is null
  and offered_to = auth.uid()
  and exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'driver'
  )
);

-- 5. Update accept policy to require offered_to match
drop policy if exists "Drivers can accept pending requests" on public.ride_requests;
create policy "Drivers can accept pending requests"
on public.ride_requests for update
to authenticated
using (status='pending' and driver_id is null and offered_to=auth.uid() and exists(select 1 from public.profiles where id=auth.uid() and role='driver'))
with check (driver_id=auth.uid());

-- 6. Add duration_price_used to trips for detailed receipt
alter table if exists public.trips add column if not exists duration_price_used double precision default 0.5;
