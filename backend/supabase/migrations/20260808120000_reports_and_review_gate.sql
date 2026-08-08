-- Blablacamp — reports/moderation + tighter review rules

-- ---------------------------------------------------------------------------
-- reports: users flag hikes / users / messages for moderation
-- ---------------------------------------------------------------------------
create table public.reports (
  id          uuid        primary key default gen_random_uuid(),
  reporter_id uuid        not null references public.profiles (id) on delete cascade,
  target_type text        not null check (target_type in ('hike', 'user', 'message')),
  target_id   uuid        not null,
  hike_id     uuid        references public.hikes (id) on delete set null,
  reason      text        not null
                check (reason in ('spam', 'scam', 'unsafe', 'harassment', 'other')),
  details     text,
  status      text        not null default 'open'
                check (status in ('open', 'reviewing', 'resolved', 'dismissed')),
  created_at  timestamptz not null default now(),
  unique (reporter_id, target_type, target_id)
);

create index reports_status_idx on public.reports (status, created_at desc);

alter table public.reports enable row level security;

create policy "users file reports as themselves"
  on public.reports for insert
  with check (reporter_id = auth.uid());

create policy "users read their own reports"
  on public.reports for select
  using (reporter_id = auth.uid());

-- Soft takedown flag (flipped by an admin out-of-band); hidden hikes drop out
-- of search/feed.
alter table public.hikes
  add column if not exists is_hidden boolean not null default false;

-- ---------------------------------------------------------------------------
-- Tighten reviews: only an approved participant of a hike that has already
-- happened may review, and only about someone from that hike.
-- ---------------------------------------------------------------------------
drop policy if exists "users write reviews as themselves" on public.reviews;

create policy "reviews only by approved participants after the hike"
  on public.reviews for insert
  with check (
    author_id = auth.uid()
    and author_id <> subject_id
    and hike_id is not null
    and exists (
      select 1
      from public.hike_participants hp
      join public.hikes h on h.id = hp.hike_id
      where hp.hike_id = reviews.hike_id
        and hp.user_id = auth.uid()
        and hp.status = 'approved'
        and coalesce(h.end_date, h.start_date) <= (now() at time zone 'utc')::date
    )
  );
