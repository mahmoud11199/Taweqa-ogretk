-- ============================================================
-- Migration: Fix runtime errors R2/R3/R4/R6/R7
-- Replace RLS-blocked JOIN embeds with security-definer RPCs
-- 2026-08-02
-- ============================================================

-- 1. Driver trip history with passenger info
create or replace function public.get_driver_trip_history(p_driver_id uuid)
returns setof jsonb
language plpgsql security definer set search_path = public
as $$
begin
  return query
  select jsonb_build_object(
    'id', t.id,
    'driver_id', t.driver_id,
    'passenger_id', t.passenger_id,
    'start_lat', t.start_lat,
    'start_lng', t.start_lng,
    'end_lat', t.end_lat,
    'end_lng', t.end_lng,
    'distance_km', t.distance_km,
    'duration_min', t.duration_min,
    'fare', t.fare,
    'driver_cut', t.driver_cut,
    'passenger_name', p.full_name,
    'passenger_phone', p.phone,
    'passenger_rating', p.rating,
    'status', t.status,
    'trip_type', t.trip_type,
    'scheduled_at', t.scheduled_at,
    'created_at', t.created_at,
    'completed_at', t.completed_at
  )
  from public.trips t
  left join public.profiles p on p.id = t.passenger_id
  where t.driver_id = p_driver_id
  order by t.created_at desc
  limit 50;
end;
$$;

-- 2. Single trip details with passenger info
create or replace function public.get_trip_details(p_trip_id uuid)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  v_result jsonb;
begin
  select jsonb_build_object(
    'id', t.id,
    'driver_id', t.driver_id,
    'passenger_id', t.passenger_id,
    'start_lat', t.start_lat,
    'start_lng', t.start_lng,
    'end_lat', t.end_lat,
    'end_lng', t.end_lng,
    'distance_km', t.distance_km,
    'duration_min', t.duration_min,
    'fare', t.fare,
    'driver_cut', t.driver_cut,
    'passenger_name', p.full_name,
    'passenger_phone', p.phone,
    'passenger_rating', p.rating,
    'status', t.status,
    'trip_type', t.trip_type,
    'scheduled_at', t.scheduled_at,
    'created_at', t.created_at,
    'completed_at', t.completed_at
  )
  into v_result
  from public.trips t
  left join public.profiles p on p.id = t.passenger_id
  where t.id = p_trip_id;

  if v_result is null then
    return null;
  end if;
  return v_result;
end;
$$;

-- 3. Driver scheduled trips with passenger info
create or replace function public.get_driver_scheduled_trips(p_driver_id uuid)
returns setof jsonb
language plpgsql security definer set search_path = public
as $$
begin
  return query
  select jsonb_build_object(
    'id', t.id,
    'driver_id', t.driver_id,
    'passenger_id', t.passenger_id,
    'start_lat', t.start_lat,
    'start_lng', t.start_lng,
    'end_lat', t.end_lat,
    'end_lng', t.end_lng,
    'distance_km', t.distance_km,
    'duration_min', t.duration_min,
    'fare', t.fare,
    'driver_cut', t.driver_cut,
    'passenger_name', p.full_name,
    'passenger_phone', p.phone,
    'passenger_rating', p.rating,
    'status', t.status,
    'trip_type', t.trip_type,
    'scheduled_at', t.scheduled_at,
    'created_at', t.created_at,
    'completed_at', t.completed_at
  )
  from public.trips t
  left join public.profiles p on p.id = t.passenger_id
  where t.driver_id = p_driver_id
    and t.trip_type = 'scheduled'
    and t.status = 'scheduled'
  order by t.scheduled_at asc;
end;
$$;

-- 4. Conversations with other-user profile info
create or replace function public.get_conversations(p_user_id uuid)
returns setof jsonb
language plpgsql security definer set search_path = public
as $$
begin
  return query
  select jsonb_build_object(
    'id', c.id,
    'user1_id', c.user1_id,
    'user2_id', c.user2_id,
    'created_at', c.created_at,
    'last_message_at', c.last_message_at,
    'last_message', c.last_message,
    'other_user_name', case when c.user1_id = p_user_id then p2.full_name else p1.full_name end,
    'other_user_avatar', case when c.user1_id = p_user_id then p2.avatar_url else p1.avatar_url end
  )
  from public.conversations c
  left join public.profiles p1 on p1.id = c.user1_id
  left join public.profiles p2 on p2.id = c.user2_id
  where c.user1_id = p_user_id or c.user2_id = p_user_id
  order by c.last_message_at desc;
end;
$$;

