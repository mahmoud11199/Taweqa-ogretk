-- Enable Realtime publication for real-time subscriptions
do $$
begin
  -- Ensure the supabase_realtime publication exists
  create publication if not exists supabase_realtime;
  -- Add ride_requests table for instant request delivery to drivers
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'ride_requests'
  ) then
    alter publication supabase_realtime add table only ride_requests;
  end if;
  -- Add trips table for trip status change notifications
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'trips'
  ) then
    alter publication supabase_realtime add table only trips;
  end if;
end;
$$;
