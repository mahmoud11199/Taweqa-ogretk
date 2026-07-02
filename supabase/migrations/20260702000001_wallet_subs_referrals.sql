-- Wallet + Subscription + Referral system

-- 0. Ensure profiles have proper RLS policies (required for login)
alter table if exists public.profiles enable row level security;

drop policy if exists "Users can view own profile" on public.profiles;
create policy "Users can view own profile"
on public.profiles for select
to authenticated
using (id = auth.uid());

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
on public.profiles for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists "Trigger can insert profiles" on public.profiles;
create policy "Trigger can insert profiles"
on public.profiles for insert
to authenticated, service_role
with check (true);

-- 1. WALLETS
create table if not exists public.wallets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade unique,
  balance double precision not null default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.wallets enable row level security;

create policy "Users can view own wallet"
on public.wallets for select
to authenticated
using (user_id = auth.uid());

create policy "System can insert wallet"
on public.wallets for insert
to authenticated
with check (user_id = auth.uid());

-- 2. WALLET TRANSACTIONS
create table if not exists public.wallet_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  amount double precision not null,
  type text not null check (type in ('charge', 'subscription', 'refund', 'referral_reward', 'withdrawal')),
  status text not null default 'pending' check (status in ('pending', 'completed', 'failed')),
  reference text,
  description text,
  created_at timestamptz default now()
);

alter table public.wallet_transactions enable row level security;

create policy "Users can view own transactions"
on public.wallet_transactions for select
to authenticated
using (user_id = auth.uid());

create policy "Users can insert own transactions"
on public.wallet_transactions for insert
to authenticated
with check (user_id = auth.uid());

-- 3. SUBSCRIPTIONS
create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  plan_type text not null check (plan_type in ('driver', 'passenger')),
  status text not null default 'active' check (status in ('active', 'expired', 'cancelled')),
  start_date timestamptz not null default now(),
  end_date timestamptz not null,
  auto_renew boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.subscriptions enable row level security;

create policy "Users can view own subscriptions"
on public.subscriptions for select
to authenticated
using (user_id = auth.uid());

create policy "Users can insert own subscriptions"
on public.subscriptions for insert
to authenticated
with check (user_id = auth.uid());

create policy "Users can update own subscriptions"
on public.subscriptions for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- 4. REFERRALS
create table if not exists public.referral_codes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade unique,
  code text not null unique,
  created_at timestamptz default now()
);

alter table public.referral_codes enable row level security;

create policy "Users can view own referral code"
on public.referral_codes for select
to authenticated
using (user_id = auth.uid());

create policy "Anyone can look up referral code"
on public.referral_codes for select
to authenticated
using (true);

create policy "Users can insert own referral code"
on public.referral_codes for insert
to authenticated
with check (user_id = auth.uid());

create table if not exists public.referrals (
  id uuid primary key default gen_random_uuid(),
  referrer_id uuid not null references auth.users(id) on delete cascade,
  referred_id uuid not null references auth.users(id) on delete cascade unique,
  status text not null default 'pending' check (status in ('pending', 'completed', 'rewarded')),
  created_at timestamptz default now()
);

alter table public.referrals enable row level security;

create policy "Referrals viewable by referrer"
on public.referrals for select
to authenticated
using (referrer_id = auth.uid());

create policy "System can insert referrals"
on public.referrals for insert
to authenticated
with check (referrer_id = auth.uid());

-- 5. Helper function: auto-create profile + wallet + referral code on user creation
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  ref_code text;
  v_full_name text;
  v_role text;
  v_phone text;
begin
  -- Extract metadata
  v_full_name := new.raw_user_meta_data ->> 'full_name';
  v_role := new.raw_user_meta_data ->> 'role';
  v_phone := new.raw_user_meta_data ->> 'phone';

  -- Create profile
  insert into public.profiles (id, full_name, role, phone, created_at)
  values (new.id, v_full_name, v_role, v_phone, now());

  -- Create wallet
  insert into public.wallets (user_id, balance) values (new.id, 0);

  -- Generate referral code
  ref_code := upper(substr(md5(random()::text || new.id::text), 1, 8));
  insert into public.referral_codes (user_id, code) values (new.id, ref_code);

  -- Check if referred by someone (from raw_user_meta_data)
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

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 6. Check & expire subscriptions function (call periodically or on login)
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

