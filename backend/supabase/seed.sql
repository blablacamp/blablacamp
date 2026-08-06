-- Blablacamp — demo seed data
-- Creates two auth users (profiles are auto-created by the on_auth_user_created trigger),
-- then a few hikes of each type with itinerary and participants.
--
-- Demo logins:
--   olena@blablacamp.dev  / password123   (campmaker / guide)
--   taras@blablacamp.dev  / password123   (campmate)
--
-- Safe to run repeatedly: uses fixed UUIDs + ON CONFLICT.

-- ---- auth users -----------------------------------------------------------
insert into auth.users (
  id, instance_id, aud, role, email,
  encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at
)
values
  ('11111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'olena@blablacamp.dev',
   extensions.crypt('password123', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}',
   '{"display_name":"Олена Гірська","default_role":"campmaker"}',
   now(), now()),
  ('22222222-2222-2222-2222-222222222222', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'taras@blablacamp.dev',
   extensions.crypt('password123', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}',
   '{"display_name":"Тарас Мандрівник","default_role":"campmate"}',
   now(), now())
on conflict (id) do nothing;

-- identities are required for email/password login
insert into auth.identities (
  id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at
)
values
  ('11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111',
   '11111111-1111-1111-1111-111111111111',
   '{"sub":"11111111-1111-1111-1111-111111111111","email":"olena@blablacamp.dev"}',
   'email', now(), now(), now()),
  ('22222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222',
   '22222222-2222-2222-2222-222222222222',
   '{"sub":"22222222-2222-2222-2222-222222222222","email":"taras@blablacamp.dev"}',
   'email', now(), now(), now())
on conflict (id) do nothing;

update public.profiles
   set bio = 'Гід із 8-річним досвідом. Карпати знаю як свої п’ять пальців.'
 where id = '11111111-1111-1111-1111-111111111111';

-- ---- hikes ----------------------------------------------------------------
insert into public.hikes (
  id, organizer_id, type, title, summary, description, region, location,
  start_date, end_date, difficulty, distance_km, duration_days,
  max_participants, price_cents, currency, status
)
values
  ('a0000000-0000-0000-0000-000000000001',
   '11111111-1111-1111-1111-111111111111', 'guided',
   'Говерла на світанку',
   'Зустріти схід сонця на найвищій вершині України.',
   'Класичний маршрут із ночівлею в наметах під Петросом. Гід, гаряча їжа, трансфер зі Львова.',
   'Карпати', 'Львів (трансфер)',
   date '2026-08-22', date '2026-08-24', 'moderate', 28.0, 3,
   10, 240000, 'UAH', 'open'),
  ('a0000000-0000-0000-0000-000000000002',
   '11111111-1111-1111-1111-111111111111', 'guided',
   'Мармароси: дикий хребет',
   'Багатоденний трек уздовж українсько-румунського кордону.',
   'Автономний похід для підготовлених. Складний рельєф, неймовірні краєвиди.',
   'Карпати', 'Ділове',
   date '2026-09-05', date '2026-09-09', 'hard', 62.0, 5,
   8, 450000, 'UAH', 'open'),
  ('a0000000-0000-0000-0000-000000000003',
   '22222222-2222-2222-2222-222222222222', 'shared',
   'Вихідні на Чорногорі',
   'Шукаю компанію на легкий похід без гіда.',
   'Ділимо витрати на трансфер і газ. Свій намет і спальник обов’язково.',
   'Карпати', 'Івано-Франківськ',
   date '2026-08-16', date '2026-08-17', 'easy', 18.0, 2,
   6, 0, 'UAH', 'open')
on conflict (id) do nothing;

-- ---- itinerary for the guided Goverla hike --------------------------------
insert into public.hike_itinerary (hike_id, day_num, title, description)
values
  ('a0000000-0000-0000-0000-000000000001', 1, 'Трансфер і підхід',
   'Виїзд зі Львова, підхід до підніжжя, встановлення табору.'),
  ('a0000000-0000-0000-0000-000000000001', 2, 'Сходження на Говерлу',
   'Ранній підйом, сходження на вершину на світанку, повернення в табір.'),
  ('a0000000-0000-0000-0000-000000000001', 3, 'Спуск і повернення',
   'Збір табору, спуск, трансфер до Львова.')
on conflict (hike_id, day_num) do nothing;

-- ---- participation: Taras requests to join the Goverla hike ----------------
insert into public.hike_participants (hike_id, user_id, role, status)
values
  ('a0000000-0000-0000-0000-000000000001',
   '22222222-2222-2222-2222-222222222222', 'member', 'pending')
on conflict (hike_id, user_id) do nothing;

-- ---- itinerary for the Marmarosy guided hike -------------------------------
insert into public.hike_itinerary (hike_id, day_num, title, description)
values
  ('a0000000-0000-0000-0000-000000000002', 1, 'Старт від Ділового',
   'Реєстрація, підхід до полонини, перший табір.'),
  ('a0000000-0000-0000-0000-000000000002', 2, 'Хребет Поп Іван Мармароський',
   'Вихід на прикордонний хребет, панорами двох країн.'),
  ('a0000000-0000-0000-0000-000000000002', 3, 'Дикі озера',
   'Траверс до льодовикових озер, днювання.'),
  ('a0000000-0000-0000-0000-000000000002', 4, 'Резервний день',
   'Запас на негоду або радіальний вихід.'),
  ('a0000000-0000-0000-0000-000000000002', 5, 'Спуск і трансфер',
   'Спуск у долину, трансфер назад.')
on conflict (hike_id, day_num) do nothing;

-- ---- includes / highlights -------------------------------------------------
update public.hikes set
  includes   = array['Трансфер','Ночівля','Гаряча їжа','Супровід гіда'],
  highlights = array['Схід сонця на вершині','Перевірений маршрут','Групи до 10 осіб']
where id = 'a0000000-0000-0000-0000-000000000001';

update public.hikes set
  includes   = array['Трансфер','Реєстрація','Супровід гіда','Аптечка'],
  highlights = array['Дикий прикордонний хребет','Льодовикові озера','Резервний день на негоду']
where id = 'a0000000-0000-0000-0000-000000000002';

update public.hikes set
  includes   = array['Спільний трансфер','Газ і пальник','Груповий намет'],
  highlights = array['Спокійний темп','Багаття ввечері','Без комісії організатору']
where id = 'a0000000-0000-0000-0000-000000000003';
