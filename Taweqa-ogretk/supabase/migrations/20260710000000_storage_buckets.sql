-- ============================================================
--  Create storage buckets for avatars and driver documents
-- ============================================================

-- 1. Avatars bucket
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 2097152, array['image/jpeg', 'image/png', 'image/webp', 'image/gif'])
on conflict (id) do nothing;

-- Avatars: users can only read/update their own avatar
drop policy if exists "Users can view avatars" on storage.objects;
create policy "Users can view avatars"
on storage.objects for select
to public
using (bucket_id = 'avatars');

drop policy if exists "Users can upload own avatar" on storage.objects;
create policy "Users can upload own avatar"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = 'avatars'
);

drop policy if exists "Users can update own avatar" on storage.objects;
create policy "Users can update own avatar"
on storage.objects for update
to authenticated
using (bucket_id = 'avatars' and (storage.foldername(name))[2] = auth.uid()::text)
with check (bucket_id = 'avatars' and (storage.foldername(name))[2] = auth.uid()::text);

-- 2. Driver documents bucket
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('driver-documents', 'driver-documents', true, 10485760, array['image/jpeg', 'image/png', 'image/webp', 'application/pdf', 'video/mp4', 'video/quicktime'])
on conflict (id) do nothing;

drop policy if exists "Anyone can view driver docs" on storage.objects;
create policy "Anyone can view driver docs"
on storage.objects for select
to public
using (bucket_id = 'driver-documents');

drop policy if exists "Drivers can upload own docs" on storage.objects;
create policy "Drivers can upload own docs"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'driver-documents'
  and (storage.foldername(name))[1] = 'driver-docs'
  and (storage.foldername(name))[2] = auth.uid()::text
);
