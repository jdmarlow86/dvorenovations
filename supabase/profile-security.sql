-- Van Ornum Renovations: safe profile password-change bookkeeping
-- Run as a NEW query after schema.sql and the employer profile setup.
create or replace function public.guard_profile_self_update()
returns trigger language plpgsql
set search_path = public
as $$
begin
  if public.current_user_is_employer() then
    return new;
  end if;
  if old.id <> auth.uid()
     or new.id <> old.id
     or new.username <> old.username
     or new.role <> old.role
     or new.active <> old.active
     or new.created_at <> old.created_at then
    raise exception 'Profile fields cannot be changed by this account';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_guard_self_update on public.profiles;
create trigger profiles_guard_self_update
before update on public.profiles
for each row execute function public.guard_profile_self_update();

drop policy if exists "users update own password flag" on public.profiles;
create policy "users update own password flag" on public.profiles
for update to authenticated
using (id = auth.uid())
with check (id = auth.uid());

-- Add an RPC that lets the signed-in user clear the first-login flag only.
create or replace function public.mark_password_changed()
returns void language plpgsql security definer
set search_path = public
as $$
begin
  update public.profiles
  set must_change_password = false
  where id = auth.uid() and active = true;
  if not found then raise exception 'Active profile not found'; end if;
end;
$$;
revoke all on function public.mark_password_changed() from public, anon;
grant execute on function public.mark_password_changed() to authenticated;
