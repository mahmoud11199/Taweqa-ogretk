-- ============================================================
-- Fill all gaps between migration files and live database
-- Detected 16 missing tables, 13 missing RPCs, columns, policies
-- ============================================================

-- ============================================================
-- 1. MISSING TABLES
-- ============================================================

-- 1a. passengers
create table if not exists public.passengers (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  created_at timestamptz default now()
);
alter table public.passengers enable row level security;

-- 1b. pricing
create table if not exists public.pricing (
  governorate text not null,
  label text not null,
  meter_start double precision default 5.0,
  km_price double precision default 8.0,
  person_km_price double precision default 4.0,
  wait_minute_price double precision default 1.0,
  min_trip_cost double precision default 12.0,
  is_active boolean default true,
  created_at timestamptz default now(),
  km_price_min double precision,
  km_price_max double precision,
  child_km_price double precision default 3.0,
  individual_km_price double precision default 5.0,
  primary key (governorate, label)
);
alter table public.pricing enable row level security;

-- 1c. ratings
create table if not exists public.ratings (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid,
  driver_id uuid,
  passenger_id uuid,
  score int,
  comment text,
  created_at timestamptz default now()
);
alter table public.ratings enable row level security;

-- 1d. referrals
create table if not exists public.referrals (
  id uuid primary key default gen_random_uuid(),
  referrer_id uuid not null,
  referred_id uuid not null,
  status text not null default 'pending' check (status in ('pending','completed','rewarded')),
  created_at timestamptz default now()
);
alter table public.referrals enable row level security;

-- 1e. referral_log
create table if not exists public.referral_log (
  id uuid primary key default gen_random_uuid(),
  referrer_driver_id uuid,
  referred_driver_id uuid,
  status text default 'pending' check (status in ('pending','completed','rewarded')),
  reward_granted boolean default false,
  created_at timestamptz default now()
);
alter table public.referral_log enable row level security;

-- 1f. dispute_tickets
create table if not exists public.dispute_tickets (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid,
  driver_id uuid,
  rating_id uuid,
  reason text,
  status text default 'open',
  admin_note text,
  created_at timestamptz default now()
);
alter table public.dispute_tickets enable row level security;

-- 1g. gps_track_points
create table if not exists public.gps_track_points (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid,
  trip_id uuid,
  lat double precision,
  lng double precision,
  recorded_at timestamptz default now()
);
alter table public.gps_track_points enable row level security;

