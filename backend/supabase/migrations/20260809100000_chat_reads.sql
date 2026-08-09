-- Blablacamp — unread tracking for chat (badge on Повідомлення).

create table public.chat_reads (
  user_id      uuid        not null references public.profiles (id) on delete cascade,
  hike_id      uuid        not null references public.hikes (id) on delete cascade,
  last_read_at timestamptz not null default now(),
  primary key (user_id, hike_id)
);

alter table public.chat_reads enable row level security;

create policy "users manage their own read marks"
  on public.chat_reads for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Number of conversations (hikes) with at least one unread message from
-- someone else, for the current user.
create or replace function public.unread_conversation_count()
returns int
language sql
security definer
set search_path = public
stable
as $$
  select count(*)::int from (
    select m.hike_id
    from public.messages m
    where m.sender_id <> auth.uid()
      and (
        public.is_hike_member(m.hike_id, auth.uid())
        or public.is_hike_organizer(m.hike_id, auth.uid())
      )
      and m.created_at > coalesce(
        (select r.last_read_at
           from public.chat_reads r
          where r.user_id = auth.uid() and r.hike_id = m.hike_id),
        'epoch'::timestamptz)
    group by m.hike_id
  ) t;
$$;
