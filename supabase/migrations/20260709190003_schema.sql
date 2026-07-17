-- ============================================================
-- توقع أجرتك - Full Database Schema
-- Migration 00001: Core tables, RLS, indexes, and RPCs
-- ============================================================

-- 0. Extensions
create extension if not exists "pgcrypto";

-- 0a. Migration fix: ensure all columns exist (safe to re-run)
do $$ begin alter table public.profiles add column if not exists updated_at timestamptz not null default now(); exception when others then null; end $$;
do $$ begin alter table public.profiles add column if not exists banned boolean not null default false; exception when others then null; end $$;
do $$ begin alter table public.profiles add column if not exists rating double precision; exception when others then null; end $$;
do $$ begin alter table public.profiles add column if not exists avatar_url text; exception when others then null; end $$;
do $$ begin alter table public.drivers add column if not exists updated_at timestamptz not null default now(); exception when others then null; end $$;
do $$ begin alter table public.drivers add column if not exists driver_type text; exception when others then null; end $$;
do $$ begin alter table public.drivers add column if not exists car_model text; exception when others then null; end $$;
do $$ begin alter table public.drivers add column if not exists car_plate text; exception when others then null; end $$;
do $$ begin alter table public.drivers add column if not exists car_color text; exception when others then null; end $$;
do $$ begin alter table public.drivers add column if not exists current_lat double precision; exception when others then null; end $$;
do $$ begin alter table public.drivers add column if not exists current_lng double precision; exception when others then null; end $$;
do $$ begin alter table public.driver_applications add column if not exists updated_at timestamptz not null default now(); exception when others then null; end $$;
do $$ begin alter table public.wallets add column if not exists updated_at timestamptz not null default now(); exception when others then null; end $$;
do $$ begin alter table public.wallets add column if not exists pending_balance double precision default 0; exception when others then null; end $$;
do $$ begin alter table public.ride_requests add column if not exists updated_at timestamptz not null default now(); exception when others then null; end $$;
do $$ begin alter table public.trips add column if not exists driver_cut double precision; exception when others then null; end $$;
do $$ begin alter table public.trips add column if not exists completed_at timestamptz; exception when others then null; end $$;

-- 1. PROFILES
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  full_name   text not null default '',
  role        text not null default 'passenger' check (role in ('passenger','driver','admin')),
  phone       text,
  email       text,
  avatar_url  text,
  banned      boolean not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles_select_own" on public.profiles
  for select using (auth.uid() = id);

create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id);

create policy "profiles_admin_all" on public.profiles
  for all using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- 2. DRIVERS
