-- Blablacamp — initial schema
-- Domain: a "carpooling for hikes" app. Users find a hike to join or organize one.
-- Two hike types:
--   * guided  — organized by a guide (campmaker), usually paid
--   * shared  — peer trip, no fee, participants share costs/gear
--
-- Conventions:
--   * all PKs are uuid (gen_random_uuid)
--   * timestamps are timestamptz, set/maintained by triggers
--   * status/role/type are text + CHECK for MVP flexibility (cheap to extend)

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- profiles: 1:1 with auth.users, auto-created on signup (see handle_new_user)
-- ---------------------------------------------------------------------------
create table public.profiles (
  id            uuid primary key references auth.users (id) on delete cascade,
  display_name  text        not null default '',
  avatar_url    text,
  bio           text,
  -- role chosen on onboarding; a user can still do both, this is just the default lens
  default_role  text        not null default 'campmate'
                  check (default_role in ('campmate', 'campmaker')),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

comment on table public.profiles is 'Public user profile, 1:1 with auth.users.';
comment on column public.profiles.default_role is 'campmate = joins hikes, campmaker = organizes.';

-- ---------------------------------------------------------------------------
-- hikes: the core listing
-- ---------------------------------------------------------------------------
create table public.hikes (
  id               uuid primary key default gen_random_uuid(),
  organizer_id     uuid        not null references public.profiles (id) on delete cascade,
  type             text        not null
                     check (type in ('guided', 'shared')),
  title            text        not null,
  summary          text,                 -- "why this hike" editorial statement
  description      text,                 -- field-note / longer body
  cover_url        text,
  region           text,                 -- e.g. "Карпати"
  location         text,                 -- start point / meeting place
  start_date       date,
  end_date         date,
  difficulty       text        not null default 'moderate'
                     check (difficulty in ('easy', 'moderate', 'hard', 'expert')),
  distance_km      numeric(6, 1),
  duration_days    int         not null default 1 check (duration_days > 0),
  max_participants int         not null default 8 check (max_participants > 0),
  -- price is 0 for shared hikes; kept in minor units to avoid float money
  price_cents      int         not null default 0 check (price_cents >= 0),
  currency         text        not null default 'UAH',
  status           text        not null default 'open'
                     check (status in ('draft', 'open', 'full', 'completed', 'cancelled')),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),

  constraint hikes_dates_ordered check (end_date is null or start_date is null or end_date >= start_date),
  constraint hikes_shared_is_free check (type <> 'shared' or price_cents = 0)
);

create index hikes_status_start_idx on public.hikes (status, start_date);
create index hikes_type_idx         on public.hikes (type);
create index hikes_organizer_idx    on public.hikes (organizer_id);
create index hikes_region_idx       on public.hikes (region);

comment on table public.hikes is 'A hike listing, either guided (paid) or shared (peer, free).';

-- ---------------------------------------------------------------------------
-- hike_participants: join requests + memberships
-- The organizer row is created automatically on hike insert (see trigger).
-- ---------------------------------------------------------------------------
create table public.hike_participants (
  id         uuid        primary key default gen_random_uuid(),
  hike_id    uuid        not null references public.hikes (id) on delete cascade,
  user_id    uuid        not null references public.profiles (id) on delete cascade,
  role       text        not null default 'member'
               check (role in ('organizer', 'member')),
  status     text        not null default 'pending'
               check (status in ('pending', 'approved', 'rejected', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  unique (hike_id, user_id)
);

create index hike_participants_hike_idx on public.hike_participants (hike_id, status);
create index hike_participants_user_idx on public.hike_participants (user_id, status);

comment on table public.hike_participants is 'Membership + join requests. status flows pending -> approved/rejected.';

-- ---------------------------------------------------------------------------
-- hike_itinerary: day-by-day plan (mostly for guided hikes)
-- ---------------------------------------------------------------------------
create table public.hike_itinerary (
  id          uuid        primary key default gen_random_uuid(),
  hike_id     uuid        not null references public.hikes (id) on delete cascade,
  day_num     int         not null check (day_num > 0),
  title       text        not null,
  description text,
  unique (hike_id, day_num)
);

create index hike_itinerary_hike_idx on public.hike_itinerary (hike_id, day_num);

-- ---------------------------------------------------------------------------
-- checklist_items: the "backpack" gear checklist, per hike per user
-- Categories seen in design: Ночівля / Одяг / Спорядження
-- ---------------------------------------------------------------------------
create table public.checklist_items (
  id         uuid        primary key default gen_random_uuid(),
  hike_id    uuid        not null references public.hikes (id) on delete cascade,
  user_id    uuid        not null references public.profiles (id) on delete cascade,
  category   text        not null,
  name       text        not null,
  spec       text,                 -- e.g. "2-місцевий, 3-сезонний"
  status     text        not null default 'todo'
               check (status in ('todo', 'packed', 'shared')),
  created_at timestamptz not null default now()
);

create index checklist_items_hike_user_idx on public.checklist_items (hike_id, user_id);

-- ---------------------------------------------------------------------------
-- favorites: the "Обране" tab
-- ---------------------------------------------------------------------------
create table public.favorites (
  user_id    uuid        not null references public.profiles (id) on delete cascade,
  hike_id    uuid        not null references public.hikes (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, hike_id)
);

-- ---------------------------------------------------------------------------
-- messages: simple per-hike chat (the "Повідомлення" tab)
-- ---------------------------------------------------------------------------
create table public.messages (
  id         uuid        primary key default gen_random_uuid(),
  hike_id    uuid        not null references public.hikes (id) on delete cascade,
  sender_id  uuid        not null references public.profiles (id) on delete cascade,
  body       text        not null check (length(trim(body)) > 0),
  created_at timestamptz not null default now()
);

create index messages_hike_created_idx on public.messages (hike_id, created_at);
