-- Row Level Security for TapLog (issue #24).
--
-- State when this was written (checked against pg_policies): RLS was already on
-- for every table and each had an "own rows" policy. The only gap was
-- tracking_sessions, whose WITH CHECK tested user_id alone, so a user could
-- insert/update a session pointing at another user's activity or tag.
-- This file records the full setup so it can be reproduced, and tightens that policy.
-- Safe to re-run.

alter table public.profiles           enable row level security;
alter table public.activities         enable row level security;
alter table public.tracking_sessions  enable row level security;
alter table public.nfc_tags           enable row level security;
alter table public.nfc_tag_activities enable row level security;

-- profiles: own row only; no delete policy, so deletes are blocked.
drop policy if exists "Own profile: read"   on public.profiles;
drop policy if exists "Own profile: create" on public.profiles;
drop policy if exists "Own profile: update" on public.profiles;
create policy "Own profile: read"   on public.profiles for select to authenticated
  using ((select auth.uid()) = id);
create policy "Own profile: create" on public.profiles for insert to authenticated
  with check ((select auth.uid()) = id);
create policy "Own profile: update" on public.profiles for update to authenticated
  using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

-- activities
drop policy if exists "Own activities" on public.activities;
create policy "Own activities" on public.activities for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- nfc_tags
drop policy if exists "Own tags" on public.nfc_tags;
create policy "Own tags" on public.nfc_tags for all to authenticated
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

-- nfc_tag_activities: visible if you own the tag; writable only if you own
-- both the tag and the activity.
drop policy if exists "Own tag links" on public.nfc_tag_activities;
create policy "Own tag links" on public.nfc_tag_activities for all to authenticated
  using (exists (
    select 1 from public.nfc_tags t
    where t.id = nfc_tag_activities.tag_id and t.owner_id = (select auth.uid())
  ))
  with check (
    exists (
      select 1 from public.nfc_tags t
      where t.id = nfc_tag_activities.tag_id and t.owner_id = (select auth.uid())
    )
    and exists (
      select 1 from public.activities a
      where a.id = nfc_tag_activities.activity_id and a.user_id = (select auth.uid())
    )
  );

-- tracking_sessions: own rows, and any activity/tag referenced must also be yours.
-- activity_id and nfc_tag_id are nullable, so null is allowed.
drop policy if exists "Own sessions" on public.tracking_sessions;
create policy "Own sessions" on public.tracking_sessions for all to authenticated
  using ((select auth.uid()) = user_id)
  with check (
    (select auth.uid()) = user_id
    and (
      activity_id is null
      or exists (
        select 1 from public.activities a
        where a.id = tracking_sessions.activity_id and a.user_id = (select auth.uid())
      )
    )
    and (
      nfc_tag_id is null
      or exists (
        select 1 from public.nfc_tags t
        where t.id = tracking_sessions.nfc_tag_id and t.owner_id = (select auth.uid())
      )
    )
  );
