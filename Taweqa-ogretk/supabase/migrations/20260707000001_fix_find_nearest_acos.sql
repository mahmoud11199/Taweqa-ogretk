create or replace function public.find_nearest_available_driver(
  pickup_lat double precision,
  pickup_lng double precision,
  exclude_ids uuid[] default '{}'
) returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  driver_record record;
begin
  select d.id, p.full_name,
    (6371 * acos(least(1, greatest(-1,
      cos(radians(pickup_lat)) * cos(radians(d.current_lat)) *
      cos(radians(d.current_lng) - radians(pickup_lng)) +
      sin(radians(pickup_lat)) * sin(radians(d.current_lat))
    )))) as distance_km
  into driver_record
  from drivers d
  join profiles p on p.id = d.id
  where d.is_available = true
    and d.current_lat is not null
    and d.current_lng is not null
    and d.id != all(coalesce(exclude_ids, '{}'))
    and (6371 * acos(least(1, greatest(-1,
      cos(radians(pickup_lat)) * cos(radians(d.current_lat)) *
      cos(radians(d.current_lng) - radians(pickup_lng)) +
      sin(radians(pickup_lat)) * sin(radians(d.current_lat))
    )))) < 10
  order by distance_km
  limit 1;

  if driver_record.id is null then
    return json_build_object('found', false);
  end if;

  return json_build_object(
    'found', true,
    'driver_id', driver_record.id,
    'driver_name', driver_record.full_name,
    'distance_km', round(driver_record.distance_km::numeric, 2)
  );
end;
$$;

grant execute on function public.find_nearest_available_driver to authenticated;
