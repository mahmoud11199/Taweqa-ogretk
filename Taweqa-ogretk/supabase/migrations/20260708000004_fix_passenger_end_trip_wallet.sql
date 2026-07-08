DROP FUNCTION IF EXISTS public.apply_wallet_charge(uuid, double precision);

CREATE OR REPLACE FUNCTION public.apply_wallet_charge(p_user_id uuid, p_amount double precision)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
declare
  v_current_balance double precision;
  v_new_balance double precision;
begin
  if p_amount < 0 then
    select coalesce(balance, 0) into v_current_balance from public.wallets where user_id = p_user_id;
    if v_current_balance + p_amount < 0 then
      return json_build_object('success', false, 'error', 'Balance insufficient', 'balance', v_current_balance);
    end if;
  end if;
  insert into public.wallets (user_id, balance)
  values (p_user_id, p_amount)
  on conflict (user_id)
  do update set balance = public.wallets.balance + p_amount, updated_at = now();
  select coalesce(balance, 0) into v_new_balance from public.wallets where user_id = p_user_id;
  return json_build_object('success', true, 'balance', v_new_balance);
end;
$$;

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
  if v_trip.status not in ('assigned', 'started') then
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
