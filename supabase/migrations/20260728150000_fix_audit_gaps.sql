-- ============================================================
-- Migration: Fill audit gaps — tables, columns, RPCs
-- 2026-07-28
-- ============================================================

-- 1. sos_alerts table
create table if not exists public.sos_alerts (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id),
  lat        double precision,
  lng        double precision,
  message    text default 'طلب نجدة',
  status     text not null default 'active' check (status in ('active','resolved')),
  created_at timestamptz default now()
);
alter table public.sos_alerts enable row level security;

create policy "sos_alerts_insert_own" on public.sos_alerts
  for insert with check (auth.uid() = user_id);
create policy "sos_alerts_select_admin" on public.sos_alerts
  for select using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));
create policy "sos_alerts_update_admin" on public.sos_alerts
  for update using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

-- 2. saved_cards table
create table if not exists public.saved_cards (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id),
  card_holder text not null default '',
  last4       text not null,
  brand       text not null default 'Visa',
  exp_month   int not null default 12,
  exp_year    int not null default 30,
  is_default  boolean not null default false,
  created_at  timestamptz default now()
);
alter table public.saved_cards enable row level security;

create policy "cards_select_own" on public.saved_cards
  for select using (auth.uid() = user_id);
create policy "cards_insert_own" on public.saved_cards
  for insert with check (auth.uid() = user_id);
create policy "cards_delete_own" on public.saved_cards
  for delete using (auth.uid() = user_id);

-- 3. Add columns to trips
do $$ begin
  alter table public.trips add column if not exists trip_type text not null default 'instant';
exception when others then null;
end $$;

do $$ begin
  alter table public.trips add column if not exists scheduled_at timestamptz;
exception when others then null;
end $$;

do $$ begin
  alter table public.trips drop constraint if exists trips_status_check;
exception when others then null;
end $$;

do $$ begin
  alter table public.trips add constraint trips_status_check
    check (status in ('active','completed','cancelled','scheduled'));
exception when others then null;
end $$;

-- 4. Add columns to app_settings
do $$ begin
  alter table public.app_settings add column if not exists wait_price double precision not null default 0.25;
exception when others then null;
end $$;

do $$ begin
  alter table public.app_settings add column if not exists night_multiplier double precision not null default 1.5;
exception when others then null;
end $$;

do $$ begin
  alter table public.app_settings add column if not exists min_fare double precision not null default 5.0;
exception when others then null;
end $$;

-- 5. Add rejected_drivers to ride_requests (for reject_ride_request RPC)
do $$ begin
  alter table public.ride_requests add column if not exists rejected_drivers jsonb default '[]'::jsonb;
exception when others then null;
end $$;

-- 6. Create missing RPCs

-- get_pending_requests_for_driver
create or replace function public.get_pending_requests_for_driver(p_driver_id uuid)
returns setof public.ride_requests
language plpgsql security definer
as $$
begin
  return query
  select *
  from public.ride_requests
  where status = 'pending'
    and (offered_to = p_driver_id or offered_drivers @> to_jsonb(p_driver_id::text)::jsonb)
  order by created_at desc;
end;
$$;

-- accept_ride_request
create or replace function public.accept_ride_request(p_request_id uuid, p_driver_id uuid)
returns json
language plpgsql security definer
as $$
declare
  v_request record;
begin
  select * into v_request from public.ride_requests where id = p_request_id;
  if not found then
    return json_build_object('success', false, 'error', 'Request not found');
  end if;
  if v_request.status <> 'pending' then
    return json_build_object('success', false, 'error', 'Not pending');
  end if;
  if v_request.offered_to <> p_driver_id then
    return json_build_object('success', false, 'error', 'Not offered to this driver');
  end if;

  update public.ride_requests
  set driver_id = p_driver_id, status = 'accepted', updated_at = now()
  where id = p_request_id;

  return json_build_object('success', true, 'request_id', p_request_id, 'driver_id', p_driver_id);
end;
$$;

-- reject_ride_request
create or replace function public.reject_ride_request(p_request_id uuid, p_driver_id uuid)
returns json
language plpgsql security definer
as $$
declare
  v_offered jsonb;
  v_rejected jsonb;
begin
  -- Remove driver from offered_drivers and add to rejected_drivers
  select coalesce(offered_drivers, '[]'::jsonb), coalesce(rejected_drivers, '[]'::jsonb)
  into v_offered, v_rejected
  from public.ride_requests
  where id = p_request_id;

  if not found then
    return json_build_object('success', false, 'error', 'Request not found');
  end if;

  v_offered = v_offered - p_driver_id::text;
  v_rejected = v_rejected || to_jsonb(p_driver_id::text);

  update public.ride_requests
  set
    offered_drivers = v_offered,
    rejected_drivers = v_rejected,
    offered_to = case when v_offered = '[]'::jsonb then null else offered_to end,
    updated_at = now()
  where id = p_request_id;

  return json_build_object('success', true);
end;
$$;