-- Restore offered_to filter: only the assigned driver sees/accepts the request

drop policy if exists "Drivers can view pending requests" on public.ride_requests;
create policy "Drivers can view pending requests"
on public.ride_requests for select
to authenticated
using (
  status = 'pending'
  and driver_id is null
  and offered_to = auth.uid()
  and exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'driver'
  )
);

drop policy if exists "Drivers can accept pending requests" on public.ride_requests;
create policy "Drivers can accept pending requests"
on public.ride_requests for update
to authenticated
using (status='pending' and driver_id is null and offered_to=auth.uid() and exists(select 1 from public.profiles where id=auth.uid() and role='driver'))
with check (driver_id=auth.uid());
