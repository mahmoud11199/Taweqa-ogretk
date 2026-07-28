-- Fix: offer_request_to_driver signature mismatch
-- process_scheduled_rides calls it with uuid[], but migration file changed it to jsonb

create or replace function public.offer_request_to_driver(
  p_request_id uuid,
  p_driver_id uuid,
  p_offered_drivers uuid[] default '{}'::uuid[]
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare v_request record; begin select * into v_request from public.ride_requests where id = p_request_id; if not found then return json_build_object('success', false, 'error', 'Request not found'); end if; if v_request.status <> 'pending' then return json_build_object('success', false, 'error', 'Not pending'); end if; update public.ride_requests set offered_to = p_driver_id, offered_at = now(), offered_drivers = to_jsonb(p_offered_drivers) where id = p_request_id; return json_build_object('success', true, 'driver_id', p_driver_id); end;
$$;

select '✅ offer_request_to_driver signature fixed to accept uuid[]' as info;
