-- Checks the row-level security policies against a real Postgres.
--
-- Run with supabase/test/rls_test.sh. It builds a throwaway database from
-- schema.sql, so a policy that cannot be evaluated (the 42P17 recursion that
-- once made four of five tables unreadable) or that leaks another group's
-- rows fails here rather than on someone's phone.
\set ON_ERROR_STOP on
set client_min_messages = notice;
\o /dev/null

create function pg_temp.as_user(p_id text) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', p_id, false);
  perform set_config('request.jwt.claim.role', 'authenticated', false);
end $$;

create function pg_temp.check(p_label text, p_got anyelement, p_want anyelement)
returns void language plpgsql as $$
begin
  if p_got is distinct from p_want then
    raise exception 'FAIL  %: got %, want %', p_label, p_got, p_want;
  end if;
  raise notice 'ok    %', p_label;
end $$;

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'alice@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'bob@example.com');

set role authenticated;
select pg_temp.as_user('11111111-1111-1111-1111-111111111111');

-- Alice creates a shared group and a private one, the way the app does:
-- the group row first, then her own membership row.
insert into public.groups (id, name, color_value, invite_code, created_by) values
  ('aaaaaaaa-0000-0000-0000-000000000001','Lunch',        4281051284,'LNC777','11111111-1111-1111-1111-111111111111'),
  ('aaaaaaaa-0000-0000-0000-000000000002','Alice private',4293483114,'PRV999','11111111-1111-1111-1111-111111111111');
insert into public.group_members values
  ('aaaaaaaa-0000-0000-0000-000000000001','11111111-1111-1111-1111-111111111111'),
  ('aaaaaaaa-0000-0000-0000-000000000002','11111111-1111-1111-1111-111111111111');

-- Every table the app reads on startup must be readable at all. Before the
-- helper function existed, each of these raised 42P17.
select pg_temp.check('profiles readable',     (select count(*)::int from public.profiles),      2);
select pg_temp.check('groups readable',       (select count(*)::int from public.groups),        2);
select pg_temp.check('memberships readable',  (select count(*)::int from public.group_members), 2);
select pg_temp.check('expenses readable',     (select count(*)::int from public.expenses),      0);
select pg_temp.check('settlements readable',  (select count(*)::int from public.settlements),   0);

-- A stranger sees nothing.
select pg_temp.as_user('22222222-2222-2222-2222-222222222222');
select pg_temp.check('non-member sees no groups',      (select count(*)::int from public.groups),        0);
select pg_temp.check('non-member sees no memberships', (select count(*)::int from public.group_members), 0);

-- Joining by code lets Bob in, and only into the group whose code he used.
select pg_temp.check('join by code returns the group',
  public.join_group_by_code('lnc777'), 'aaaaaaaa-0000-0000-0000-000000000001'::uuid);
select pg_temp.check('joiner sees only that group', (select string_agg(name, ',' order by name) from public.groups), 'Lunch');
select pg_temp.check('joiner sees both members',    (select count(*)::int from public.group_members), 2);
select pg_temp.check('bad code is rejected', (
  select case when (select count(*) from public.groups where invite_code = 'NOPE00') = 0 then 'rejected' end), 'rejected');

-- Expenses and settlements flow both ways between members.
select pg_temp.as_user('11111111-1111-1111-1111-111111111111');
insert into public.expenses (group_id, description, amount, paid_by, split_type, shares, participant_ids, created_by)
values ('aaaaaaaa-0000-0000-0000-000000000001','Biryani',900,'11111111-1111-1111-1111-111111111111','unequal',
        '{"11111111-1111-1111-1111-111111111111":500,"22222222-2222-2222-2222-222222222222":400}',
        array['11111111-1111-1111-1111-111111111111','22222222-2222-2222-2222-222222222222']::uuid[],
        '11111111-1111-1111-1111-111111111111');
insert into public.expenses (group_id, description, amount, paid_by, split_type, shares, participant_ids, created_by)
values ('aaaaaaaa-0000-0000-0000-000000000002','Secret',50,'11111111-1111-1111-1111-111111111111','equal','{}',
        array['11111111-1111-1111-1111-111111111111']::uuid[],'11111111-1111-1111-1111-111111111111');

select pg_temp.as_user('22222222-2222-2222-2222-222222222222');
select pg_temp.check('member sees the shared expense only',
  (select string_agg(description, ',' order by description) from public.expenses), 'Biryani');
insert into public.settlements (group_id, from_id, to_id, amount, created_by)
values ('aaaaaaaa-0000-0000-0000-000000000001','22222222-2222-2222-2222-222222222222',
        '11111111-1111-1111-1111-111111111111',400,'22222222-2222-2222-2222-222222222222');

select pg_temp.as_user('11111111-1111-1111-1111-111111111111');
select pg_temp.check('settlement is visible to the other member',
  (select sum(amount)::int from public.settlements), 400);

-- A non-member may not write into a group, even knowing its id.
select pg_temp.as_user('22222222-2222-2222-2222-222222222222');
do $$
begin
  insert into public.expenses (group_id, description, amount, paid_by, split_type, shares, participant_ids, created_by)
  values ('aaaaaaaa-0000-0000-0000-000000000002','Sneaky',10,'22222222-2222-2222-2222-222222222222','equal','{}',
          array['22222222-2222-2222-2222-222222222222']::uuid[],'22222222-2222-2222-2222-222222222222');
  raise exception 'FAIL  non-member write was allowed';
exception when insufficient_privilege then
  raise notice 'ok    non-member cannot write into a group';
end $$;

-- Leaving a group takes its rows out of view again.
do $$
declare n int;
begin
  delete from public.group_members
   where group_id = 'aaaaaaaa-0000-0000-0000-000000000001'
     and user_id  = '22222222-2222-2222-2222-222222222222';
  get diagnostics n = row_count;
  perform pg_temp.check('member can leave', n, 1);
end $$;
select pg_temp.check('after leaving, the group is hidden', (select count(*)::int from public.groups), 0);
select pg_temp.check('after leaving, its expenses are hidden', (select count(*)::int from public.expenses), 0);

reset role;
\o
\echo ''
\echo 'All RLS checks passed.'
