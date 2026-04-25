-- ============================================================
-- HabitFlow — Supabase Schema
-- Run this in your Supabase SQL editor (Dashboard → SQL Editor)
-- ============================================================

-- Enable UUID extension
create extension if not exists "pgcrypto";

-- ─────────────────────────────────────────
-- PROFILES (extends Supabase auth.users)
-- ─────────────────────────────────────────
create table public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  email        text not null,
  display_name text not null default '',
  role         text not null default 'member' check (role in ('admin','member')),
  color        text not null default '#1A5276',
  fill         text not null default '#D6EAF8',
  created_at   timestamptz not null default now()
);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, email, display_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email,'@',1)),
    coalesce(new.raw_user_meta_data->>'role', 'member')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ─────────────────────────────────────────
-- HABITS
-- ─────────────────────────────────────────
create table public.habits (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  name       text not null,
  sort_order int  not null default 0,
  created_at timestamptz not null default now()
);

-- ─────────────────────────────────────────
-- HABIT LOGS  (one row per user/habit/day)
-- ─────────────────────────────────────────
create table public.habit_logs (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  habit_id   uuid not null references public.habits(id) on delete cascade,
  log_date   date not null,
  status     text not null check (status in ('done','skip')),
  created_at timestamptz not null default now(),
  unique (habit_id, log_date)
);

-- ─────────────────────────────────────────
-- ROW LEVEL SECURITY
-- ─────────────────────────────────────────

alter table public.profiles   enable row level security;
alter table public.habits     enable row level security;
alter table public.habit_logs enable row level security;

-- Profiles: everyone can read all (needed for summary/leaderboard)
create policy "profiles_select_all" on public.profiles
  for select using (auth.role() = 'authenticated');

-- Profiles: only own row can be updated
create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id);

-- Admin can update any profile (for display_name / role edits)
create policy "profiles_admin_update" on public.profiles
  for update using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- Habits: read own + admin reads all
create policy "habits_select" on public.habits
  for select using (
    auth.uid() = user_id
    or exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

create policy "habits_insert_own" on public.habits
  for insert with check (auth.uid() = user_id);

create policy "habits_update_own" on public.habits
  for update using (auth.uid() = user_id);

create policy "habits_delete_own" on public.habits
  for delete using (auth.uid() = user_id);

-- Habit logs: read own + admin reads all
create policy "logs_select" on public.habit_logs
  for select using (
    auth.uid() = user_id
    or exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

create policy "logs_insert_own" on public.habit_logs
  for insert with check (auth.uid() = user_id);

create policy "logs_upsert_own" on public.habit_logs
  for update using (auth.uid() = user_id);

create policy "logs_delete_own" on public.habit_logs
  for delete using (auth.uid() = user_id);

-- ─────────────────────────────────────────
-- USEFUL VIEWS (optional, for summary tab)
-- ─────────────────────────────────────────
create or replace view public.habit_summary as
  select
    p.id        as user_id,
    p.display_name,
    p.color,
    h.id        as habit_id,
    h.name      as habit_name,
    extract(year  from l.log_date)::int as year,
    extract(month from l.log_date)::int as month,
    count(*) filter (where l.status = 'done') as done_count,
    count(*) filter (where l.status = 'skip') as skip_count
  from public.profiles p
  join public.habits h    on h.user_id = p.id
  left join public.habit_logs l on l.habit_id = h.id
  group by p.id, p.display_name, p.color, h.id, h.name,
           extract(year from l.log_date), extract(month from l.log_date);

-- ─────────────────────────────────────────
-- SEED: first admin user
-- ─────────────────────────────────────────
-- After you sign up your first account, run:
--   update public.profiles set role = 'admin' where email = 'your@email.com';
