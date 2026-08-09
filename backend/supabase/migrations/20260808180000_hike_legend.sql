-- Blablacamp — "Легенда цих гір": short Carpathian lore per hike (a Galician
-- touch shown on the hike page).

alter table public.hikes add column if not exists legend text;

-- Seed legends for the sample hikes (guarded so re-runs / seedless prod are ok).
update public.hikes set legend =
  'Кажуть, що назва Говерли — від «гори, вкритої снігом». Опришки вірили: хто зустріне світанок на вершині, тому цілий рік ведеться в дорозі.'
where id = 'a0000000-0000-0000-0000-000000000001' and legend is null;

update public.hikes set legend =
  'На Мармароських хребтах, за переказами, ще з часів Русі пастухи-вівчарі перегукувалися трембітами через долини — так звістка про негоду летіла швидше за вітер.'
where id = 'a0000000-0000-0000-0000-000000000002' and legend is null;

update public.hikes set legend =
  'Боржаву називають «полониною вітрів». Старі ґазди кажуть: якщо на Стої заграє туман — то мольфар кличе дощ, і треба чемно попросити гору пустити далі.'
where id = 'a0000000-0000-0000-0000-000000000003' and legend is null;
