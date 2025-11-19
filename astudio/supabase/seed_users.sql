-- Seed demo staff accounts (admin/editor/viewer)
-- Run after schema.sql inside Supabase SQL editor (authenticated with service role)

-- Helper to create a user if it does not exist
create or replace function public._seed_user(
  p_email text,
  p_password text,
  p_full_name text,
  p_role text
) returns void language plpgsql security definer as $$
declare
  _data jsonb := jsonb_build_object(
    'full_name', p_full_name,
    'account_role', p_role
  );
begin
  if not exists (select 1 from auth.users where email = p_email) then
    perform auth.sign_up(
      email => p_email,
      password => p_password,
      data => _data
    );
  end if;
end;
$$;

select public._seed_user('admin@actorstudio.global', 'Admin@123', 'Platform Admin', 'admin');
select public._seed_user('editor@actorstudio.global', 'Editor@123', 'Content Editor', 'editor');
select public._seed_user('viewer@actorstudio.global', 'Viewer@123', 'Internal Viewer', 'viewer');

drop function if exists public._seed_user(text, text, text, text);

insert into public.profiles (
  id,
  email,
  full_name,
  account_role,
  status,
  is_visible,
  approved_by,
  approved_at,
  created_at,
  updated_at
)
select
  u.id,
  u.email,
  coalesce(u.raw_user_meta_data->>'full_name', split_part(u.email, '@', 1)),
  coalesce((u.raw_user_meta_data->>'account_role')::account_role, 'viewer'::account_role),
  'approved',
  true,
  u.id,
  now(),
  now(),
  now()
from auth.users u
where u.email in (
  'admin@actorstudio.global',
  'editor@actorstudio.global',
  'viewer@actorstudio.global'
)
on conflict (id) do update set
  account_role = excluded.account_role,
  status = excluded.status,
  is_visible = excluded.is_visible,
  approved_by = excluded.approved_by,
  approved_at = excluded.approved_at,
  updated_at = now();

