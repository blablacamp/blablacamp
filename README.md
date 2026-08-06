# Blablacamp

"BlaBlaCar for hikes" — find a hike to join, or organize your own. MVP.

- **frontend/** — Flutter app (Bloc + go_router + supabase_flutter)
- **backend/** — Supabase project (Postgres schema, RLS, seed, edge functions)
- **docs/** — design & data-model notes

## Domain in one paragraph

Users pick a role on onboarding — **campmate** (join a hike) or **campmaker**
(organize one). A **hike** is either `guided` (led by a guide, usually paid) or
`shared` (peer trip, free, costs/gear split). Campmates send join requests
(`hike_participants`, pending → approved/rejected); each hike has an itinerary,
a per-user gear **checklist** (the "backpack"), favorites, and a simple per-hike
chat.

## Backend (Supabase)

Schema lives in `backend/supabase/migrations`, demo data in `seed.sql`.

### Link the cloud project (one-time)

```bash
supabase login                          # opens a browser
supabase link --project-ref <ref>       # from your project's dashboard
```

### Push schema + seed

```bash
cd backend
supabase db push                        # applies migrations to the cloud DB
psql "$SUPABASE_DB_URL" -f supabase/seed.sql   # optional demo data
```

### Or run fully local (needs Docker running)

```bash
cd backend
supabase start                          # local Postgres/Auth/Storage + Studio
```

Demo logins (after seeding): `olena@blablacamp.dev` / `password123` (campmaker),
`taras@blablacamp.dev` / `password123` (campmate).

## Frontend (Flutter)

Supabase keys are passed at build time (only the public anon/publishable key):

```bash
cd frontend
flutter run \
  --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

The app also runs without keys (UI-only preview) — Supabase is wired only when
both defines are present.

```bash
flutter analyze
flutter test
```

## Notifications (OneSignal)

Push + email + in-app via OneSignal. Client wrapper in
`frontend/lib/core/notifications/`; server sends through the `notify` edge
function (`backend/supabase/functions/notify`).

```bash
# one-time, after creating a OneSignal app:
supabase secrets set ONESIGNAL_APP_ID=... ONESIGNAL_REST_API_KEY=...
supabase functions deploy notify
# run the app with the public app id:
flutter run --dart-define=ONESIGNAL_APP_ID=...
```

## Status

- [x] Repo scaffold, theme tokens (Manrope + Unbounded), asset pipeline
- [x] Supabase schema, triggers, RLS, seed — **deployed to cloud**
- [x] Onboarding, Home, Search, adaptive Hike details (join request wired)
- [x] OneSignal scaffold (client + `notify` edge function)
- [ ] Backpack screen; pixel-refine detail sections
- [ ] Auth flow (email) + router redirects
- [ ] Set OneSignal secrets & deploy the function
