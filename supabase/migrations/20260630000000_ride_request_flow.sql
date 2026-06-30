-- Ride request flow: passenger requests -> driver accepts -> trip starts

alter table if exists public.ride_requests
  add column if not exists pickup_address text,
  add column if not exists destination_address text,
  add column if not exists destination_lat double precision,
  add column if not exists destination_lng double precision;

drop policy if exists "Drivers can view pending requests" on public.ride_requests;
create policy "Drivers can view pending requests"
on public.ride_requests for select
to authenticated
using (
  status = 'pending'
  and driver_id is null
  and exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'driver'
  )
);

drop policy if exists "Drivers can accept pending requests" on public.ride_requests;
create policy "Drivers can accept pending requests"
on public.ride_requests for update
to authenticated
using (
  status = 'pending'
  and driver_id is null
  and exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'driver'
  )
)
with check (driver_id = auth.uid());
