-- Price adjustment + payment method for trips
alter table if exists public.trips
  add column if not exists original_km_price double precision,
  add column if not exists original_wait_price double precision,
  add column if not exists original_duration_price double precision,
  add column if not exists original_bandira double precision,
  add column if not exists price_adjusted boolean not null default false,
  add column if not exists payment_method text default 'cash' check (payment_method in ('cash', 'wallet', 'pending')),
  add column if not exists payment_status text default 'unpaid' check (payment_status in ('unpaid', 'paid_cash', 'paid_wallet', 'settled'));

-- Add price_adjusted to trip_events event_type check
alter table if exists public.trip_events drop constraint if exists trip_events_event_type_check;
alter table if exists public.trip_events add constraint trip_events_event_type_check
  check (event_type in ('started', 'location', 'pause', 'resume', 'passenger_joined',
    'passenger_left', 'manual_distance', 'completed', 'cancelled', 'price_adjusted'));
