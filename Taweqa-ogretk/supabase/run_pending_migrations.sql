-- ============================================================
--  تشغيل هذا الملف في SQL Editor في Supabase Dashboard
--  https://supabase.com/dashboard/project/hhuiseftzbqssswnuwrv/sql/new
-- ============================================================

-- ============================================================
--  1. تفعيل Realtime Publication للجداول
-- ============================================================
do $$
begin
  create publication if not exists supabase_realtime;
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
end;
$$;

-- ============================================================
--  2. إضافة 'arrived' و 'ongoing' إلى trips.status
-- ============================================================
alter table public.trips drop constraint if exists trips_status_check;
alter table public.trips add constraint trips_status_check
  check (status in ('assigned', 'arrived', 'ongoing', 'started', 'completed', 'cancelled'));

-- تحديث passenger_end_trip ليقبل الحالات الجديدة
-- (موجود مسبقاً في 20260708000004)
CREATE OR REPLACE FUNCTION public.passenger_end_trip(p_trip_id uuid)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
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

-- تحديث sync_active_trips_count ليشمل الحالات الجديدة
CREATE OR REPLACE FUNCTION public.sync_active_trips_count()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
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

-- ============================================================
--  3. جدول الرحلات المجدولة (scheduled_trips)
-- ============================================================
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

-- فهرس للبحث عن الرحلات المجدولة التي حان وقتها
create index if not exists scheduled_trips_due_idx
  on public.scheduled_trips(status, scheduled_time)
  where status = 'scheduled';

-- RLS
alter table public.scheduled_trips enable row level security;

-- سياسة: الراكب يرى فقط رحلاته المجدولة
drop policy if exists "passenger_select_own_scheduled" on public.scheduled_trips;
create policy "passenger_select_own_scheduled" on public.scheduled_trips
  for select using (auth.uid() = passenger_id);

-- سياسة: الراكب يُنشئ رحلاته المجدولة
drop policy if exists "passenger_insert_own_scheduled" on public.scheduled_trips;
create policy "passenger_insert_own_scheduled" on public.scheduled_trips
  for insert with check (auth.uid() = passenger_id);

-- سياسة: الراكب يُحدّث (يلغي) رحلاته المجدولة
drop policy if exists "passenger_update_own_scheduled" on public.scheduled_trips;
create policy "passenger_update_own_scheduled" on public.scheduled_trips
  for update using (auth.uid() = passenger_id);

-- ============================================================
--  4. دالة الأتمتة: معالجة الرحلات المجدولة
-- ============================================================
CREATE OR REPLACE FUNCTION public.process_scheduled_rides()
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
declare
  v_count int := 0;
  v_scheduled record;
  v_request_id uuid;
  v_nearest json;
  v_driver_id uuid;
begin
  for v_scheduled in
    select * from public.scheduled_trips
    where status = 'scheduled'
      and scheduled_time <= now()
    order by scheduled_time asc
    limit 10
  loop
    -- Mark as processing (to avoid duplicate processing)
    update public.scheduled_trips set status = 'processing', updated_at = now()
    where id = v_scheduled.id and status = 'scheduled';

    if not found then continue; end if;

    -- Insert into ride_requests
    insert into public.ride_requests (
      passenger_id, passenger_count, classification, status,
      pickup_address, destination_address,
      pickup_lat, pickup_lng, waypoints, note
    ) values (
      v_scheduled.passenger_id,
      v_scheduled.passenger_count,
      v_scheduled.classification,
      'pending',
      v_scheduled.pickup_address,
      v_scheduled.destination_address,
      v_scheduled.pickup_lat,
      v_scheduled.pickup_lng,
      v_scheduled.waypoints,
      v_scheduled.note
    )
    returning id into v_request_id;

    -- Try to find and offer to nearest driver
    if v_scheduled.pickup_lat is not null and v_scheduled.pickup_lng is not null then
      select json_agg(t) into v_nearest
      from (
        select d.id as driver_id, null as found
        from public.drivers d
        where d.is_available = true
          and d.active_trips_count < 2
          and d.current_lat is not null
          and d.current_lng is not null
        order by point(d.current_lng, d.current_lat) <-> point(v_scheduled.pickup_lng, v_scheduled.pickup_lat)
        limit 1
      ) t;
      v_nearest := coalesce(v_nearest, '[]'::json);
      if json_array_length(v_nearest) > 0 then
        v_driver_id := (v_nearest->0->>'driver_id')::uuid;
        perform public.offer_request_to_driver(v_request_id, v_driver_id, array[v_driver_id]::uuid[]);
      end if;
    end if;

    -- Mark as active
    update public.scheduled_trips set status = 'active', updated_at = now()
    where id = v_scheduled.id;

    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

-- ============================================================
--  5. جدولة دالة الأتمتة كل دقيقة عبر pg_cron
-- ============================================================
-- يتطلب تفعيل pg_cron أولاً:
-- https://supabase.com/docs/guides/platform/cron
-- قم بتشغيل الأمرين التاليين بشكل منفصل:
-- ============================================================

-- الأمر 1: تفعيل pg_cron (شغّل هذا مرة واحدة فقط)
-- select supabase_functions.http_request(
--   'https://hhuiseftzbqssswnuwrv.supabase.co/rest/v1/rpc/process_scheduled_rides',
--   'POST',
--   '{"Content-Type":"application/json"}',
--   '{}',
--   '60000'
-- );

-- الأمر 2: إنشاء الجدولة (شغّل هذا بعد تفعيل pg_cron)
-- SELECT cron.schedule(
--   'process-scheduled-rides',     -- اسم المهمة
--   '* * * * *',                   -- كل دقيقة
--   'select public.process_scheduled_rides()'
-- );

-- لمشاهدة المهام النشطة:
-- SELECT * FROM cron.job;

-- لإيقاف المهمة:
-- SELECT cron.unschedule('process-scheduled-rides');

select 'تم تجهيز كل التغييرات. قم بتشغيل الأمرين في القسم 5 بشكل منفصل بعد تفعيل pg_cron' as info;
