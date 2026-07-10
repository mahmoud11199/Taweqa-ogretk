-- ============================================================
--  Consolidated migration: remaining schema changes
--  All statements use IF NOT EXISTS / DROP ... IF EXISTS
-- ============================================================

-- 1. Add 'arrived' and 'ongoing' to trips status (safe drop+recreate)
alter table public.trips drop constraint if exists trips_status_check;
alter table public.trips add constraint trips_status_check
  check (status in ('assigned', 'arrived', 'ongoing', 'started', 'completed', 'cancelled'));

-- 2. Update passenger_end_trip to accept new statuses
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

-- 3. Update sync_active_trips_count to include new statuses
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

-- 4. Create scheduled_trips table
create table if not exists public.scheduled_trips (
  id uuid primary key default gen_random_uuid(),
  passenger_id uuid not null references auth.users(id) on delete cascade,
  pickup_address text,
  destination_address text,
  pickup_lat double precision,
  pickup_lng double precision,
  destination_lat double precision,
  destination_lng double precision,
  waypoints jsonb,
  classification text not null default 'private',
  passenger_count int not null default 1,
  note text,
  scheduled_time timestamptz not null,
  status text not null default 'scheduled'
    check (status in ('scheduled', 'processing', 'active', 'cancelled', 'completed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Index for finding due scheduled trips
create index if not exists scheduled_trips_due_idx
  on public.scheduled_trips(status, scheduled_time)
  where status = 'scheduled';

-- RLS
alter table public.scheduled_trips enable row level security;

-- Policies (drop first to avoid duplicate errors)
drop policy if exists "passenger_select_own_scheduled" on public.scheduled_trips;
create policy "passenger_select_own_scheduled" on public.scheduled_trips
  for select using (auth.uid() = passenger_id);

drop policy if exists "passenger_insert_own_scheduled" on public.scheduled_trips;
create policy "passenger_insert_own_scheduled" on public.scheduled_trips
  for insert with check (auth.uid() = passenger_id);

drop policy if exists "passenger_update_own_scheduled" on public.scheduled_trips;
create policy "passenger_update_own_scheduled" on public.scheduled_trips
  for update using (auth.uid() = passenger_id);

-- 5. Enable Realtime publication (after tables exist)
do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'ride_requests'
  ) then
    alter publication supabase_realtime add table only ride_requests;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'trips'
  ) then
    alter publication supabase_realtime add table only trips;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'scheduled_trips'
  ) then
    alter publication supabase_realtime add table only scheduled_trips;
  end if;
end;
$$;

-- 6. Process scheduled rides function
create or replace function public.process_scheduled_rides()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int := 0;
  v_scheduled record;
  v_request_id uuid;
  v_driver_id uuid;
begin
  for v_scheduled in
    select * from public.scheduled_trips
    where status = 'scheduled'
      and scheduled_time <= now()
    order by scheduled_time asc
    limit 10
  loop
    update public.scheduled_trips set status = 'processing', updated_at = now()
    where id = v_scheduled.id and status = 'scheduled';
    if not found then continue; end if;

    insert into public.ride_requests (
      passenger_id, passenger_count, classification, status,
      pickup_address, destination_address,
      pickup_lat, pickup_lng, waypoints, note
    ) values (
      v_scheduled.passenger_id, v_scheduled.passenger_count,
      v_scheduled.classification, 'pending',
      v_scheduled.pickup_address, v_scheduled.destination_address,
      v_scheduled.pickup_lat, v_scheduled.pickup_lng,
      v_scheduled.waypoints, v_scheduled.note
    )
    returning id into v_request_id;

    if v_scheduled.pickup_lat is not null and v_scheduled.pickup_lng is not null then
      select d.id into v_driver_id
      from public.drivers d
      where d.is_available = true
        and d.active_trips_count < 2
        and d.current_lat is not null and d.current_lng is not null
      order by point(d.current_lng, d.current_lat) <-> point(v_scheduled.pickup_lng, v_scheduled.pickup_lat)
      limit 1;

      if v_driver_id is not null then
        perform public.offer_request_to_driver(v_request_id, v_driver_id, array[v_driver_id]::uuid[]);
      end if;
    end if;

    update public.scheduled_trips set status = 'active', updated_at = now()
    where id = v_scheduled.id;

    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;