-- 1h. scheduled_trips
create table if not exists public.scheduled_trips (
  id uuid primary key default gen_random_uuid(),
  passenger_id uuid not null,
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
  status text not null default 'scheduled' check (status in ('scheduled','processing','active','completed','cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.scheduled_trips enable row level security;

-- 1i. settings
create table if not exists public.settings (
  id text primary key,
  value text
);
alter table public.settings enable row level security;

-- 1j. subscriptions
create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  plan_type text not null,
  status text not null default 'active' check (status in ('active','expired','cancelled')),
  start_date timestamptz not null default now(),
  end_date timestamptz not null,
  auto_renew boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
alter table public.subscriptions enable row level security;

-- 1k. trip_chat_messages
create table if not exists public.trip_chat_messages (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null,
  sender_id uuid not null,
  sender_role text not null,
  message text not null,
  created_at timestamptz default now()
);
alter table public.trip_chat_messages enable row level security;

-- 1l. trip_events
create table if not exists public.trip_events (
  id uuid primary key default gen_random_uuid(),
  trip_id text not null,
  actor_id uuid,
  event_type text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
alter table public.trip_events enable row level security;

-- 1m. trip_locations
create table if not exists public.trip_locations (
  id uuid primary key default gen_random_uuid(),
  trip_id text not null,
  actor_id uuid,
  lat double precision not null,
  lng double precision not null,
  accuracy_m double precision,
  speed_kmh double precision,
  created_at timestamptz not null default now()
);
alter table public.trip_locations enable row level security;

-- 1n. user_devices
create table if not exists public.user_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid,
  device_id text,
  created_at timestamptz default now()
);
alter table public.user_devices enable row level security;

-- 1o. visitors
create table if not exists public.visitors (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  name text default ''::text,
  source text default 'landing_page'::text,
  created_at timestamptz default now()
);
alter table public.visitors enable row level security;

-- 1p. wallet_transactions
create table if not exists public.wallet_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid,
  type text default 'deposit'::text,
  amount double precision,
  status text default 'pending'::text,
  sender_phone text,
  proof_image text,
  admin_notes text,
  reference_type text,
  reference_id text,
  created_at timestamptz default now()
);
alter table public.wallet_transactions enable row level security;

-- ============================================================
-- 2. MISSING COLUMNS ON EXISTING TABLES
-- ============================================================

-- drivers
do $$ begin alter table public.drivers add column if not exists email text; exception when others then null; end $$;
do $$ begin alter table public.drivers add column if not exists governorate text; exception when others then null; end $$;
do $$ begin alter table public.drivers add column if not exists status text default 'pending'; exception when others then null; end $$;
do $$ begin alter table public.drivers add column if not exists wallet_balance double precision default 0.0; exception when others then null; end $$;
do $$ begin alter table public.drivers add column if not exists referral_code text; exception when others then null; end $$;
do $$ begin alter table public.drivers add column if not exists referred_by text; exception when others then null; end $$;
do $$ begin alter table public.drivers add column if not exists payment_system text default 'cash'; exception when others then null; end $$;
do $$ begin alter table public.drivers add column if not exists active_trips_count int default 0; exception when others then null; end $$;
do $$ begin alter table public.drivers add column if not exists rejection_reason text; exception when others then null; end $$;
do $$ begin alter table public.drivers add column if not exists national_id_image text; exception when others then null; end $$;
do $$ begin alter table public.drivers add column if not exists license_image text; exception when others then null; end $$;
do $$ begin alter table public.drivers add column if not exists documents_skipped boolean default false; exception when others then null; end $$;

-- ride_requests
do $$ begin alter table public.ride_requests add column if not exists passenger_count int default 1; exception when others then null; end $$;
do $$ begin alter table public.ride_requests add column if not exists classification text default 'private'; exception when others then null; end $$;
do $$ begin alter table public.ride_requests add column if not exists adult_count int default 1; exception when others then null; end $$;
do $$ begin alter table public.ride_requests add column if not exists child_count int default 0; exception when others then null; end $$;
do $$ begin alter table public.ride_requests add column if not exists destination_address text; exception when others then null; end $$;
do $$ begin alter table public.ride_requests add column if not exists destination_lat double precision; exception when others then null; end $$;
do $$ begin alter table public.ride_requests add column if not exists destination_lng double precision; exception when others then null; end $$;
do $$ begin alter table public.ride_requests add column if not exists offered_to uuid; exception when others then null; end $$;
do $$ begin alter table public.ride_requests add column if not exists offered_at timestamptz; exception when others then null; end $$;
do $$ begin alter table public.ride_requests add column if not exists offered_drivers jsonb default '[]'::jsonb; exception when others then null; end $$;
do $$ begin alter table public.ride_requests add column if not exists waypoints jsonb not null default '[]'::jsonb; exception when others then null; end $$;
do $$ begin alter table public.ride_requests add column if not exists note text; exception when others then null; end $$;

-- trips
do $$ begin alter table public.trips add column if not exists total_fare double precision; exception when others then null; end $$;
do $$ begin alter table public.trips add column if not exists meter_start_fee double precision default 5.0; exception when others then null; end $$;
do $$ begin alter table public.trips add column if not exists km_price_used double precision default 8.0; exception when others then null; end $$;
do $$ begin alter table public.trips add column if not exists person_km_price_used double precision default 5.0; exception when others then null; end $$;
do $$ begin alter table public.trips add column if not exists wait_price_used double precision default 1.0; exception when others then null; end $$;
do $$ begin alter table public.trips add column if not exists wait_minutes double precision default 0; exception when others then null; end $$;
do $$ begin alter table public.trips add column if not exists start_address text; exception when others then null; end $$;
do $$ begin alter table public.trips add column if not exists end_address text; exception when others then null; end $$;
do $$ begin alter table public.trips add column if not exists classification text default 'private'; exception when others then null; end $$;
do $$ begin alter table public.trips add column if not exists child_count int default 0; exception when others then null; end $$;
do $$ begin alter table public.trips add column if not exists passenger_breakdown jsonb; exception when others then null; end $$;
do $$ begin alter table public.trips add column if not exists adult_count int default 1; exception when others then null; end $$;
do $$ begin alter table public.trips add column if not exists parent_trip_id uuid; exception when others then null; end $$;
do $$ begin alter table public.trips add column if not exists group_label text; exception when others then null; end $$;
do $$ begin alter table public.trips add column if not exists started_at timestamptz default now(); exception when others then null; end $$;
do $$ begin alter table public.trips add column if not exists last_synced_at timestamptz default now(); exception when others then null; end $$;
do $$ begin alter table public.trips add column if not exists last_lat double precision; exception when others then null; end $$;
do $$ begin alter table public.trips add column if not exists last_lng double precision; exception when others then null; end $$;
do $$ begin alter table public.trips add column if not exists server_calculated boolean not null default false; exception when others then null; end $$;
do $$ begin alter table public.trips add column if not exists duration_price_used double precision default 0.5; exception when others then null; end $$;
do $$ begin alter table public.trips add column if not exists waypoints jsonb not null default '[]'::jsonb; exception when others then null; end $$;
do $$ begin alter table public.trips add column if not exists join_code text; exception when others then null; end $$;
do $$ begin alter table public.trips add column if not exists gps_weak_mode boolean default false; exception when others then null; end $$;
do $$ begin alter table public.trips add column if not exists manual_distance_km double precision; exception when others then null; end $$;
do $$ begin alter table public.trips add column if not exists cancellation_fine double precision; exception when others then null; end $$;
do $$ begin alter table public.trips add column if not exists cancelled_by text; exception when others then null; end $$;
do $$ begin alter table public.trips add column if not exists passenger_id uuid; exception when others then null; end $$;

-- messages
do $$ begin alter table public.messages add column if not exists topic text not null default ''; exception when others then null; end $$;
do $$ begin alter table public.messages add column if not exists extension text not null default ''; exception when others then null; end $$;
do $$ begin alter table public.messages add column if not exists payload jsonb; exception when others then null; end $$;
do $$ begin alter table public.messages add column if not exists event text; exception when others then null; end $$;
do $$ begin alter table public.messages add column if not exists private boolean default false; exception when others then null; end $$;
do $$ begin alter table public.messages add column if not exists updated_at timestamp without time zone not null default now(); exception when others then null; end $$;
do $$ begin alter table public.messages add column if not exists inserted_at timestamp without time zone not null default now(); exception when others then null; end $$;
do $$ begin alter table public.messages add column if not exists binary_payload bytea; exception when others then null; end $$;

-- driver_applications
do $$ begin alter table public.driver_applications add column if not exists id uuid; exception when others then null; end $$;
do $$ begin alter table public.driver_applications add column if not exists reviewed_at timestamptz; exception when others then null; end $$;

-- wallets
do $$ begin alter table public.wallets add column if not exists id uuid; exception when others then null; end $$;
do $$ begin alter table public.wallets add column if not exists created_at timestamptz default now(); exception when others then null; end $$;

-- ============================================================
-- 3. MISSING INDEXES
-- ============================================================
create index if not exists idx_drivers_available on public.drivers(is_available) where is_available = true;
create index if not exists idx_referral_code on public.referral_codes(code);
create index if not exists idx_referrals_referrer on public.referrals(referrer_id, status);
create index if not exists idx_ratings_driver on public.ratings(driver_id);
create index if not exists idx_ratings_trip on public.ratings(trip_id);
create index if not exists idx_ride_requests_offered_to on public.ride_requests(offered_to);
create index if not exists scheduled_trips_due_idx on public.scheduled_trips(status, scheduled_time) where status = 'scheduled';
create index if not exists idx_subscription_user on public.subscriptions(user_id, status);
create index if not exists idx_chat_trip_id on public.trip_chat_messages(trip_id, created_at);
create index if not exists trip_events_trip_id_created_at_idx on public.trip_events(trip_id, created_at);
create index if not exists trip_locations_trip_id_created_at_idx on public.trip_locations(trip_id, created_at);
create index if not exists idx_wallet_tx_user on public.wallet_transactions(user_id, created_at desc);
create index if not exists idx_wallet_user on public.wallets(user_id);
create index if not exists trips_join_code_status_idx on public.trips(join_code, status);

-- ============================================================
-- 4. MISSING RLS POLICIES (using do blocks for safety)
-- ============================================================

do $$ begin
  drop policy if exists passengers_select_own on public.passengers;
  create policy passengers_select_own on public.passengers for select using (auth.uid() = id);
exception when others then null; end $$;

do $$ begin
  drop policy if exists passengers_insert_own on public.passengers;
  create policy passengers_insert_own on public.passengers for insert with check (auth.uid() = id);
exception when others then null; end $$;

do $$ begin
  drop policy if exists passengers_update_own on public.passengers;
  create policy passengers_update_own on public.passengers for update using (auth.uid() = id) with check (auth.uid() = id);
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Authenticated can select pricing" on public.pricing;
  create policy "Authenticated can select pricing" on public.pricing for select using (auth.role() = 'authenticated');
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Admin can update pricing" on public.pricing;
  create policy "Admin can update pricing" on public.pricing for all using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Users can view ratings" on public.ratings;
  create policy "Users can view ratings" on public.ratings for select using (true);
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Drivers can view own ratings" on public.ratings;
  create policy "Drivers can view own ratings" on public.ratings for select using (driver_id = auth.uid() or passenger_id = auth.uid());
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Users can insert own ratings" on public.ratings;
  create policy "Users can insert own ratings" on public.ratings for insert with check (passenger_id = auth.uid() or driver_id = auth.uid());
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Passengers can insert ratings" on public.ratings;
  create policy "Passengers can insert ratings" on public.ratings for insert with check (passenger_id = auth.uid());
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Authenticated can select ratings" on public.ratings;
  create policy "Authenticated can select ratings" on public.ratings for select using (auth.role() = 'authenticated');
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Authenticated can insert ratings" on public.ratings;
  create policy "Authenticated can insert ratings" on public.ratings for insert with check (auth.role() = 'authenticated');
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Referrals viewable by referrer" on public.referrals;
  create policy "Referrals viewable by referrer" on public.referrals for select using (referrer_id = auth.uid());
exception when others then null; end $$;

do $$ begin
  drop policy if exists "System can insert referrals" on public.referrals;
  create policy "System can insert referrals" on public.referrals for insert with check (referrer_id = auth.uid());
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Authenticated can select referral_log" on public.referral_log;
  create policy "Authenticated can select referral_log" on public.referral_log for select using (auth.role() = 'authenticated');
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Authenticated can insert referral_log" on public.referral_log;
  create policy "Authenticated can insert referral_log" on public.referral_log for insert with check (auth.role() = 'authenticated');
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Authenticated can select dispute_tickets" on public.dispute_tickets;
  create policy "Authenticated can select dispute_tickets" on public.dispute_tickets for select using (auth.role() = 'authenticated');
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Authenticated can insert dispute_tickets" on public.dispute_tickets;
  create policy "Authenticated can insert dispute_tickets" on public.dispute_tickets for insert with check (auth.role() = 'authenticated');
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Admin can update dispute_tickets" on public.dispute_tickets;
  create policy "Admin can update dispute_tickets" on public.dispute_tickets for update using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Authenticated can select gps" on public.gps_track_points;
  create policy "Authenticated can select gps" on public.gps_track_points for select using (auth.role() = 'authenticated');
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Authenticated can insert gps" on public.gps_track_points;
  create policy "Authenticated can insert gps" on public.gps_track_points for insert with check (auth.role() = 'authenticated');
exception when others then null; end $$;

do $$ begin
  drop policy if exists passenger_select_own_scheduled on public.scheduled_trips;
  create policy passenger_select_own_scheduled on public.scheduled_trips for select using (auth.uid() = passenger_id);
exception when others then null; end $$;

do $$ begin
  drop policy if exists passenger_insert_own_scheduled on public.scheduled_trips;
  create policy passenger_insert_own_scheduled on public.scheduled_trips for insert with check (auth.uid() = passenger_id);
exception when others then null; end $$;

do $$ begin
  drop policy if exists passenger_update_own_scheduled on public.scheduled_trips;
  create policy passenger_update_own_scheduled on public.scheduled_trips for update using (auth.uid() = passenger_id);
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Authenticated can select settings" on public.settings;
  create policy "Authenticated can select settings" on public.settings for select using (auth.role() = 'authenticated');
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Admin can update settings" on public.settings;
  create policy "Admin can update settings" on public.settings for all using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Users can view own subscriptions" on public.subscriptions;
  create policy "Users can view own subscriptions" on public.subscriptions for select using (user_id = auth.uid());
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Users can insert own subscriptions" on public.subscriptions;
  create policy "Users can insert own subscriptions" on public.subscriptions for insert with check (user_id = auth.uid());
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Users can update own subscriptions" on public.subscriptions;
  create policy "Users can update own subscriptions" on public.subscriptions for update using (user_id = auth.uid()) with check (user_id = auth.uid());
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Users can read messages of their trips" on public.trip_chat_messages;
  create policy "Users can read messages of their trips" on public.trip_chat_messages for select using (exists (select 1 from public.trips where id = trip_id and (driver_id = auth.uid() or passenger_id = auth.uid())));
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Users can insert messages in their trips" on public.trip_chat_messages;
  create policy "Users can insert messages in their trips" on public.trip_chat_messages for insert with check (sender_id = auth.uid() and exists (select 1 from public.trips where id = trip_id and (driver_id = auth.uid() or passenger_id = auth.uid())));
exception when others then null; end $$;

do $$ begin
  drop policy if exists "trip actors can read events" on public.trip_events;
  create policy "trip actors can read events" on public.trip_events for select using (exists (select 1 from public.trips t where t.id::text = trip_id and (t.driver_id = auth.uid() or t.passenger_id = auth.uid())));
exception when others then null; end $$;

do $$ begin
  drop policy if exists "trip actors can read locations" on public.trip_locations;
  create policy "trip actors can read locations" on public.trip_locations for select using (exists (select 1 from public.trips t where t.id::text = trip_id and (t.driver_id = auth.uid() or t.passenger_id = auth.uid())));
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Anyone can insert visitors" on public.visitors;
  create policy "Anyone can insert visitors" on public.visitors for insert with check (true);
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Only admins can view visitors" on public.visitors;
  create policy "Only admins can view visitors" on public.visitors for select using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Users can view own transactions" on public.wallet_transactions;
  create policy "Users can view own transactions" on public.wallet_transactions for select using (user_id = auth.uid());
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Users can insert own transactions" on public.wallet_transactions;
  create policy "Users can insert own transactions" on public.wallet_transactions for insert with check (user_id = auth.uid());
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Wallet tx insertable" on public.wallet_transactions;
  create policy "Wallet tx insertable" on public.wallet_transactions for insert with check (auth.role() = 'authenticated');
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Wallet tx updatable by admin" on public.wallet_transactions;
  create policy "Wallet tx updatable by admin" on public.wallet_transactions for update using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));
