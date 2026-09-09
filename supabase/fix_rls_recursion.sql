-- Fix: "infinite recursion detected in policy for relation group_members" (42P17)
--
-- Run this once in Supabase: Dashboard -> SQL Editor -> New query -> paste -> Run.
-- Only needed if you created your database from an earlier copy of schema.sql;
-- the current schema.sql already contains these definitions.
--
-- The old policy on group_members asked "is this user a member of this group?"
-- by selecting from group_members itself. Evaluating that subquery re-applies
-- the very policy being evaluated, so Postgres aborts with 42P17. Because the
-- policies on groups, expenses and settlements all reached into group_members
-- for the same check, the single cycle made four of the five tables unreadable
-- and every screen in the app failed.
--
-- The helper below does the lookup as its owner, where RLS does not apply, so
-- there is no cycle. It changes who can see what in no way: the same rows are
-- visible to the same people as the policies always intended.

-- A policy on group_members may not query group_members: evaluating the
-- subquery re-applies the same policy, which Postgres rejects as infinite
-- recursion (42P17). Because every other table's policies ask "is this user
-- in that group?" by reading group_members, that one cycle made groups,
-- expenses and settlements unreadable too. This helper runs as its owner, so
-- the lookup inside it is not subject to RLS and the cycle is broken. Every
-- membership check goes through it.
create or replace function public.is_group_member(p_group_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.group_members
    where group_id = p_group_id and user_id = auth.uid()
  );
$$;

revoke all on function public.is_group_member(uuid) from public;
grant execute on function public.is_group_member(uuid) to authenticated;

drop policy if exists "members view their groups" on public.groups;
create policy "members view their groups" on public.groups
  for select using (public.is_group_member(id));

drop policy if exists "members update their groups" on public.groups;
create policy "members update their groups" on public.groups
  for update using (public.is_group_member(id));

drop policy if exists "members view group membership" on public.group_members;
create policy "members view group membership" on public.group_members
  for select using (public.is_group_member(group_id));

drop policy if exists "members view group expenses" on public.expenses;
create policy "members view group expenses" on public.expenses
  for select using (public.is_group_member(group_id));

drop policy if exists "members add group expenses" on public.expenses;
create policy "members add group expenses" on public.expenses
  for insert with check (public.is_group_member(group_id));

drop policy if exists "members update group expenses" on public.expenses;
create policy "members update group expenses" on public.expenses
  for update using (public.is_group_member(group_id));

drop policy if exists "members delete group expenses" on public.expenses;
create policy "members delete group expenses" on public.expenses
  for delete using (public.is_group_member(group_id));

drop policy if exists "members view group settlements" on public.settlements;
create policy "members view group settlements" on public.settlements
  for select using (public.is_group_member(group_id));

drop policy if exists "members add group settlements" on public.settlements;
create policy "members add group settlements" on public.settlements
  for insert with check (public.is_group_member(group_id));

drop policy if exists "members delete group settlements" on public.settlements;
create policy "members delete group settlements" on public.settlements
  for delete using (public.is_group_member(group_id));
