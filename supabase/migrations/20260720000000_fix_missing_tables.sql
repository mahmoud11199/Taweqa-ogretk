-- ============================================================
--  Fix all missing tables, columns, RPCs discovered during audit
--  Run via: supabase db push  OR  paste in Supabase SQL Editor
-- ============================================================

-- ============================================================
--  1. جدول الإشعارات الداخلية (in_app)
-- ============================================================
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  body text not null default '',
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_notifications_user on public.notifications(user_id, created_at desc);

alter table public.notifications enable row level security;

drop policy if exists "users_select_own_notifications" on public.notifications;
create policy "users_select_own_notifications"
  on public.notifications for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "users_insert_own_notifications" on public.notifications;
create policy "users_insert_own_notifications"
  on public.notifications for insert
  to authenticated
  with check (auth.uid() = user_id);

-- ============================================================
--  2. جدول أجهزة المستخدمين (FCM tokens) — اسم device_tokens
-- ============================================================
create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null,
  platform text not null default 'android' check (platform in ('android', 'ios')),
  updated_at timestamptz not null default now(),
  unique (user_id, token)
);

create index if not exists idx_device_tokens_user on public.device_tokens(user_id);

alter table public.device_tokens enable row level security;

drop policy if exists "users_manage_own_device_tokens" on public.device_tokens;
create policy "users_manage_own_device_tokens"
  on public.device_tokens for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ============================================================
--  3. جدول فئات المركبات (vehicle_categories)
-- ============================================================
create table if not exists public.vehicle_categories (
  id uuid primary key default gen_random_uuid(),
  category_name text not null,
  base_fare double precision not null default 10,
  per_km_price double precision not null default 2,
  per_minute_price double precision not null default 0.5,
  per_wait_minute double precision not null default 1,
  created_at timestamptz not null default now()
);

alter table public.vehicle_categories enable row level security;

drop policy if exists "all_read_vehicle_categories" on public.vehicle_categories;
create policy "all_read_vehicle_categories"
  on public.vehicle_categories for select
  to authenticated
  using (true);

-- ============================================================
--  4. جدول ركاب الرحلة (trip_passengers)
-- ============================================================
create table if not exists public.trip_passengers (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips(id) on delete cascade,
  passenger_id uuid not null references auth.users(id) on delete cascade,
  passenger_name text,
  passenger_phone text,
  pickup_lat double precision,
  pickup_lng double precision,
  pickup_address text,
  dropoff_lat double precision,
  dropoff_lng double precision,
  dropoff_address text,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'dropped_off', 'cancelled')),
  fare double precision,
  created_at timestamptz not null default now()
);

create index if not exists idx_trip_passengers_trip on public.trip_passengers(trip_id);

alter table public.trip_passengers enable row level security;

drop policy if exists "trip_actors_read_trip_passengers" on public.trip_passengers;
create policy "trip_actors_read_trip_passengers"
  on public.trip_passengers for select
  to authenticated
  using (
    exists (
      select 1 from public.trips
      where id = trip_id and (driver_id = auth.uid() or passenger_id = auth.uid())
    )
  );

drop policy if exists "passenger_insert_trip_passengers" on public.trip_passengers;
create policy "passenger_insert_trip_passengers"
  on public.trip_passengers for insert
  to authenticated
  with check (
    passenger_id = auth.uid()
    and exists (
      select 1 from public.trips
      where id = trip_id and (driver_id = auth.uid() or passenger_id = auth.uid())
    )
  );

drop policy if exists "trip_actors_update_trip_passengers" on public.trip_passengers;
create policy "trip_actors_update_trip_passengers"
  on public.trip_passengers for update
  to authenticated
  using (
    exists (
      select 1 from public.trips
      where id = trip_id and (driver_id = auth.uid() or passenger_id = auth.uid())
    )
  );

-- ============================================================
--  5. إضافة unread_count إلى conversations
-- ============================================================
alter table if exists public.conversations
  add column if not exists unread_count int not null default 0;

-- ============================================================
--  6. RPC: جلب السائقين القريبين
-- ============================================================
create or replace function public.get_nearby_drivers(
  p_lat double precision,
  p_lng double precision,
  p_radius_km double precision default 10
) returns table(
  id uuid,
  current_lat double precision,
  current_lng double precision,
  driver_type text,
  car_model text,
  car_plate text,
  car_color text,
  full_name text,
  phone text,
  rating double precision
)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  select
    d.id,
    d.current_lat,
    d.current_lng,
    d.driver_type,
    d.car_model,
    d.car_plate,
    d.car_color,
    p.full_name,
    p.phone,
    p.rating
  from drivers d
  join profiles p on p.id = d.id
  where d.is_available = true
    and d.current_lat is not null
    and d.current_lng is not null
    and (
      6371 * acos(
        cos(radians(p_lat)) * cos(radians(d.current_lat)) *
        cos(radians(d.current_lng) - radians(p_lng)) +
        sin(radians(p_lat)) * sin(radians(d.current_lat))
      )
    ) < p_radius_km
  order by
    (6371 * acos(
      cos(radians(p_lat)) * cos(radians(d.current_lat)) *
      cos(radians(d.current_lng) - radians(p_lng)) +
      sin(radians(p_lat)) * sin(radians(d.current_lat))
    ));
end;
$$;

grant execute on function public.get_nearby_drivers to authenticated;

-- ============================================================
--  7. إضافة جدول notifications و device_tokens إلى Realtime
-- ============================================================
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table only notifications;
  end if;
end;
$$;

-- ============================================================
--  8. إدراج بيانات افتراضية لفئات المركبات (اختياري)
-- ============================================================
insert into public.vehicle_categories (category_name, base_fare, per_km_price, per_minute_price, per_wait_minute)
values
  ('عادية', 10, 2, 0.5, 1),
  ('VIP', 15, 3, 0.75, 1.5),
  ('عائلة', 12, 2.5, 0.6, 1.2)
on conflict do nothing;

-- ============================================================
--  9. إصلاح RLS policies — user_devices + passengers + transactions
-- ============================================================
alter table if exists public.user_devices enable row level security;

drop policy if exists "Users can manage own passenger record" on public.passengers;
drop policy if exists passengers_select_own on public.passengers;
drop policy if exists passengers_insert_own on public.passengers;
drop policy if exists passengers_update_own on public.passengers;
create policy passengers_select_own on public.passengers for select to authenticated using (auth.uid() = id);
create policy passengers_insert_own on public.passengers for insert to authenticated with check (auth.uid() = id);
create policy passengers_update_own on public.passengers for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists transactions_insert_own on public.transactions;
create policy transactions_insert_own on public.transactions for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists user_devices_select_own on public.user_devices;
drop policy if exists user_devices_insert_own on public.user_devices;
drop policy if exists user_devices_update_own on public.user_devices;
create policy user_devices_select_own on public.user_devices for select to authenticated using (auth.uid() = user_id);
create policy user_devices_insert_own on public.user_devices for insert to authenticated with check (auth.uid() = user_id);
create policy user_devices_update_own on public.user_devices for update to authenticated using (auth.uid() = user_id);

select '✅ تم تطبيق جميع الإصلاحات بنجاح' as info;