exception when others then null; end $$;

do $$ begin
  drop policy if exists "Wallet tx viewable by owner or admin" on public.wallet_transactions;
  create policy "Wallet tx viewable by owner or admin" on public.wallet_transactions for select using (auth.uid() = user_id or exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));
exception when others then null; end $$;

-- ============================================================
-- 5. MISSING RPCs
-- ============================================================

-- apply_wallet_charge
create or replace function public.apply_wallet_charge(p_user_id uuid, p_amount double precision)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare v_current_balance double precision; v_new_balance double precision; begin if p_amount < 0 then select coalesce(balance, 0) into v_current_balance from public.wallets where user_id = p_user_id; if v_current_balance + p_amount < 0 then return json_build_object('success', false, 'error', 'Balance insufficient', 'balance', v_current_balance); end if; end if; insert into public.wallets (user_id, balance) values (p_user_id, p_amount) on conflict (user_id) do update set balance = public.wallets.balance + p_amount, updated_at = now(); select coalesce(balance, 0) into v_new_balance from public.wallets where user_id = p_user_id; return json_build_object('success', true, 'balance', v_new_balance); end;
$$;

-- check_referral_rewards
create or replace function public.check_referral_rewards()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_referrer record;
  v_count integer;
begin
  for v_referrer in
    select referrer_id, count(*) as cnt
    from public.referrals
    where status = 'completed'
    group by referrer_id
    having count(*) >= 10
  loop
    update public.referrals
    set status = 'rewarded'
    where referrer_id = v_referrer.referrer_id and status = 'completed';
    insert into public.subscriptions (user_id, plan_type, status, start_date, end_date, auto_renew)
    select v_referrer.referrer_id, coalesce(p.role, 'passenger'), 'active', now(), now() + interval '30 days', false
    from public.profiles p where p.id = v_referrer.referrer_id;
    insert into public.wallet_transactions (user_id, amount, type, status, description)
    values (v_referrer.referrer_id, 0, 'referral_reward', 'completed', 'مكافأة إحالة 10 مستخدمين - شهر مجاني');
  end loop;
