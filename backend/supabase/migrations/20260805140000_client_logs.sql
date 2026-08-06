-- Blablacamp — client-side log sink
-- The Flutter app streams structured logs here (errors, key events) so we can
-- debug issues like auth failures without a device attached.

create table public.client_logs (
  id         uuid        primary key default gen_random_uuid(),
  user_id    uuid        references auth.users (id) on delete set null,
  level      text        not null default 'info'
               check (level in ('debug', 'info', 'warn', 'error')),
  tag        text,                 -- e.g. "auth", "hikes", "router"
  message    text        not null,
  context    jsonb       not null default '{}',
  platform   text,                 -- android / ios / etc.
  created_at timestamptz not null default now()
);

create index client_logs_created_idx on public.client_logs (created_at desc);
create index client_logs_level_idx   on public.client_logs (level, created_at desc);
create index client_logs_user_idx    on public.client_logs (user_id, created_at desc);

alter table public.client_logs enable row level security;

-- Anyone (even anonymous, pre-login) may write logs — that's the whole point.
create policy "anyone can insert logs"
  on public.client_logs for insert
  with check (true);

-- A signed-in user may read back only their own log rows.
create policy "users read their own logs"
  on public.client_logs for select
  using (auth.uid() = user_id);
