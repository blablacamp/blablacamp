-- Blablacamp — rich chat: message kinds, attachments, and a chat bucket.

-- ---------------------------------------------------------------------------
-- messages: support image / file / contact messages alongside plain text.
-- ---------------------------------------------------------------------------
alter table public.messages
  add column if not exists kind text not null default 'text'
    check (kind in ('text', 'image', 'file', 'contact')),
  add column if not exists attachment_url  text,
  add column if not exists attachment_name text,
  add column if not exists meta jsonb;

-- The original constraint required a non-empty body. Attachments/contacts can
-- have an empty body (the payload lives in attachment_url / meta).
alter table public.messages drop constraint if exists messages_body_check;
alter table public.messages
  add constraint messages_body_check check (
    kind <> 'text' or length(trim(body)) > 0
  );
alter table public.messages alter column body set default '';

-- ---------------------------------------------------------------------------
-- chat bucket: private-ish public-read bucket for chat photos/files. Only
-- members (or the organizer) of the hike may upload under that hike's folder.
-- Path convention: {hike_id}/{uid}/{timestamp}_{filename}
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('chat', 'chat', true)
on conflict (id) do nothing;

-- Public read (served via getPublicUrl, same as avatars). Uploads are the
-- gated part; the URLs themselves are unguessable (timestamped filenames).
create policy "chat attachments are publicly readable"
  on storage.objects for select
  using (bucket_id = 'chat');

create policy "members upload chat attachments"
  on storage.objects for insert
  with check (
    bucket_id = 'chat'
    and auth.uid()::text = (storage.foldername(name))[2]
    and (
      public.is_hike_member((storage.foldername(name))[1]::uuid, auth.uid())
      or public.is_hike_organizer((storage.foldername(name))[1]::uuid, auth.uid())
    )
  );