-- 5. SOS alerts with user info (fixes R4: 'name' column doesn't exist)
create or replace function public.get_sos_alerts()
returns setof jsonb
language plpgsql security definer set search_path = public
as $$
begin
  return query
  select jsonb_build_object(
    'id', a.id,
    'user_id', a.user_id,
    'lat', a.lat,
    'lng', a.lng,
    'message', a.message,
    'status', a.status,
    'created_at', a.created_at,
    'user_name', p.full_name,
    'user_phone', p.phone
  )
  from public.sos_alerts a
  left join public.profiles p on p.id = a.user_id
  where a.status = 'active'
  order by a.created_at desc;
end;
$$;

-- 6. Trip passengers with passenger profile (trip_passengers has no FK to profiles,
--    passenger_id references auth.users, so join via auth.users then profiles)
create or replace function public.get_trip_passengers(p_trip_id uuid)
returns setof jsonb
language plpgsql security definer set search_path = public
as $$
begin
  return query
  select jsonb_build_object(
    'id', tp.id,
    'trip_id', tp.trip_id,
    'passenger_id', tp.passenger_id,
    'pickup_lat', tp.pickup_lat,
    'pickup_lng', tp.pickup_lng,
    'pickup_address', tp.pickup_address,
    'dropoff_lat', tp.dropoff_lat,
    'dropoff_lng', tp.dropoff_lng,
    'dropoff_address', tp.dropoff_address,
    'status', tp.status,
    'fare', tp.fare,
    'created_at', tp.created_at,
    'passenger_name', p.full_name,
    'passenger_phone', p.phone
  )
  from public.trip_passengers tp
  left join public.profiles p on p.id = tp.passenger_id
  where tp.trip_id = p_trip_id
  order by tp.created_at asc;
end;
$$;

-- 7. Fix R6: ride_requests.status CHECK must allow 'scheduled', and add scheduled_at
do $$ begin
  alter table public.ride_requests drop constraint if exists ride_requests_status_check;
exception when others then null;
end $$;

do $$ begin
  alter table public.ride_requests add constraint ride_requests_status_check
    check (status in ('pending','accepted','completed','cancelled','scheduled'));
exception when others then null;
end $$;

do $$ begin
  alter table public.ride_requests add column if not exists scheduled_at timestamptz;
exception when others then null;
end $$;

-- 8. Fix R7: trip_passengers.status CHECK must allow the statuses used by the app
do $$ begin
  alter table public.trip_passengers drop constraint if exists trip_passengers_status_check;
exception when others then null;
end $$;

do $$ begin
  alter table public.trip_passengers add constraint trip_passengers_status_check
    check (status in ('pending','accepted','dropped_off','cancelled','picked_up','arrived','ended'));
exception when others then null;
end $$;

-- 9. Fix R8/R15: missing INSERT policies
-- wallets insert own (only if wallet doesn't exist)
drop policy if exists "wallets_insert_own" on public.wallets;
create policy "wallets_insert_own"
  on public.wallets for insert
  to authenticated
  with check (auth.uid() = user_id);

-- drivers insert own
drop policy if exists "drivers_insert_own" on public.drivers;
create policy "drivers_insert_own"
  on public.drivers for insert
  to authenticated
  with check (auth.uid() = id);

-- profiles insert own
drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
  on public.profiles for insert
  to authenticated
  with check (auth.uid() = id);

-- referral_codes insert own
drop policy if exists "referral_insert_own" on public.referral_codes;
create policy "referral_insert_own"
  on public.referral_codes for insert
  to authenticated
  with check (auth.uid() = user_id);

-- Attach handle_new_user trigger (was defined but never attached -> new users had no wallet)
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 10. Fix R18: device_tokens upsert conflict target
create unique index if not exists device_tokens_user_token_key on public.device_tokens(user_id, token);

-- 11. Admin helpers: join profiles safely (profiles select is own-only)
create or replace function public.get_admin_drivers()
returns setof jsonb
language plpgsql security definer set search_path = public
as $$
begin
  if not exists (select 1 from public.profiles where id = auth.uid() and role = 'admin') then
    return;
  end if;
  return query
  select jsonb_build_object(
    'id', d.id,
    'is_available', d.is_available,
    'driver_type', d.driver_type,
    'car_model', d.car_model,
    'car_plate', d.car_plate,
    'created_at', d.created_at,
    'updated_at', d.updated_at,
    'full_name', p.full_name,
    'phone', p.phone,
    'banned', p.banned,
    'rating', p.rating
  )
  from public.drivers d
  left join public.profiles p on p.id = d.id
  order by d.created_at desc;
end;
$$;

create or replace function public.get_admin_driver_applications()
returns setof jsonb
language plpgsql security definer set search_path = public
as $$
begin
  if not exists (select 1 from public.profiles where id = auth.uid() and role = 'admin') then
    return;
  end if;
  return query
  select jsonb_build_object(
    'user_id', a.user_id,
    'status', a.status,
    'payload', a.payload,
    'created_at', a.created_at,
    'updated_at', a.updated_at,
    'full_name', p.full_name,
    'phone', p.phone
  )
  from public.driver_applications a
  left join public.profiles p on p.id = a.user_id
  order by a.created_at desc;
end;
$$;

-- 12. Add profiles select policy for trip participants + admins (fixes RLS-blocked embeds at DB level)
drop policy if exists "profiles_select_participants" on public.profiles;
create policy "profiles_select_participants"
  on public.profiles for select
  to authenticated
  using (
    exists (
      select 1 from public.trips t
      where (t.driver_id = auth.uid() and t.passenger_id = profiles.id)
         or (t.passenger_id = auth.uid() and t.driver_id = profiles.id)
    )
  );

drop policy if exists "profiles_select_admin" on public.profiles;
create policy "profiles_select_admin"
  on public.profiles for select
  to authenticated
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));