end;
$$;

-- check_subscription_expiry
create or replace function public.check_subscription_expiry()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.subscriptions
  set status = 'expired', updated_at = now()
  where status = 'active' and end_date < now();
end;
$$;

-- delete_trip
create or replace function public.delete_trip(p_trip_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from gps_track_points where trip_id = p_trip_id;
  delete from trips where id = p_trip_id;
end;
$$;

-- find_nearest_available_driver
create or replace function public.find_nearest_available_driver(
  pickup_lat double precision,
  pickup_lng double precision,
  exclude_ids uuid[] default '{}'::uuid[]
)
returns json
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

-- get_public_stats
create or replace function public.get_public_stats()
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_users_total int;
  v_users_drivers int;
  v_users_passengers int;
  v_trips_total int;
  v_trips_completed int;
  v_trips_cancelled int;
  v_trips_today int;
  v_trips_week int;
  v_trips_month int;
  v_total_fare double precision;
  v_total_dist double precision;
  v_active_drivers int;
  v_available_now int;
  v_avg_rating double precision;
  v_ratings_total int;
  v_ref_total int;
  v_ref_successful int;
begin
  select count(*) into v_users_total from public.profiles;
  select count(*) into v_users_drivers from public.profiles where role = 'driver';
  select count(*) into v_users_passengers from public.profiles where role = 'passenger';
  select count(*) into v_trips_total from public.trips;
  select count(*) into v_trips_completed from public.trips where status = 'completed';
  select count(*) into v_trips_cancelled from public.trips where status = 'cancelled';
  select count(*) into v_trips_today from public.trips where created_at >= current_date;
  select count(*) into v_trips_week from public.trips where created_at >= now() - interval '7 days';
  select count(*) into v_trips_month from public.trips where created_at >= now() - interval '30 days';
  select coalesce(sum(total_fare), 0) into v_total_fare from public.trips where status = 'completed';
  select coalesce(sum(distance_km), 0) into v_total_dist from public.trips where status = 'completed';
  select count(*) into v_active_drivers from public.drivers;
  select count(*) into v_available_now from public.drivers where is_available = true;
  select coalesce(avg(score), 0) into v_avg_rating from public.ratings;
  select count(*) into v_ratings_total from public.ratings;
  select count(*) into v_ref_total from public.referrals;
  select count(*) into v_ref_successful from public.referrals where status in ('completed', 'rewarded');
  return json_build_object(
    'users', json_build_object('total', v_users_total, 'drivers', v_users_drivers, 'passengers', v_users_passengers),
    'trips', json_build_object('total', v_trips_total, 'completed', v_trips_completed, 'cancelled', v_trips_cancelled,
      'today', v_trips_today, 'this_week', v_trips_week, 'this_month', v_trips_month,
      'total_fare', v_total_fare, 'avg_fare', case when v_trips_completed > 0 then v_total_fare / v_trips_completed else 0 end,
      'total_distance_km', v_total_dist),
    'drivers', json_build_object('active', v_active_drivers, 'available_now', v_available_now),
    'ratings', json_build_object('avg_score', round(v_avg_rating::numeric, 1), 'total', v_ratings_total),
    'referrals', json_build_object('total', v_ref_total, 'successful', v_ref_successful)
  );
end;
$$;

-- handle_new_user
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  ref_code text;
begin
  insert into public.wallets (user_id, balance) values (new.id, 0);
  ref_code := upper(substr(md5(random()::text || new.id::text), 1, 8));
  insert into public.referral_codes (user_id, code) values (new.id, ref_code);
  if new.raw_user_meta_data ? 'ref' then
    declare
      v_referrer_user_id uuid;
    begin
      select user_id into v_referrer_user_id from public.referral_codes where code = new.raw_user_meta_data ->> 'ref';
      if found and v_referrer_user_id is not null then
        insert into public.referrals (referrer_id, referred_id, status) values (v_referrer_user_id, new.id, 'pending');
      end if;
    end;
  end if;
  return new;
end;
$$;

-- offer_request_to_driver
create or replace function public.offer_request_to_driver(
  p_request_id uuid,
  p_driver_id uuid,
  p_offered_drivers uuid[] default '{}'::uuid[]
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare v_request record; begin select * into v_request from public.ride_requests where id = p_request_id; if not found then return json_build_object('success', false, 'error', 'Request not found'); end if; if v_request.status <> 'pending' then return json_build_object('success', false, 'error', 'Not pending'); end if; update public.ride_requests set offered_to = p_driver_id, offered_at = now(), offered_drivers = to_jsonb(p_offered_drivers) where id = p_request_id; return json_build_object('success', true, 'driver_id', p_driver_id); end;
$$;

-- passenger_end_trip
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

-- pay_trip_from_wallet
create or replace function public.pay_trip_from_wallet(p_trip_id uuid)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_trip record;
  v_passenger_balance double precision;
begin
  select * into v_trip from public.trips where id = p_trip_id;
  if not found then
    return json_build_object('success', false, 'error', 'Trip not found');
  end if;
  if v_trip.passenger_id <> auth.uid() then
    return json_build_object('success', false, 'error', 'Not your trip');
  end if;
  if v_trip.payment_method <> 'wallet' then
    return json_build_object('success', false, 'error', 'Payment method is not wallet');
  end if;
  if v_trip.payment_status = 'paid_wallet' or v_trip.payment_status = 'settled' then
    return json_build_object('success', false, 'error', 'Already paid');
  end if;
  select balance into v_passenger_balance from public.wallets where user_id = v_trip.passenger_id;
  if v_passenger_balance is null or v_passenger_balance < v_trip.total_fare then
    return json_build_object('success', false, 'error', 'Insufficient balance',
      'required', v_trip.total_fare, 'balance', coalesce(v_passenger_balance, 0));
  end if;
  update public.wallets set balance = balance - v_trip.total_fare, updated_at = now()
  where user_id = v_trip.passenger_id;
  insert into public.wallets (user_id, balance)
  values (v_trip.driver_id, v_trip.total_fare)
  on conflict (user_id)
  do update set balance = public.wallets.balance + v_trip.total_fare, updated_at = now();
  insert into public.wallet_transactions (user_id, amount, type, status, description, reference)
  values (v_trip.passenger_id, -v_trip.total_fare, 'trip_payment', 'completed',
    'دفع الرحلة - كود: ' || coalesce(v_trip.join_code, ''), p_trip_id::text);
  insert into public.wallet_transactions (user_id, amount, type, status, description, reference)
  values (v_trip.driver_id, v_trip.total_fare, 'trip_payment', 'completed',
    'استلام الرحلة - كود: ' || coalesce(v_trip.join_code, ''), p_trip_id::text);
  update public.trips set payment_status = 'paid_wallet' where id = p_trip_id;
  insert into public.trip_events (trip_id, actor_id, event_type, payload)
  values (p_trip_id::text, auth.uid(), 'payment_completed',
    jsonb_build_object('amount', v_trip.total_fare, 'method', 'wallet'));
  return json_build_object('success', true, 'amount', v_trip.total_fare);
end;
$$;

-- process_scheduled_rides
create or replace function public.process_scheduled_rides()
returns integer
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

-- process_user_withdrawal
create or replace function public.process_user_withdrawal(p_user_id uuid, p_amount double precision)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare v_balance double precision; begin select balance into v_balance from public.wallets where user_id = p_user_id; if v_balance is null or v_balance < p_amount then return json_build_object('success', false, 'error', 'Insufficient balance'); end if; update public.wallets set balance = balance - p_amount, updated_at = now() where user_id = p_user_id; insert into public.wallet_transactions (user_id, amount, type, status, description) values (p_user_id, -p_amount, 'withdrawal', 'pending', 'withdrawal request'); return json_build_object('success', true); end;
$$;

-- renew_subscription
create or replace function public.renew_subscription(p_user_id uuid)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_plan text;
  v_price double precision;
  v_balance double precision;
  v_sub record;
begin
  select * into v_sub from public.subscriptions
  where user_id = p_user_id and status = 'active'
  order by end_date desc limit 1;
  if not found then
    select role into v_plan from public.profiles where id = p_user_id;
    if not found then return json_build_object('success', false, 'error', 'No profile'); end if;
    v_plan := case when v_plan = 'driver' then 'driver' else 'passenger' end;
  else
    v_plan := v_sub.plan_type;
  end if;
  v_price := case when v_plan = 'driver' then 299 else 89 end;
  select balance into v_balance from public.wallets where user_id = p_user_id;
  if v_balance < v_price then
    return json_build_object('success', false, 'error', 'Insufficient balance', 'required', v_price, 'balance', v_balance);
  end if;
  update public.wallets set balance = balance - v_price, updated_at = now() where user_id = p_user_id;
  insert into public.wallet_transactions (user_id, amount, type, status, description)
  values (p_user_id, -v_price, 'subscription', 'completed', 'تجديد الاشتراك الشهري - ' || v_plan);
  if not found then
    insert into public.subscriptions (user_id, plan_type, status, start_date, end_date)
    values (p_user_id, v_plan, 'active', now(), now() + interval '30 days');
  else
    update public.subscriptions
    set status = 'active', end_date = now() + interval '30 days', updated_at = now()
    where id = v_sub.id;
  end if;
  return json_build_object('success', true, 'plan', v_plan, 'end_date', (now() + interval '30 days')::text);
end;
$$;

-- sync_active_trips_count
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

-- rls_auto_enable event trigger
create or replace function public.rls_auto_enable()
returns event_trigger
language plpgsql
security definer
set search_path = public
as $$
declare cmd record; begin for cmd in select * from pg_event_trigger_ddl_commands() where command_tag in ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO') and object_type in ('table','partitioned table') loop if cmd.schema_name is not null and cmd.schema_name in ('public') and cmd.schema_name not in ('pg_catalog','information_schema') and cmd.schema_name not like 'pg_toast%' and cmd.schema_name not like 'pg_temp%' then begin execute format('alter table if exists %s enable row level security', cmd.object_identity); raise log 'rls_auto_enable: enabled RLS on %', cmd.object_identity; exception when others then raise log 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity; end; else raise log 'rls_auto_enable: skip % (system schema)', cmd.object_identity; end if; end loop; end;
$$;

-- ============================================================
-- 6. MISSING TRIGGERS
-- ============================================================
drop trigger if exists trg_sync_active_trips_count on public.trips;
create trigger trg_sync_active_trips_count
  after insert or delete or update of status on public.trips
  for each row execute function sync_active_trips_count();

-- Event trigger: auto-enable RLS on new tables
drop event trigger if exists ensure_rls;
create event trigger ensure_rls
  on ddl_command_end
  when tag in ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
  execute function rls_auto_enable();

-- ============================================================
-- 7. ADD UNIQUE / FK CONSTRAINTS THAT EXIST IN LIVE
-- ============================================================
-- Ensure referral_codes.code is unique (might be defined differently in migration 1)
do $$ begin
  alter table public.referral_codes add constraint referral_codes_code_key unique (code);
exception when unique_violation then null; when others then null;
end $$;

-- Ensure referral_codes.user_id is unique (already pk, but just in case)
do $$ begin
  alter table public.referral_codes add constraint referral_codes_user_id_key unique (user_id);
exception when unique_violation then null; when others then null;
end $$;

-- Ensure drivers.referral_code is unique
do $$ begin
  alter table public.drivers add constraint drivers_referral_code_key unique (referral_code);
exception when unique_violation then null; when others then null;
end $$;

-- Ensure referrals.referred_id is unique
do $$ begin
  alter table public.referrals add constraint referrals_referred_id_key unique (referred_id);
exception when unique_violation then null; when others then null;
end $$;

-- Ensure device_tokens has unique constraint on (user_id, token)
do $$ begin
  alter table public.device_tokens add constraint device_tokens_user_id_token_key unique (user_id, token);
exception when unique_violation then null; when others then null;
end $$;

-- Ensure trips.join_code is unique
do $$ begin
  alter table public.trips add constraint trips_join_code_key unique (join_code);
exception when unique_violation then null; when others then null;
end $$;

-- ============================================================
-- 8. ENABLE MISSING TABLES IN REALTIME PUBLICATION
-- ============================================================
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'trip_events'
  ) then
    alter publication supabase_realtime add table only trip_events;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'trip_locations'
  ) then
    alter publication supabase_realtime add table only trip_locations;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'ride_requests'
  ) then
    alter publication supabase_realtime add table only ride_requests;
  end if;
end;
$$;

select '✅ تم سد جميع الفجوات بنجاح' as info;
