# OfficeSplit

A Splitwise-style expense splitter with a shared Supabase backend: sign in,
start or join a group with an invite code, and every expense, payment, and
balance syncs live to everyone in it.

## How it works

- **Sign up / sign in** — email + password. Your account is how your team
  sees the same live data.
- **Groups** — start a group (e.g. "Office") and share its invite code with
  colleagues; they join it from the app and instantly see (and add to) the
  same shared expenses and balances, live.
- **Friends** — anyone who shares a group with you shows up here with a
  running balance aggregated across every group you're both in.
- **Add an expense** — description, amount, category, who paid, and how to
  split it:
  - **Equal** — split evenly among selected people
  - **Unequal** — type an exact amount per person
  - **%** — type a percentage per person
  - **Items** — itemize what was ordered and assign each item to whoever
    ordered it (shared items split evenly between assignees)
- **Settle up** — a group's "fewest payments to settle everyone up" list,
  computed with the classic debt-simplification algorithm; tap one to
  record it.
- **Activity** — a chronological feed of every expense and payment across
  all your groups.

## Backend (Supabase)

`supabase/schema.sql` is the full database: profiles (auto-created on
signup), groups joined by invite code, and group-scoped expenses/
settlements, all behind row-level security so only group members can read
or write a group's data, with realtime enabled on every table clients
watch live. See `supabase/SETUP.md` to stand up your own project — it's a
five-minute, no-cost signup. The project URL and anon key then go in
`lib/services/supabase_config.dart` (the anon key is meant to be
public — the schema's RLS policies are what actually protect data).

Those policies are tested. `supabase/test/rls_test.sh` builds a throwaway
PostgreSQL from `schema.sql`, stands in for the pieces of Supabase the
schema builds on, and checks both halves of what RLS is for: that a member
can read and write their group, and that a non-member can do neither. It
runs in CI on every push.

If you created your database from an earlier copy of `schema.sql` and hit
`infinite recursion detected in policy for relation "group_members"`, run
`supabase/fix_rls_recursion.sql` once in the SQL Editor.

## Development

```bash
flutter pub get
flutter run
```

## Building the APK

A GitHub Actions workflow (`.github/workflows/build-apk.yml`) builds a
release APK per CPU architecture on every push and uploads them as a
workflow artifact named `officesplit-release-apk` (and as release assets).
Use `app-arm64-v8a-release.apk` for virtually any phone from the last
several years. You can also build locally:

```bash
flutter build apk --release --split-per-abi
# output: build/app/outputs/flutter-apk/app-<abi>-release.apk
```