-- 7. Auto-renew subscription function (call when checking subscription)
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
  -- Get current subscription
  select * into v_sub from public.subscriptions
  where user_id = p_user_id and status = 'active'
  order by end_date desc limit 1;

  if not found then
    -- Get plan type from profile
    select role into v_plan from public.profiles where id = p_user_id;
    if not found then return json_build_object('success', false, 'error', 'No profile'); end if;
    v_plan := case when v_plan = 'driver' then 'driver' else 'passenger' end;
  else
    v_plan := v_sub.plan_type;
  end if;

  v_price := case when v_plan = 'driver' then 299 else 89 end;

  -- Check balance
  select balance into v_balance from public.wallets where user_id = p_user_id;
  if v_balance < v_price then
    return json_build_object('success', false, 'error', 'Insufficient balance', 'required', v_price, 'balance', v_balance);
  end if;

  -- Deduct from wallet
  update public.wallets set balance = balance - v_price, updated_at = now() where user_id = p_user_id;

  -- Record transaction
  insert into public.wallet_transactions (user_id, amount, type, status, description)
  values (p_user_id, -v_price, 'subscription', 'completed', 'تجديد الاشتراك الشهري - ' || v_plan);

  -- Update or insert subscription
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

-- 8. Check and reward referrals function
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
    -- Mark these referrals as rewarded
    update public.referrals
    set status = 'rewarded'
    where referrer_id = v_referrer.referrer_id and status = 'completed';

    -- Add free month subscription
    insert into public.subscriptions (user_id, plan_type, status, start_date, end_date, auto_renew)
    select v_referrer.referrer_id, coalesce(p.role, 'passenger'), 'active', now(), now() + interval '30 days', false
    from public.profiles p where p.id = v_referrer.referrer_id;

    -- Record reward transaction
    insert into public.wallet_transactions (user_id, amount, type, status, description)
    values (v_referrer.referrer_id, 0, 'referral_reward', 'completed', 'مكافأة إحالة 10 مستخدمين - شهر مجاني');
  end loop;
end;
$$;

-- 9. Public stats function (live data for landing page)
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
  -- Users
  select count(*) into v_users_total from public.profiles;
  select count(*) into v_users_drivers from public.profiles where role = 'driver';
  select count(*) into v_users_passengers from public.profiles where role = 'passenger';
  -- Trips
  select count(*) into v_trips_total from public.trips;
  select count(*) into v_trips_completed from public.trips where status = 'completed';
  select count(*) into v_trips_cancelled from public.trips where status = 'cancelled';
  select count(*) into v_trips_today from public.trips where created_at >= current_date;
  select count(*) into v_trips_week from public.trips where created_at >= now() - interval '7 days';
  select count(*) into v_trips_month from public.trips where created_at >= now() - interval '30 days';
  select coalesce(sum(total_fare), 0) into v_total_fare from public.trips where status = 'completed';
  select coalesce(sum(distance_km), 0) into v_total_dist from public.trips where status = 'completed';
  -- Drivers
  select count(*) into v_active_drivers from public.drivers;
  select count(*) into v_available_now from public.drivers where is_available = true;
  -- Ratings
  select coalesce(avg(score), 0) into v_avg_rating from public.ratings;
  select count(*) into v_ratings_total from public.ratings;
  -- Referrals
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

-- 10. Indexes
create index if not exists idx_wallet_user on public.wallets(user_id);
create index if not exists idx_wallet_tx_user on public.wallet_transactions(user_id, created_at desc);
create index if not exists idx_subscription_user on public.subscriptions(user_id, status);
create index if not exists idx_referral_code on public.referral_codes(code);
create index if not exists idx_referrals_referrer on public.referrals(referrer_id, status);
