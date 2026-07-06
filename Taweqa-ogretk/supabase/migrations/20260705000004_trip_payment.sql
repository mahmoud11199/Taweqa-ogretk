-- Phase 3: Trip payment from wallet
alter table if exists public.wallet_transactions drop constraint if exists wallet_transactions_type_check;
alter table if exists public.wallet_transactions add constraint wallet_transactions_type_check
  check (type in ('charge', 'subscription', 'refund', 'referral_reward', 'withdrawal', 'trip_payment'));

-- Passenger pays for a trip from their wallet
create or replace function public.pay_trip_from_wallet(p_trip_id uuid)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_trip record;
  v_passenger_balance double precision;
  v_driver_balance double precision;
begin
  select * into v_trip from public.trips where id = p_trip_id;
  if not found then
    return json_build_object('success', false, 'error', 'Trip not found');
  end if;
  if v_trip.passenger_id <> auth.uid() then
    return json_build_object('success', false, 'error', 'Not your trip');
  end if;
  if v_trip.payment_method <> 'wallet' then
    return json_build_object('success', false, 'error', 'Payment method is not wallet');
  end if;
  if v_trip.payment_status = 'paid_wallet' or v_trip.payment_status = 'settled' then
    return json_build_object('success', false, 'error', 'Already paid');
  end if;

  select balance into v_passenger_balance from public.wallets where user_id = v_trip.passenger_id;
  if v_passenger_balance is null or v_passenger_balance < v_trip.total_fare then
    return json_build_object('success', false, 'error', 'Insufficient balance',
      'required', v_trip.total_fare, 'balance', coalesce(v_passenger_balance, 0));
  end if;

  -- Deduct from passenger
  update public.wallets set balance = balance - v_trip.total_fare, updated_at = now()
  where user_id = v_trip.passenger_id;

  -- Credit to driver (insert or update)
  insert into public.wallets (user_id, balance)
  values (v_trip.driver_id, v_trip.total_fare)
  on conflict (user_id)
  do update set balance = public.wallets.balance + v_trip.total_fare, updated_at = now();

  -- Record passenger transaction
  insert into public.wallet_transactions (user_id, amount, type, status, description, reference)
  values (v_trip.passenger_id, -v_trip.total_fare, 'trip_payment', 'completed',
    'دفع رحلة - كود: ' || coalesce(v_trip.join_code, ''), p_trip_id::text);

  -- Record driver transaction
  insert into public.wallet_transactions (user_id, amount, type, status, description, reference)
  values (v_trip.driver_id, v_trip.total_fare, 'trip_payment', 'completed',
    'أرباح رحلة - كود: ' || coalesce(v_trip.join_code, ''), p_trip_id::text);

  -- Update trip payment status
  update public.trips
  set payment_status = 'paid_wallet'
  where id = p_trip_id;

  insert into public.trip_events (trip_id, actor_id, event_type, payload)
  values (p_trip_id::text, auth.uid(), 'payment_completed',
    jsonb_build_object('amount', v_trip.total_fare, 'method', 'wallet'));

  return json_build_object('success', true, 'amount', v_trip.total_fare);
end;
$$;

-- Add payment_completed to trip_events event_type check
alter table if exists public.trip_events drop constraint if exists trip_events_event_type_check;
alter table if exists public.trip_events add constraint trip_events_event_type_check
  check (event_type in ('started', 'location', 'pause', 'resume', 'passenger_joined',
    'passenger_left', 'manual_distance', 'completed', 'cancelled', 'price_adjusted',
    'price_proposed', 'passenger_price_accepted', 'passenger_price_rejected',
    'payment_completed'));
