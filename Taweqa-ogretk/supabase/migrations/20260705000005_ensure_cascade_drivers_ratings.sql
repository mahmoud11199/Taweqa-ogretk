-- Create missing tables (drivers, ratings) + ensure ON DELETE CASCADE on all FK to auth.users

-- 1. Create drivers table if not exists
create table if not exists public.drivers (
  id uuid primary key references auth.users(id) on delete cascade,
  is_available boolean not null default true,
  current_lat double precision,
  current_lng double precision,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.drivers enable row level security;

drop policy if exists "Users can manage own driver record" on public.drivers;
create policy "Users can manage own driver record" on public.drivers
  for all to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- 2. Create ratings table if not exists
create table if not exists public.ratings (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips(id) on delete cascade,
  driver_id uuid not null references auth.users(id) on delete cascade,
  passenger_id uuid not null references auth.users(id) on delete cascade,
  score integer not null check (score >= 1 and score <= 5),
  comment text,
  created_at timestamptz default now(),
  unique (trip_id, passenger_id)
);

alter table public.ratings enable row level security;

drop policy if exists "Users can view ratings" on public.ratings;
create policy "Users can view ratings" on public.ratings
  for select to authenticated using (true);

drop policy if exists "Users can insert own ratings" on public.ratings;
create policy "Users can insert own ratings" on public.ratings
  for insert to authenticated with check (passenger_id = auth.uid() or driver_id = auth.uid());

-- 3. Drop all existing FK to auth.users or profiles and recreate with ON DELETE CASCADE
do $$
declare
  r record;
  target_oids bigint[];
begin
  -- Find OIDs for both auth.users and public.profiles
  select array_agg(c.oid) into target_oids from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where (c.relname = 'users' and n.nspname = 'auth')
       or (c.relname = 'profiles' and n.nspname = 'public');

  for r in (
    select con.conname, rel.relname, a.attname as col
    from pg_constraint con
    join pg_class rel on rel.oid = con.conrelid
    join pg_namespace nsp on nsp.oid = rel.relnamespace
    join pg_attribute a on a.attrelid = con.conrelid and a.attnum = con.conkey[1]
    where nsp.nspname = 'public'
      and con.contype = 'f'
      and con.confrelid = any(target_oids)
      and rel.relname not in ('drivers', 'ratings')
  ) loop
    execute 'alter table public.' || r.relname || ' drop constraint ' || r.conname;
  end loop;
end $$;

-- 4. Re-add FKs with CASCADE (use DO block to skip if already exists)
do $$
begin
  -- profiles
  if not exists (select 1 from pg_constraint where conname = 'profiles_id_fkey' and conrelid = 'public.profiles'::regclass) then
    alter table public.profiles add constraint profiles_id_fkey foreign key (id) references auth.users(id) on delete cascade;
  end if;
  -- trips
  if not exists (select 1 from pg_constraint where conname = 'trips_driver_id_fkey' and conrelid = 'public.trips'::regclass) then
    alter table public.trips add constraint trips_driver_id_fkey foreign key (driver_id) references auth.users(id) on delete cascade;
  end if;
  if not exists (select 1 from pg_constraint where conname = 'trips_passenger_id_fkey' and conrelid = 'public.trips'::regclass) then
    alter table public.trips add constraint trips_passenger_id_fkey foreign key (passenger_id) references auth.users(id) on delete cascade;
  end if;
  -- ride_requests
  if not exists (select 1 from pg_constraint where conname = 'ride_requests_passenger_id_fkey' and conrelid = 'public.ride_requests'::regclass) then
    alter table public.ride_requests add constraint ride_requests_passenger_id_fkey foreign key (passenger_id) references auth.users(id) on delete cascade;
  end if;
  if not exists (select 1 from pg_constraint where conname = 'ride_requests_driver_id_fkey' and conrelid = 'public.ride_requests'::regclass) then
    alter table public.ride_requests add constraint ride_requests_driver_id_fkey foreign key (driver_id) references auth.users(id) on delete cascade;
  end if;
end $$;

-- 5. Grant execute on get_public_stats to anonymous users (landing page)
do $$
begin
  if exists (select 1 from pg_proc where proname = 'get_public_stats' and pronamespace = 'public'::regnamespace) then
    execute 'grant execute on function public.get_public_stats to anon, authenticated';
  end if;
end $$;

-- 6. Indexes for performance
create index if not exists idx_ratings_trip on public.ratings(trip_id);
create index if not exists idx_ratings_driver on public.ratings(driver_id);
create index if not exists idx_drivers_available on public.drivers(is_available) where is_available = true;
