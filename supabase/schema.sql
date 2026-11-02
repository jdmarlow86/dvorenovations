-- Van Ornum Renovations: Supabase database foundation
-- Run this entire file in Supabase Dashboard > SQL Editor > New query.
-- Authentication is handled by Supabase Auth. Never put a service_role/secret key in the website.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  display_name text not null,
  role text not null default 'employee' check (role in ('employer','employee')),
  active boolean not null default true,
  must_change_password boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.jobs (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  customer text not null,
  location text,
  description text,
  status text not null default 'Quoted',
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists public.job_assignments (
  job_id uuid not null references public.jobs(id) on delete cascade,
  employee_id uuid not null references public.profiles(id) on delete cascade,
  primary key (job_id, employee_id)
);

create table if not exists public.time_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id),
  job_id uuid not null references public.jobs(id),
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  created_at timestamptz not null default now(),
  constraint valid_time_range check (ended_at is null or ended_at >= started_at)
);
create unique index if not exists one_open_time_entry_per_user
  on public.time_entries(user_id) where ended_at is null;

create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  job_id uuid references public.jobs(id) on delete set null,
  expense_date date not null default current_date,
  category text not null,
  description text not null,
  amount numeric(12,2) not null check (amount >= 0),
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  number text not null unique,
  job_id uuid references public.jobs(id) on delete set null,
  job_name text,
  invoice_date date not null default current_date,
  customer text not null,
  customer_address text,
  salesperson text,
  terms text default 'Due upon receipt',
  tax_rate numeric(7,3) not null default 0,
  subtotal numeric(12,2) not null default 0,
  tax numeric(12,2) not null default 0,
  total numeric(12,2) not null default 0,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists public.invoice_items (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.invoices(id) on delete cascade,
  quantity numeric(12,2) not null,
  description text not null,
  unit_price numeric(12,2) not null
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.invoices(id) on delete restrict,
  payment_date date not null default current_date,
  amount numeric(12,2) not null check (amount > 0),
  method text not null,
  reference text,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id),
  recipient_id uuid references public.profiles(id),
  send_to_all boolean not null default false,
  subject text not null,
  body text not null,
  created_at timestamptz not null default now()
);

create or replace function public.current_user_is_employer()
returns boolean language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'employer' and active = true
  );
$$;

create or replace function public.current_user_is_active()
returns boolean language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles where id = auth.uid() and active = true
  );
$$;

create or replace function public.current_user_assigned_to(target_job uuid)
returns boolean language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.job_assignments
    where job_id = target_job and employee_id = auth.uid()
  );
$$;

alter table public.profiles enable row level security;
alter table public.jobs enable row level security;
alter table public.job_assignments enable row level security;
alter table public.time_entries enable row level security;
alter table public.expenses enable row level security;
alter table public.invoices enable row level security;
alter table public.invoice_items enable row level security;
alter table public.payments enable row level security;
alter table public.messages enable row level security;

drop policy if exists "profiles readable by self or employer" on public.profiles;
create policy "profiles readable by self or employer" on public.profiles
for select to authenticated using (id = auth.uid() or public.current_user_is_employer());
drop policy if exists "employer manages profiles" on public.profiles;
create policy "employer manages profiles" on public.profiles
for all to authenticated using (public.current_user_is_employer()) with check (public.current_user_is_employer());

drop policy if exists "jobs readable by assigned users" on public.jobs;
create policy "jobs readable by assigned users" on public.jobs
for select to authenticated using (public.current_user_is_employer() or public.current_user_assigned_to(id));
drop policy if exists "employer manages jobs" on public.jobs;
create policy "employer manages jobs" on public.jobs
for all to authenticated using (public.current_user_is_employer()) with check (public.current_user_is_employer());

drop policy if exists "assignments readable by involved users" on public.job_assignments;
create policy "assignments readable by involved users" on public.job_assignments
for select to authenticated using (employee_id = auth.uid() or public.current_user_is_employer());
drop policy if exists "employer manages assignments" on public.job_assignments;
create policy "employer manages assignments" on public.job_assignments
for all to authenticated using (public.current_user_is_employer()) with check (public.current_user_is_employer());

drop policy if exists "time entries readable by owner or employer" on public.time_entries;
create policy "time entries readable by owner or employer" on public.time_entries
for select to authenticated using (user_id = auth.uid() or public.current_user_is_employer());
drop policy if exists "employees create own assigned time entries" on public.time_entries;
create policy "employees create own assigned time entries" on public.time_entries
for insert to authenticated with check (
  user_id = auth.uid() and public.current_user_is_active()
  and public.current_user_assigned_to(job_id)
);
drop policy if exists "employees update own open time entries" on public.time_entries;
create policy "employees update own open time entries" on public.time_entries
for update to authenticated using (
  (user_id = auth.uid() and ended_at is null) or public.current_user_is_employer()
) with check (user_id = auth.uid() or public.current_user_is_employer());

drop policy if exists "employer manages expenses" on public.expenses;
create policy "employer manages expenses" on public.expenses
for all to authenticated using (public.current_user_is_employer()) with check (public.current_user_is_employer());
drop policy if exists "employer manages invoices" on public.invoices;
create policy "employer manages invoices" on public.invoices
for all to authenticated using (public.current_user_is_employer()) with check (public.current_user_is_employer());
drop policy if exists "employer manages invoice items" on public.invoice_items;
create policy "employer manages invoice items" on public.invoice_items
for all to authenticated using (public.current_user_is_employer()) with check (public.current_user_is_employer());
drop policy if exists "employer manages payments" on public.payments;
create policy "employer manages payments" on public.payments
for all to authenticated using (public.current_user_is_employer()) with check (public.current_user_is_employer());

drop policy if exists "messages readable by participants" on public.messages;
create policy "messages readable by participants" on public.messages
for select to authenticated using (
  public.current_user_is_employer() or sender_id = auth.uid()
  or recipient_id = auth.uid() or send_to_all = true
);
drop policy if exists "employer sends messages" on public.messages;
create policy "employer sends messages" on public.messages
for insert to authenticated with check (
  public.current_user_is_employer() and sender_id = auth.uid()
);

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.profiles, public.jobs, public.job_assignments,
  public.time_entries, public.expenses, public.invoices, public.invoice_items,
  public.payments, public.messages to authenticated;
