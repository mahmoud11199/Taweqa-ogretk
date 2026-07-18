-- إصلاح infinite recursion في سياسات RLS
-- ننشئ دالة security definer لكسر دورة الاستعلام

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

do $$ begin
  drop policy if exists "profiles_admin_all" on public.profiles;
  drop policy if exists "drivers_admin_all" on public.drivers;
  drop policy if exists "driver_applications_admin_all" on public.driver_applications;
  drop policy if exists "trips_admin_all" on public.trips;
  drop policy if exists "wallets_admin_all" on public.wallets;
  drop policy if exists "rides_admin_all" on public.ride_requests;
  drop policy if exists "settings_admin_all" on public.app_settings;
exception when others then null;
end $$;

create policy "profiles_admin_all" on public.profiles
  for all using (public.is_admin());

create policy "drivers_admin_all" on public.drivers
  for all using (public.is_admin());

create policy "driver_applications_admin_all" on public.driver_applications
  for all using (public.is_admin());

create policy "trips_admin_all" on public.trips
  for all using (public.is_admin());

create policy "wallets_admin_all" on public.wallets
  for all using (public.is_admin());

create policy "rides_admin_all" on public.ride_requests
  for all using (public.is_admin());

create policy "settings_admin_all" on public.app_settings
  for all using (public.is_admin());
