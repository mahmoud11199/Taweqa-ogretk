-- Fix trips_passenger_id_fkey: reference auth.users instead of passengers
alter table if exists public.trips
  drop constraint if exists trips_passenger_id_fkey;

alter table if exists public.trips
  add constraint trips_passenger_id_fkey
  foreign key (passenger_id)
  references auth.users(id)
  on delete cascade;

-- Fix ratings_passenger_id_fkey: reference auth.users instead of passengers
alter table if exists public.ratings
  drop constraint if exists ratings_passenger_id_fkey;

alter table if exists public.ratings
  add constraint ratings_passenger_id_fkey
  foreign key (passenger_id)
  references auth.users(id)
  on delete cascade;