create table if not exists public.drivers (
  id            uuid primary key references public.profiles(id) on delete cascade,
  is_available  boolean not null default false,
  driver_type   text check (driver_type in ('private','tuk-tuk','motorcycle')),
  car_model     text,
  car_plate     text,
  car_color     text,
  current_lat   double precision,
  current_lng   double precision,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

alter table public.drivers enable row level security;

create policy "drivers_select_all" on public.drivers
  for select using (true);

create policy "drivers_update_own" on public.drivers
  for update using (auth.uid() = id);

create policy "drivers_admin_all" on public.drivers
  for all using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- 3. DRIVER APPLICATIONS
create table if not exists public.driver_applications (
  user_id    uuid primary key references public.profiles(id) on delete cascade,
  status     text not null default 'pending' check (status in ('pending','approved','rejected')),
  payload    jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.driver_applications enable row level security;

create policy "applications_select_own" on public.driver_applications
  for select using (auth.uid() = user_id);

create policy "applications_insert_own" on public.driver_applications
  for insert with check (auth.uid() = user_id);

create policy "applications_admin_all" on public.driver_applications
  for all using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- 4. TRIPS
create table if not exists public.trips (
  id              uuid primary key default gen_random_uuid(),
  driver_id       uuid not null references public.drivers(id),
  passenger_id    uuid references public.profiles(id),
  start_lat       double precision not null,
  start_lng       double precision not null,
  end_lat         double precision,
  end_lng         double precision,
  distance_km     double precision,
  duration_min    double precision,
  fare            double precision,
  driver_cut      double precision,
  status          text not null default 'active' check (status in ('active','completed','cancelled')),
  created_at      timestamptz not null default now(),
  completed_at    timestamptz
);

alter table public.trips enable row level security;

create policy "trips_select_driver" on public.trips
  for select using (auth.uid() = driver_id);

create policy "trips_select_passenger" on public.trips
  for select using (auth.uid() = passenger_id);

create policy "trips_insert_driver" on public.trips
  for insert with check (auth.uid() = driver_id);

create policy "trips_update_driver" on public.trips
  for update using (auth.uid() = driver_id);

create policy "trips_admin_all" on public.trips
  for all using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- 5. RIDE REQUESTS
create table if not exists public.ride_requests (
  id                 uuid primary key default gen_random_uuid(),
  passenger_id       uuid not null references public.profiles(id),
  driver_id          uuid references public.drivers(id),
  pickup_lat         double precision not null,
  pickup_lng         double precision not null,
  pickup_address     text not null default '',
  dest_lat           double precision,
  dest_lng           double precision,
  dest_address       text,
  status             text not null default 'pending' check (status in ('pending','accepted','completed','cancelled')),
  estimated_fare     double precision,
  estimated_distance double precision,
  estimated_duration double precision,
  rating             double precision,
  review             text,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

alter table public.ride_requests enable row level security;

create policy "requests_select_passenger" on public.ride_requests
  for select using (auth.uid() = passenger_id);

create policy "requests_select_driver" on public.ride_requests
  for select using (auth.uid() = driver_id);

create policy "requests_insert_passenger" on public.ride_requests
  for insert with check (auth.uid() = passenger_id);

create policy "requests_update_passenger" on public.ride_requests
  for update using (auth.uid() = passenger_id);

-- 6. WALLETS
create table if not exists public.wallets (
  user_id         uuid primary key references public.profiles(id) on delete cascade,
  balance         double precision not null default 0,
  pending_balance double precision default 0,
  updated_at      timestamptz not null default now()
);

alter table public.wallets enable row level security;

create policy "wallets_select_own" on public.wallets
  for select using (auth.uid() = user_id);

create policy "wallets_admin_all" on public.wallets
  for all using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- 7. TRANSACTIONS
create table if not exists public.transactions (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references public.profiles(id),
  type            text not null check (type in ('deposit','withdrawal','payment')),
  amount          double precision not null,
  balance_before  double precision,
  balance_after   double precision,
  description     text,
  status          text not null default 'completed' check (status in ('pending','completed','failed')),
  paymob_ref      text,
  created_at      timestamptz not null default now()
);

alter table public.transactions enable row level security;

create policy "transactions_select_own" on public.transactions
  for select using (auth.uid() = user_id);

-- 8. CONVERSATIONS
create table if not exists public.conversations (
  id              uuid primary key default gen_random_uuid(),
  user1_id        uuid not null references public.profiles(id),
  user2_id        uuid not null references public.profiles(id),
  last_message    text,
  last_message_at timestamptz,
  created_at      timestamptz not null default now()
);

alter table public.conversations enable row level security;

create policy "conversations_select_participant" on public.conversations
  for select using (auth.uid() in (user1_id, user2_id));

create policy "conversations_insert_participant" on public.conversations
  for insert with check (auth.uid() in (user1_id, user2_id));

-- 9. MESSAGES
create table if not exists public.messages (
  id               uuid primary key default gen_random_uuid(),
  conversation_id  uuid not null references public.conversations(id) on delete cascade,
  sender_id        uuid not null references public.profiles(id),
  text             text not null default '',
  image_url        text,
  is_read          boolean not null default false,
  created_at       timestamptz not null default now()
);

alter table public.messages enable row level security;

create policy "messages_select_participant" on public.messages
  for select using (
    exists (
      select 1 from public.conversations
      where id = messages.conversation_id
        and auth.uid() in (user1_id, user2_id)
    )
  );

create policy "messages_insert_participant" on public.messages
  for insert with check (
    exists (
      select 1 from public.conversations
      where id = conversation_id
        and auth.uid() in (user1_id, user2_id)
    )
  );

-- 10. REFERRAL CODES
create table if not exists public.referral_codes (
  user_id    uuid primary key references public.profiles(id) on delete cascade,
  code       text not null unique,
  created_at timestamptz not null default now()
);

alter table public.referral_codes enable row level security;

create policy "referral_select_own" on public.referral_codes
  for select using (auth.uid() = user_id);

-- 11. APP SETTINGS
create table if not exists public.app_settings (
  id               int primary key default 1 check (id = 1),
  pricing_per_km   double precision not null default 3.5,
  pricing_per_min  double precision not null default 0.5,
  base_fare        double precision not null default 5.0,
  commission_rate  double precision not null default 0.15,
  updated_at       timestamptz not null default now()
);

alter table public.app_settings enable row level security;

create policy "settings_select_all" on public.app_settings
  for select using (true);

create policy "settings_admin_all" on public.app_settings
  for all using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- Insert default settings row
insert into public.app_settings (id) values (1) on conflict (id) do nothing;

-- ============================================================
-- INDEXES
-- ============================================================
create index if not exists idx_trips_driver_id on public.trips(driver_id);
create index if not exists idx_trips_passenger_id on public.trips(passenger_id);
create index if not exists idx_trips_status on public.trips(status);
create index if not exists idx_trips_created_at on public.trips(created_at desc);
create index if not exists idx_ride_requests_passenger on public.ride_requests(passenger_id);
create index if not exists idx_ride_requests_status on public.ride_requests(status);
create index if not exists idx_transactions_user on public.transactions(user_id);
create index if not exists idx_messages_conversation on public.messages(conversation_id);
create index if not exists idx_messages_created on public.messages(created_at);
create index if not exists idx_conversations_participants on public.conversations(user1_id, user2_id);
create index if not exists idx_drivers_location on public.drivers(current_lat, current_lng);
create index if not exists idx_referral_codes_code on public.referral_codes(code);

-- ============================================================
-- RPCs (Database Functions)
-- ============================================================

-- RPC: update_driver_location
create or replace function public.update_driver_location(
  p_driver_id uuid,
  p_lat double precision,
  p_lng double precision
) returns void
language sql
security definer
as $$
  update public.drivers
  set current_lat = p_lat, current_lng = p_lng
  where id = p_driver_id;
$$;

-- RPC: get_nearby_drivers
create or replace function public.get_nearby_drivers(
  p_lat double precision,
  p_lng double precision,
  p_radius_km double precision default 10
) returns table (
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
language sql
security definer
as $$
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
    p.rating::double precision
  from public.drivers d
  join public.profiles p on p.id = d.id
  where d.is_available = true
    and d.current_lat is not null
    and d.current_lng is not null
    and (2 * 6371 * asin(sqrt(
        pow(sin((radians(p_lat) - radians(d.current_lat)) / 2), 2)
        + cos(radians(p_lat)) * cos(radians(d.current_lat))
        * pow(sin((radians(p_lng) - radians(d.current_lng)) / 2), 2)
      ))) <= p_radius_km;
$$;

-- RPC: apply_referral
create or replace function public.apply_referral(
  p_user_id uuid,
  p_ref_code text
) returns void
language plpgsql
security definer
as $$
declare
  v_referrer_id uuid;
begin
  select user_id into v_referrer_id
  from public.referral_codes
  where code = p_ref_code;

  if v_referrer_id is not null and v_referrer_id != p_user_id then
    -- Bonus for referrer
    update public.wallets
    set balance = balance + 10
    where user_id = v_referrer_id;

    insert into public.transactions (user_id, type, amount, description)
    values (v_referrer_id, 'deposit', 10, 'مكافأة إحالة');
  end if;
end;
$$;

-- RPC: record_wallet_deposit
create or replace function public.record_wallet_deposit(
  p_user_id uuid,
  p_amount double precision,
  p_paymob_ref text
) returns void
language plpgsql
security definer
as $$
begin
  update public.wallets
  set balance = balance + p_amount
  where user_id = p_user_id;

  insert into public.transactions (user_id, type, amount, description, paymob_ref)
  values (p_user_id, 'deposit', p_amount, 'إيداع عبر Paymob', p_paymob_ref);
end;
$$;

-- RPC: deduct_wallet_fare
create or replace function public.deduct_wallet_fare(
  p_user_id uuid,
  p_amount double precision,
  p_trip_id uuid
) returns void
language plpgsql
security definer
as $$
begin
  update public.wallets
  set balance = balance - p_amount
  where user_id = p_user_id;

  insert into public.transactions (user_id, type, amount, description)
  values (p_user_id, 'payment', p_amount, 'خصم قيمة الرحلة');
end;
$$;

-- RPC: mark_messages_read
create or replace function public.mark_messages_read(
  p_conversation_id uuid,
  p_user_id uuid
) returns void
language sql
security definer
as $$
  update public.messages
  set is_read = true
  where conversation_id = p_conversation_id
    and sender_id != p_user_id
    and is_read = false;
$$;

-- RPC: get_admin_stats
create or replace function public.get_admin_stats()
returns json
language plpgsql
security definer
as $$
declare
  v_total_drivers int;
  v_available_drivers int;
  v_total_passengers int;
  v_active_trips int;
  v_completed_trips int;
  v_pending_applications int;
  v_total_revenue double precision;
begin
  select count(*) into v_total_drivers from public.drivers;
  select count(*) into v_available_drivers from public.drivers where is_available = true;
  select count(*) into v_total_passengers from public.profiles where role = 'passenger';
  select count(*) into v_active_trips from public.trips where status = 'active';
  select count(*) into v_completed_trips from public.trips where status = 'completed';
  select count(*) into v_pending_applications from public.driver_applications where status = 'pending';
  select coalesce(sum(driver_cut), 0) into v_total_revenue from public.trips where status = 'completed';

  return json_build_object(
    'total_drivers', v_total_drivers,
    'available_drivers', v_available_drivers,
    'total_passengers', v_total_passengers,
    'active_trips', v_active_trips,
    'completed_trips', v_completed_trips,
    'pending_applications', v_pending_applications,
    'total_revenue', v_total_revenue
  );
end;
$$;

-- ============================================================
-- STORAGE BUCKETS
-- ============================================================
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('driver-documents', 'driver-documents', true)
on conflict (id) do nothing;

-- Allow authenticated users to upload to avatars
create policy "avatars_upload_own" on storage.objects
  for insert with check (
    bucket_id = 'avatars'
    and auth.role() = 'authenticated'
  );

-- Allow authenticated users to upload to driver-documents
create policy "driver_docs_upload_own" on storage.objects
  for insert with check (
    bucket_id = 'driver-documents'
    and auth.role() = 'authenticated'
  );
