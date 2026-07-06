-- Add waypoints and note columns to ride_requests and trips

alter table if exists public.ride_requests
  add column if not exists waypoints jsonb not null default '[]'::jsonb,
  add column if not exists note text;

alter table if exists public.trips
  add column if not exists waypoints jsonb not null default '[]'::jsonb;
