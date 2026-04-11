-- Rate limiting table + RPC helpers (service_role only)
-- This provides a distributed store for serverless environments without Redis/KV.

create table if not exists public.rate_limits (
  key text primary key,
  count integer not null,
  reset_time_ms bigint not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists rate_limits_reset_time_ms_idx
  on public.rate_limits (reset_time_ms);
alter table public.rate_limits enable row level security;
-- No policies: service_role bypasses RLS; anon/auth cannot access.

create or replace function public.ratelimit_increment(rl_key text, rl_window_ms integer)
returns table(count integer, reset_time_ms bigint)
language plpgsql
security definer
set search_path = public
as $$
declare
  now_ms bigint := (extract(epoch from clock_timestamp()) * 1000)::bigint;
  new_reset_ms bigint := now_ms + greatest(1000, rl_window_ms)::bigint;
begin
  if rl_key is null or length(trim(rl_key)) = 0 then
    raise exception 'rl_key is required';
  end if;

  insert into public.rate_limits as rl (key, count, reset_time_ms, created_at, updated_at)
  values (rl_key, 1, new_reset_ms, now(), now())
  on conflict (key) do update
  set
    count = case when rl.reset_time_ms < now_ms then 1 else rl.count + 1 end,
    reset_time_ms = case when rl.reset_time_ms < now_ms then new_reset_ms else rl.reset_time_ms end,
    updated_at = now()
  returning rl.count, rl.reset_time_ms
  into count, reset_time_ms;

  return next;
end;
$$;
create or replace function public.ratelimit_get(rl_key text)
returns table(count integer, reset_time_ms bigint)
language sql
security definer
set search_path = public
as $$
  select rl.count, rl.reset_time_ms
  from public.rate_limits rl
  where rl.key = rl_key
  limit 1;
$$;
create or replace function public.ratelimit_set(
  rl_key text,
  rl_count integer,
  rl_reset_time_ms bigint,
  rl_ttl_ms integer
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  now_ms bigint := (extract(epoch from clock_timestamp()) * 1000)::bigint;
  reset_ms bigint := greatest(now_ms + 1000, rl_reset_time_ms);
begin
  if rl_key is null or length(trim(rl_key)) = 0 then
    raise exception 'rl_key is required';
  end if;
  if rl_count is null or rl_count < 0 then
    raise exception 'rl_count must be >= 0';
  end if;

  insert into public.rate_limits (key, count, reset_time_ms, created_at, updated_at)
  values (rl_key, rl_count, reset_ms, now(), now())
  on conflict (key) do update
  set count = excluded.count,
      reset_time_ms = excluded.reset_time_ms,
      updated_at = now();
end;
$$;
create or replace function public.cleanup_expired_rate_limits()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  now_ms bigint := (extract(epoch from clock_timestamp()) * 1000)::bigint;
  deleted_count integer := 0;
begin
  delete from public.rate_limits
  where reset_time_ms < (now_ms - (24 * 60 * 60 * 1000)::bigint);

  get diagnostics deleted_count = row_count;
  return deleted_count;
end;
$$;
-- Harden privileges
revoke all on table public.rate_limits from public;
revoke all on function public.ratelimit_increment(text, integer) from public;
revoke all on function public.ratelimit_get(text) from public;
revoke all on function public.ratelimit_set(text, integer, bigint, integer) from public;
revoke all on function public.cleanup_expired_rate_limits() from public;
grant execute on function public.ratelimit_increment(text, integer) to service_role;
grant execute on function public.ratelimit_get(text) to service_role;
grant execute on function public.ratelimit_set(text, integer, bigint, integer) to service_role;
grant execute on function public.cleanup_expired_rate_limits() to service_role;
