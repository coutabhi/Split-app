#!/usr/bin/env bash
# Builds a throwaway Postgres from schema.sql and runs rls_test.sql against it.
# Needs a local PostgreSQL server (Debian/Ubuntu: apt install postgresql).
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../.." && pwd)
port=${PGPORT_TEST:-55432}
bindir=$(ls -d /usr/lib/postgresql/*/bin 2>/dev/null | tail -1 || true)
[ -n "$bindir" ] && PATH="$bindir:$PATH"
command -v initdb >/dev/null || { echo "no PostgreSQL server binaries found" >&2; exit 1; }

# Postgres refuses to run as root, so as root we drive it as an ordinary user.
owner=""
if [ "$(id -u)" = 0 ]; then
  owner=${PGTEST_USER:-postgres}
  id "$owner" >/dev/null 2>&1 || useradd -m "$owner"
  home=$(getent passwd "$owner" | cut -d: -f6)
  data=$(mktemp -d "$home/rls-test.XXXXXX")
  chown "$owner" "$data"
  as_owner() { su "$owner" -s /bin/bash -c "PATH='$PATH' $1"; }
else
  data=$(mktemp -d)
  as_owner() { bash -c "$1"; }
fi
cleanup() { as_owner "pg_ctl -D '$data' stop -m immediate" >/dev/null 2>&1 || true; rm -rf "$data"; }
trap cleanup EXIT

as_owner "initdb -D '$data' -U postgres --auth=trust" >/dev/null
as_owner "pg_ctl -D '$data' -o '-p $port -k /tmp' -l '$data/log' start" >/dev/null
psql() { command psql -h /tmp -p "$port" -U postgres -v ON_ERROR_STOP=1 "$@"; }
for _ in $(seq 30); do psql -tAc 'select 1' >/dev/null 2>&1 && break; sleep 0.5; done

# Stand in for the pieces of Supabase the schema builds on.
psql -q <<'EOF'
create schema auth;
create table auth.users (id uuid primary key default gen_random_uuid(), email text,
                         raw_user_meta_data jsonb default '{}'::jsonb);
create function auth.uid() returns uuid language sql stable as
  $f$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $f$;
create function auth.role() returns text language sql stable as
  $f$ select coalesce(nullif(current_setting('request.jwt.claim.role', true), ''), 'anon') $f$;
create role authenticated nologin;
grant usage on schema public, auth to authenticated;
EOF

# The realtime publication only exists inside Supabase, so drop that trailing block.
sed '/-- Realtime: let clients subscribe/,$d' "$repo/supabase/schema.sql" > /tmp/rls-schema.$$.sql
psql -q -o /dev/null -f /tmp/rls-schema.$$.sql 2>/dev/null
rm -f /tmp/rls-schema.$$.sql
psql -q -c 'grant select, insert, update, delete on all tables in schema public to authenticated;
            grant execute on all functions in schema public to authenticated;'

psql -q -f "$here/rls_test.sql"
