-- Fix ride_requests passenger_id FK: was pointing to `passengers(id)` (a test-only table)
-- instead of `auth.users(id)`. This caused FK violations for every real passenger.
alter table if exists public.ride_requests
  drop constraint if exists ride_requests_passenger_id_fkey;

alter table if exists public.ride_requests
  add constraint ride_requests_passenger_id_fkey
  foreign key (passenger_id) references auth.users(id) on delete cascade;
