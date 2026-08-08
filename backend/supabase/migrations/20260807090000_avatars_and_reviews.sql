-- Blablacamp — avatars storage bucket + user reviews

-- ---------------------------------------------------------------------------
-- Avatars bucket (public read; a user may write only under their own uid/ path)
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

create policy "avatars are publicly readable"
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy "users upload their own avatar"
  on storage.objects for insert
  with check (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "users update their own avatar"
  on storage.objects for update
  using (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- ---------------------------------------------------------------------------
-- reviews: one member rates another after a hike
-- ---------------------------------------------------------------------------
create table public.reviews (
  id         uuid        primary key default gen_random_uuid(),
  subject_id uuid        not null references public.profiles (id) on delete cascade,
  author_id  uuid        not null references public.profiles (id) on delete cascade,
  hike_id    uuid        references public.hikes (id) on delete set null,
  rating     int         not null check (rating between 1 and 5),
  body       text,
  created_at timestamptz not null default now(),

  constraint reviews_no_self check (author_id <> subject_id),
  unique (author_id, subject_id, hike_id)
);

create index reviews_subject_idx on public.reviews (subject_id, created_at desc);

alter table public.reviews enable row level security;

create policy "reviews are viewable by everyone"
  on public.reviews for select
  using (true);

create policy "users write reviews as themselves"
  on public.reviews for insert
  with check (author_id = auth.uid() and author_id <> subject_id);

create policy "authors can edit their reviews"
  on public.reviews for update
  using (author_id = auth.uid())
  with check (author_id = auth.uid());
