-- Blablacamp — route waypoints for the on-map hike route + points.

create table public.hike_waypoints (
  id         uuid        primary key default gen_random_uuid(),
  hike_id    uuid        not null references public.hikes (id) on delete cascade,
  seq        int         not null default 0,
  name       text        not null default '',
  lat        double precision not null,
  lng        double precision not null,
  created_at timestamptz not null default now()
);

create index hike_waypoints_hike_seq_idx on public.hike_waypoints (hike_id, seq);

alter table public.hike_waypoints enable row level security;

create policy "waypoints are viewable by everyone"
  on public.hike_waypoints for select
  using (true);

create policy "organizer manages waypoints"
  on public.hike_waypoints for all
  using (public.is_hike_organizer(hike_id, auth.uid()))
  with check (public.is_hike_organizer(hike_id, auth.uid()));

-- Demo routes for the seeded sample hikes (guarded: only if the hike exists and
-- has no waypoints yet, so re-runs are safe and prod without seed is untouched).
insert into public.hike_waypoints (hike_id, seq, name, lat, lng)
select v.hike_id, v.seq, v.name, v.lat, v.lng
from (values
  -- 001: Chornohora / Hoverla
  ('a0000000-0000-0000-0000-000000000001'::uuid, 0, 'Заросляк',            48.1509, 24.5386),
  ('a0000000-0000-0000-0000-000000000001'::uuid, 1, 'Козьмеска',           48.1545, 24.5200),
  ('a0000000-0000-0000-0000-000000000001'::uuid, 2, 'Перемичка',           48.1580, 24.5080),
  ('a0000000-0000-0000-0000-000000000001'::uuid, 3, 'Вершина Говерли',     48.1601, 24.5001),
  -- 002: Marmarosy / Pip Ivan Marmaroskyi
  ('a0000000-0000-0000-0000-000000000002'::uuid, 0, 'Ділове',              47.9300, 24.1400),
  ('a0000000-0000-0000-0000-000000000002'::uuid, 1, 'Погорілець',          47.9600, 24.2600),
  ('a0000000-0000-0000-0000-000000000002'::uuid, 2, 'Хребет Мармароси',    47.9500, 24.3000),
  ('a0000000-0000-0000-0000-000000000002'::uuid, 3, 'Піп Іван Мармароський',47.9430, 24.3220),
  -- 003: Borzhava ridge
  ('a0000000-0000-0000-0000-000000000003'::uuid, 0, 'Воловець',            48.7080, 23.1900),
  ('a0000000-0000-0000-0000-000000000003'::uuid, 1, 'Плай',                48.6600, 23.1200),
  ('a0000000-0000-0000-0000-000000000003'::uuid, 2, 'Великий Верх',        48.6300, 23.1000),
  ('a0000000-0000-0000-0000-000000000003'::uuid, 3, 'Стій',                48.6800, 23.0800)
) as v(hike_id, seq, name, lat, lng)
where exists (select 1 from public.hikes h where h.id = v.hike_id)
  and not exists (
    select 1 from public.hike_waypoints w where w.hike_id = v.hike_id
  );
