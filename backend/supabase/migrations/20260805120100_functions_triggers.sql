-- Blablacamp — functions & triggers

-- ---------------------------------------------------------------------------
-- updated_at maintenance
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

create trigger hikes_set_updated_at
  before update on public.hikes
  for each row execute function public.set_updated_at();

create trigger hike_participants_set_updated_at
  before update on public.hike_participants
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Auto-create a profile row when a new auth user signs up.
-- display_name / default_role can be passed via signUp options.data (raw_user_meta_data).
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, default_role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1), ''),
    coalesce(new.raw_user_meta_data ->> 'default_role', 'campmate')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- When a hike is created, register its organizer as an approved participant.
-- Keeps membership queries uniform (organizer is just an approved 'organizer' row).
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_hike()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.hike_participants (hike_id, user_id, role, status)
  values (new.id, new.organizer_id, 'organizer', 'approved')
  on conflict (hike_id, user_id) do nothing;
  return new;
end;
$$;

create trigger on_hike_created
  after insert on public.hikes
  for each row execute function public.handle_new_hike();

-- ---------------------------------------------------------------------------
-- Helper: is the given user an approved member (incl. organizer) of a hike?
-- SECURITY DEFINER so it can be used inside RLS policies without recursion.
-- ---------------------------------------------------------------------------
create or replace function public.is_hike_member(p_hike_id uuid, p_user_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.hike_participants hp
    where hp.hike_id = p_hike_id
      and hp.user_id = p_user_id
      and hp.status  = 'approved'
  );
$$;

create or replace function public.is_hike_organizer(p_hike_id uuid, p_user_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.hikes h
    where h.id = p_hike_id
      and h.organizer_id = p_user_id
  );
$$;
