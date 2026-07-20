-- إصلاح infinite recursion (42P17) في RLS لجدول profiles
-- السبب: سياسات تحتوي على subquery يستعلم من profiles نفسه

-- 1. إسقاط كل السياسات التي تسبب recursion
drop policy if exists "profiles_admin_all" on public.profiles;
drop policy if exists "Admins can update any profile" on public.profiles;
drop policy if exists "Public profiles are viewable by everyone" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;
drop policy if exists "profiles_update_own" on public.profiles;
drop policy if exists "profiles_select_own" on public.profiles;

-- 2. إنشاء سياسات بسيطة ومباشرة
create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- 3. الإبقاء على سياسة INSERT الموجودة (مطلوبة لتسجيل المستخدمين الجدد)
-- Users can insert their own profile -> باقية كما هي
