CREATE OR REPLACE FUNCTION public.sync_active_trips_count()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.drivers SET active_trips_count = (
      SELECT COUNT(*)::int FROM public.trips WHERE driver_id = NEW.driver_id AND status IN ('assigned', 'started')
    ) WHERE id = NEW.driver_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.drivers SET active_trips_count = (
      SELECT COUNT(*)::int FROM public.trips WHERE driver_id = OLD.driver_id AND status IN ('assigned', 'started')
    ) WHERE id = OLD.driver_id;
    RETURN OLD;
  ELSE
    UPDATE public.drivers SET active_trips_count = (
      SELECT COUNT(*)::int FROM public.trips WHERE driver_id = NEW.driver_id AND status IN ('assigned', 'started')
    ) WHERE id = NEW.driver_id;
    RETURN NEW;
  END IF;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_active_trips_count ON public.trips;
CREATE TRIGGER trg_sync_active_trips_count
AFTER INSERT OR UPDATE OF status OR DELETE ON public.trips
FOR EACH ROW EXECUTE FUNCTION public.sync_active_trips_count();
