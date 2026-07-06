-- Production hardening for trip integrity.
-- This migration is intentionally idempotent so it can be applied to an
-- existing Supabase project that already has the core application tables.

alter table if exists public.trips enable row level security;
alter table if exists public.profiles enable row level security;
alter table if exists public.ride_requests enable row level security;

alter table if exists public.trips
  add column if not exists started_at timestamptz default now(),
  add column if not exists completed_at timestamptz,
  add column if not exists last_synced_at timestamptz default now(),
  add column if not exists last_lat double precision,
  add column if not exists last_lng double precision,
  add column if not exists server_calculated boolean not null default false;

create table if not exists public.trip_events (
  id uuid primary key default gen_random_uuid(),
  trip_id text not null,
  actor_id uuid references auth.users(id) on delete set null,
  event_type text not null check (event_type in (
    'started', 'location', 'pause', 'resume', 'passenger_joined',
    'passenger_left', 'manual_distance', 'completed', 'cancelled'
  )),
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.trip_locations (
  id uuid primary key default gen_random_uuid(),
  trip_id text not null,
  actor_id uuid references auth.users(id) on delete set null,
  lat double precision not null check (lat between -90 and 90),
  lng double precision not null check (lng between -180 and 180),
  accuracy_m double precision check (accuracy_m is null or accuracy_m between 0 and 500),
  speed_kmh double precision check (speed_kmh is null or speed_kmh between 0 and 120),
  created_at timestamptz not null default now()
);

create table if not exists public.driver_applications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  reviewed_at timestamptz,
  unique (user_id)
);

alter table public.trip_events enable row level security;
alter table public.trip_locations enable row level security;
alter table public.driver_applications enable row level security;

create index if not exists trip_events_trip_id_created_at_idx on public.trip_events(trip_id, created_at);
create index if not exists trip_locations_trip_id_created_at_idx on public.trip_locations(trip_id, created_at);
create index if not exists trips_join_code_status_idx on public.trips(join_code, status);

drop policy if exists "drivers can read own trips" on public.trips;
create policy "drivers can read own trips"
on public.trips for select
to authenticated
using (driver_id = auth.uid() or passenger_id = auth.uid());

drop policy if exists "drivers can insert own trips" on public.trips;
create policy "drivers can insert own trips"
on public.trips for insert
to authenticated
with check (driver_id = auth.uid());

drop policy if exists "drivers can update own non-completed trips" on public.trips;
create policy "drivers can update own non-completed trips"
on public.trips for update
to authenticated
using (driver_id = auth.uid() and coalesce(status, '') <> 'completed')
with check (driver_id = auth.uid());

drop policy if exists "trip actors can read events" on public.trip_events;
create policy "trip actors can read events"
on public.trip_events for select
to authenticated
using (
  exists (
    select 1 from public.trips t
    where t.id::text = trip_events.trip_id
      and (t.driver_id = auth.uid() or t.passenger_id = auth.uid())
  )
);

drop policy if exists "trip actors can read locations" on public.trip_locations;
create policy "trip actors can read locations"
on public.trip_locations for select
to authenticated
using (
  exists (
    select 1 from public.trips t
    where t.id::text = trip_locations.trip_id
      and (t.driver_id = auth.uid() or t.passenger_id = auth.uid())
  )
);

drop policy if exists "users can manage own driver applications" on public.driver_applications;
create policy "users can manage own driver applications"
on public.driver_applications for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());
