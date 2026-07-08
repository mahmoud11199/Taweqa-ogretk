-- RPC function to offer a ride request to a specific driver (bypasses RLS via security definer)
create or replace function public.offer_request_to_driver(p_request_id uuid, p_driver_id uuid, p_offered_drivers jsonb default '[]'::jsonb)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_request record;
begin
  select * into v_request from public.ride_requests where id = p_request_id;
  if not found then
    return json_build_object('success', false, 'error', 'الطلب غير موجود');
  end if;
  if v_request.status <> 'pending' then
    return json_build_object('success', false, 'error', 'الطلب لم يعد قيد الانتظار');
  end if;
  update public.ride_requests
  set offered_to = p_driver_id,
      offered_at = now(),
      offered_drivers = p_offered_drivers
  where id = p_request_id;
  return json_build_object('success', true, 'driver_id', p_driver_id);
end;
$$;
