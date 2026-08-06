#!/usr/bin/env bash
# Convenience launcher with the public client credentials baked in.
# The Supabase publishable (anon) key is safe to ship in the client.
# Add ONESIGNAL_APP_ID once you create a OneSignal app.
set -euo pipefail

flutter run \
  --dart-define=SUPABASE_URL=https://hoytcbozkgdjpqfhimdy.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhveXRjYm96a2dkanBxZmhpbWR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU5MzgyNDUsImV4cCI6MjEwMTUxNDI0NX0.JxhM7TqcBKQYPgepyvmHnvTlx78vQHL1LbMCkfh5y0s \
  --dart-define=ONESIGNAL_APP_ID=e8629160-6025-4820-8bd6-4cf28cac5a23 \
  "$@"
