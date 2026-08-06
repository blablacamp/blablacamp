-- Blablacamp — richer hike detail fields
-- includes:   what a guided price covers / what a shared trip splits
-- highlights: short route bullet points shown as check-rows on the detail screen

alter table public.hikes
  add column if not exists includes   text[] not null default '{}',
  add column if not exists highlights text[] not null default '{}';

comment on column public.hikes.includes is
  'Guided: what the price covers. Shared: what the group shares. Rendered as chips.';
comment on column public.hikes.highlights is
  'Short route highlights, rendered as check-rows on the hike detail screen.';
