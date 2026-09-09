-- OfficeSplit — Supabase schema
-- Run this once in your Supabase project's SQL Editor (Dashboard → SQL Editor → New query → paste → Run).
-- Safe to re-run: every statement is idempotent.

-- ============================================================
-- Profiles: one row per signed-up user, auto-created on signup
-- ============================================================
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null,
  color_value bigint not null,
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, name, color_value)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', split_part(new.email, '@', 1)),
    -- matches the app's kPersonPalette (0xFFxxxxxx as a plain positive int)
    (array[
      4281051284, 4293483114, 4294946875, 4285291751, 4282097151,
      4294937265, 4281975914, 4294933061, 4288442111, 4279742631
    ])[1 + (abs(hashtext(new.id::text)) % 10)]
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================
-- Groups + membership
-- ============================================================
create table if not exists public.groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  color_value bigint not null,
  invite_code text not null unique,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now()
);

create table if not exists public.group_members (
  group_id uuid not null references public.groups (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

-- Join a group by its invite code (bypasses RLS safely via security definer,
-- since a non-member can't SELECT a group row directly).
create or replace function public.join_group_by_code(p_code text)
returns uuid
language plpgsql
security definer set search_path = public
as $$
declare
  v_group_id uuid;
begin
  select id into v_group_id from public.groups where invite_code = upper(p_code);
  if v_group_id is null then
    raise exception 'Invalid invite code';
  end if;
  insert into public.group_members (group_id, user_id)
  values (v_group_id, auth.uid())
  on conflict do nothing;
  return v_group_id;
end;
$$;

-- ============================================================
-- Expenses + settlements
-- ============================================================
create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  description text not null,
  amount numeric not null,
  paid_by uuid not null references public.profiles (id),
  split_type text not null,
  shares jsonb not null,
  participant_ids uuid[] not null,
  category text not null default 'general',
  items jsonb not null default '[]',
  date timestamptz not null default now(),
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now()
);

create table if not exists public.settlements (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  from_id uuid not null references public.profiles (id),
  to_id uuid not null references public.profiles (id),
  amount numeric not null,
  note text not null default '',
  date timestamptz not null default now(),
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now()
);

-- ============================================================
-- Row Level Security
-- ============================================================
alter table public.profiles enable row level security;
alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.expenses enable row level security;
alter table public.settlements enable row level security;

drop policy if exists "profiles viewable by authenticated users" on public.profiles;
create policy "profiles viewable by authenticated users" on public.profiles
  for select using (auth.role() = 'authenticated');

drop policy if exists "users update own profile" on public.profiles;
create policy "users update own profile" on public.profiles
  for update using (auth.uid() = id);

drop policy if exists "members view their groups" on public.groups;
create policy "members view their groups" on public.groups
  for select using (
    exists (select 1 from public.group_members gm where gm.group_id = id and gm.user_id = auth.uid())
  );

drop policy if exists "authenticated users create groups" on public.groups;
create policy "authenticated users create groups" on public.groups
  for insert with check (auth.uid() = created_by);

drop policy if exists "members update their groups" on public.groups;
create policy "members update their groups" on public.groups
  for update using (
    exists (select 1 from public.group_members gm where gm.group_id = id and gm.user_id = auth.uid())
  );

drop policy if exists "members view group membership" on public.group_members;
create policy "members view group membership" on public.group_members
  for select using (
    exists (
      select 1 from public.group_members gm2
      where gm2.group_id = group_members.group_id and gm2.user_id = auth.uid()
    )
  );

drop policy if exists "users add themselves to a group" on public.group_members;
create policy "users add themselves to a group" on public.group_members
  for insert with check (auth.uid() = user_id);

drop policy if exists "users leave a group" on public.group_members;
create policy "users leave a group" on public.group_members
  for delete using (auth.uid() = user_id);

drop policy if exists "members view group expenses" on public.expenses;
create policy "members view group expenses" on public.expenses
  for select using (
    exists (select 1 from public.group_members gm where gm.group_id = expenses.group_id and gm.user_id = auth.uid())
  );

drop policy if exists "members add group expenses" on public.expenses;
create policy "members add group expenses" on public.expenses
  for insert with check (
    exists (select 1 from public.group_members gm where gm.group_id = expenses.group_id and gm.user_id = auth.uid())
  );

drop policy if exists "members update group expenses" on public.expenses;
create policy "members update group expenses" on public.expenses
  for update using (
    exists (select 1 from public.group_members gm where gm.group_id = expenses.group_id and gm.user_id = auth.uid())
  );

drop policy if exists "members delete group expenses" on public.expenses;
create policy "members delete group expenses" on public.expenses
  for delete using (
    exists (select 1 from public.group_members gm where gm.group_id = expenses.group_id and gm.user_id = auth.uid())
  );

drop policy if exists "members view group settlements" on public.settlements;
create policy "members view group settlements" on public.settlements
  for select using (
    exists (select 1 from public.group_members gm where gm.group_id = settlements.group_id and gm.user_id = auth.uid())
  );

drop policy if exists "members add group settlements" on public.settlements;
create policy "members add group settlements" on public.settlements
  for insert with check (
    exists (select 1 from public.group_members gm where gm.group_id = settlements.group_id and gm.user_id = auth.uid())
  );

drop policy if exists "members delete group settlements" on public.settlements;
create policy "members delete group settlements" on public.settlements
  for delete using (
    exists (select 1 from public.group_members gm where gm.group_id = settlements.group_id and gm.user_id = auth.uid())
  );

-- ============================================================
-- Realtime: let clients subscribe to live changes on these tables
-- ============================================================
do $$
declare
  t text;
begin
  foreach t in array array['groups', 'group_members', 'expenses', 'settlements'] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;
