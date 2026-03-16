create table if not exists public.edge_response_cache (
  key text primary key,
  payload jsonb not null,
  expires_at timestamptz not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists edge_response_cache_expires_at_idx
  on public.edge_response_cache (expires_at);
