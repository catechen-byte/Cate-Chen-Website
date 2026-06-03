-- Optional Supabase schema for private admin drafting.
-- Run in the Supabase SQL editor after creating a project.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique not null,
  created_at timestamptz default now()
);

create table if not exists public.draft_posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  slug text,
  kind text not null check (kind in ('blog', 'projects', 'research')),
  body text not null default '',
  frontmatter jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.admin_audit_log (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users(id) on delete set null,
  action text not null,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);

alter table public.draft_posts enable row level security;
alter table public.profiles enable row level security;
alter table public.admin_audit_log enable row level security;

create policy "Users manage own drafts"
  on public.draft_posts
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users read own profile"
  on public.profiles
  for select
  using (auth.uid() = id);

create policy "Users manage own audit rows"
  on public.admin_audit_log
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
