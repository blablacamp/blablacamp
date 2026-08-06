-- Enable Supabase Realtime for the per-hike chat.
-- Postgres Changes on `messages` are broadcast to subscribed clients; RLS
-- (members-only SELECT via is_hike_member) still applies, so users only
-- receive messages for hikes they belong to.

alter publication supabase_realtime add table public.messages;

-- REPLICA IDENTITY FULL so UPDATE/DELETE payloads carry the old row too
-- (not strictly needed for insert-only chat, but future-proofs edits).
alter table public.messages replica identity full;
