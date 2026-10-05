-- migrate:up
create table prompt_versions (
  id          serial primary key,
  label       text unique not null,
  content     text not null,
  created_at  timestamptz not null default now()
);

create table runs (
  id                 serial primary key,
  label              text unique not null,
  description        text,
  prompt_version_id  int references prompt_versions(id),
  config             jsonb not null default '{}'::jsonb,
  created_at         timestamptz not null default now()
);

create table sessions (
  id          uuid primary key default gen_random_uuid(),
  run_id      int references runs(id),
  channel     text not null default 'console',
  room_name   text,
  worker_id   text,
  job_id      text,
  started_at  timestamptz not null default now(),
  ended_at    timestamptz
);
create index sessions_run_id_idx on sessions(run_id);

create table turns (
  id           bigserial primary key,
  event_id     uuid unique,                 -- idempotency key from the queue
  session_id   uuid not null references sessions(id) on delete cascade,
  turn_index   int not null,
  role         text not null check (role in ('user','assistant')),
  text         text,
  interrupted  boolean not null default false,
  created_at   timestamptz not null default now(),
  unique (session_id, turn_index)
);

create table turn_metrics (
  turn_id                   bigint primary key references turns(id) on delete cascade,
  end_of_utterance_delay_s  real,
  llm_ttft_s                real,
  tts_ttfb_s                real,
  e2e_latency_s             real,
  raw                       jsonb not null default '{}'::jsonb
);

-- migrate:down
drop table turn_metrics;
drop table turns;
drop table sessions;
drop table runs;
drop table prompt_versions;