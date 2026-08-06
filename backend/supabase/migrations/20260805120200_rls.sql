-- Blablacamp — Row Level Security
-- Every table is locked down by default; policies below grant the minimum needed.

alter table public.profiles          enable row level security;
alter table public.hikes             enable row level security;
alter table public.hike_participants enable row level security;
alter table public.hike_itinerary    enable row level security;
alter table public.checklist_items   enable row level security;
alter table public.favorites         enable row level security;
alter table public.messages          enable row level security;

-- ---------------------------------------------------------------------------
-- profiles: public read, self write
-- ---------------------------------------------------------------------------
create policy "profiles are viewable by everyone"
  on public.profiles for select
  using (true);

create policy "users can insert their own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- ---------------------------------------------------------------------------
-- hikes: open hikes visible to all; organizer sees own drafts; organizer writes
-- ---------------------------------------------------------------------------
create policy "published hikes are viewable by everyone"
  on public.hikes for select
  using (status <> 'draft' or organizer_id = auth.uid());

create policy "users can create hikes they organize"
  on public.hikes for insert
  with check (organizer_id = auth.uid());

create policy "organizers can update their hikes"
  on public.hikes for update
  using (organizer_id = auth.uid())
  with check (organizer_id = auth.uid());

create policy "organizers can delete their hikes"
  on public.hikes for delete
  using (organizer_id = auth.uid());

-- ---------------------------------------------------------------------------
-- hike_participants: participant sees own rows; organizer sees all for the hike
-- ---------------------------------------------------------------------------
create policy "participants and organizers can view participation"
  on public.hike_participants for select
  using (user_id = auth.uid() or public.is_hike_organizer(hike_id, auth.uid()));

-- a user requests to join (their own row, always starts pending/member)
create policy "users can request to join a hike"
  on public.hike_participants for insert
  with check (
    user_id = auth.uid()
    and role = 'member'
    and status = 'pending'
  );

-- organizer approves/rejects; user can cancel their own request
create policy "organizer manages requests, user cancels own"
  on public.hike_participants for update
  using (user_id = auth.uid() or public.is_hike_organizer(hike_id, auth.uid()))
  with check (user_id = auth.uid() or public.is_hike_organizer(hike_id, auth.uid()));

create policy "user or organizer can remove participation"
  on public.hike_participants for delete
  using (user_id = auth.uid() or public.is_hike_organizer(hike_id, auth.uid()));

-- ---------------------------------------------------------------------------
-- hike_itinerary: readable with the hike, editable by organizer
-- ---------------------------------------------------------------------------
create policy "itinerary viewable by everyone"
  on public.hike_itinerary for select
  using (true);

create policy "organizer manages itinerary"
  on public.hike_itinerary for all
  using (public.is_hike_organizer(hike_id, auth.uid()))
  with check (public.is_hike_organizer(hike_id, auth.uid()));

-- ---------------------------------------------------------------------------
-- checklist_items: strictly private to the owning user
-- ---------------------------------------------------------------------------
create policy "users manage their own checklist"
  on public.checklist_items for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- favorites: strictly private to the owning user
-- ---------------------------------------------------------------------------
create policy "users manage their own favorites"
  on public.favorites for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- messages: only approved members of the hike can read/write
-- ---------------------------------------------------------------------------
create policy "members can read hike messages"
  on public.messages for select
  using (public.is_hike_member(hike_id, auth.uid()));

create policy "members can post hike messages"
  on public.messages for insert
  with check (sender_id = auth.uid() and public.is_hike_member(hike_id, auth.uid()));
