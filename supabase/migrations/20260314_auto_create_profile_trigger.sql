-- Auto-create a profiles row when a new auth user is created.
-- This guarantees atomicity at the database level — no orphaned auth users.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, email, full_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1))
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
-- Drop existing trigger if it exists (idempotent)
drop trigger if exists on_auth_user_created on auth.users;
-- Create trigger
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
