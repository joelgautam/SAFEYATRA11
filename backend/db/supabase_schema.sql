create extension if not exists pgcrypto;

create table if not exists public.user_profiles (
  id uuid primary key default gen_random_uuid(),
  phone text not null unique,
  full_name text default '',
  email text default '',
  age smallint check (age is null or age > 0),
  blood_group text default '',
  avatar_url text default '',
  is_phone_verified boolean not null default false,
  safety_score smallint not null default 100 check (safety_score between 0 and 100),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.guardian_contacts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.user_profiles(id) on delete cascade,
  name text not null,
  phone text not null,
  relation text not null,
  priority smallint not null default 1,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.otp_codes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.user_profiles(id) on delete cascade,
  phone text not null,
  code text not null check (char_length(code) = 6),
  purpose text not null default 'signup',
  expires_at timestamptz not null,
  verified_at timestamptz,
  attempts smallint not null default 0,
  created_at timestamptz not null default now(),
  create table if not exists public.safety_tips (
  ...
  );

  create table if not exists public.predefined_routes (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    description text default '',
    waypoints jsonb not null default '[]'::jsonb,
    is_safe boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
  );

  create table if not exists public.trips (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.user_profiles(id) on delete cascade,
    start_label text not null,
    destination_label text not null,
    start_lat numeric(9,6),
    start_lng numeric(9,6),
    destination_lat numeric(9,6),
    destination_lng numeric(9,6),
    status text not null default 'planned' check (status in ('planned','active','safe','deviation','sos','cancelled')),
    passive_mode_enabled boolean not null default false,
    safe_corridor_meters integer not null default 150,
    planned_route jsonb not null default '{}'::jsonb,
    predefined_route_id uuid references public.predefined_routes(id) on delete set null,
    started_at timestamptz,
    completed_at timestamptz,
    distance_meters integer,
    duration_seconds integer,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
  );

create table if not exists public.location_pings (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips(id) on delete cascade,
  user_id uuid not null references public.user_profiles(id) on delete cascade,
  latitude numeric(9,6) not null,
  longitude numeric(9,6) not null,
  accuracy_meters numeric(7,2),
  speed_mps numeric(7,2),
  address_label text default '',
  recorded_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.trip_events (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips(id) on delete cascade,
  event_type text not null,
  title text not null,
  description text default '',
  latitude numeric(9,6),
  longitude numeric(9,6),
  occurred_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.alerts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.user_profiles(id) on delete cascade,
  trip_id uuid references public.trips(id) on delete set null,
  alert_type text not null check (alert_type in ('deviation','sos','audio_keyword','police')),
  status text not null default 'pending' check (status in ('pending','sent','cancelled','resolved')),
  message text default '',
  latitude numeric(9,6),
  longitude numeric(9,6),
  triggered_at timestamptz not null,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.alert_recipients (
  id uuid primary key default gen_random_uuid(),
  alert_id uuid not null references public.alerts(id) on delete cascade,
  guardian_id uuid references public.guardian_contacts(id) on delete set null,
  recipient_name text not null,
  recipient_phone text not null,
  delivery_status text not null default 'pending',
  delivered_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.user_profiles(id) on delete cascade,
  title text not null,
  body text not null,
  notification_type text not null default 'general',
  is_read boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.safety_tips (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  category text not null default 'general',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.faqs (
  id uuid primary key default gen_random_uuid(),
  question text not null,
  answer text not null,
  category text not null default 'general',
  display_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.audio_safety_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.user_profiles(id) on delete cascade,
  trip_id uuid references public.trips(id) on delete set null,
  status text not null default 'recording',
  keyword_detected text default '',
  recording_url text default '',
  started_at timestamptz not null,
  ended_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists guardian_contacts_user_id_idx on public.guardian_contacts(user_id);
create index if not exists otp_codes_phone_created_idx on public.otp_codes(phone, created_at desc);
create index if not exists trips_user_id_status_idx on public.trips(user_id, status);
create index if not exists location_pings_trip_recorded_idx on public.location_pings(trip_id, recorded_at desc);
create index if not exists trip_events_trip_occurred_idx on public.trip_events(trip_id, occurred_at);
create index if not exists alerts_user_status_idx on public.alerts(user_id, status);
create index if not exists alert_recipients_alert_id_idx on public.alert_recipients(alert_id);
create index if not exists notifications_user_read_idx on public.notifications(user_id, is_read);

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists set_user_profiles_updated_at on public.user_profiles;
create trigger set_user_profiles_updated_at
before update on public.user_profiles
for each row execute function public.set_updated_at();

drop trigger if exists set_guardian_contacts_updated_at on public.guardian_contacts;
create trigger set_guardian_contacts_updated_at
before update on public.guardian_contacts
for each row execute function public.set_updated_at();

drop trigger if exists set_otp_codes_updated_at on public.otp_codes;
create trigger set_otp_codes_updated_at
before update on public.otp_codes
for each row execute function public.set_updated_at();

drop trigger if exists set_trips_updated_at on public.trips;
create trigger set_trips_updated_at
before update on public.trips
for each row execute function public.set_updated_at();

drop trigger if exists set_location_pings_updated_at on public.location_pings;
create trigger set_location_pings_updated_at
before update on public.location_pings
for each row execute function public.set_updated_at();

drop trigger if exists set_trip_events_updated_at on public.trip_events;
create trigger set_trip_events_updated_at
before update on public.trip_events
for each row execute function public.set_updated_at();

drop trigger if exists set_alerts_updated_at on public.alerts;
create trigger set_alerts_updated_at
before update on public.alerts
for each row execute function public.set_updated_at();

drop trigger if exists set_alert_recipients_updated_at on public.alert_recipients;
create trigger set_alert_recipients_updated_at
before update on public.alert_recipients
for each row execute function public.set_updated_at();

drop trigger if exists set_notifications_updated_at on public.notifications;
create trigger set_notifications_updated_at
before update on public.notifications
for each row execute function public.set_updated_at();

drop trigger if exists set_safety_tips_updated_at on public.safety_tips;
create trigger set_safety_tips_updated_at
before update on public.safety_tips
for each row execute function public.set_updated_at();

drop trigger if exists set_faqs_updated_at on public.faqs;
create trigger set_faqs_updated_at
before update on public.faqs
for each row execute function public.set_updated_at();

drop trigger if exists set_audio_safety_sessions_updated_at on public.audio_safety_sessions;
create trigger set_audio_safety_sessions_updated_at
before update on public.audio_safety_sessions
for each row execute function public.set_updated_at();

alter table public.user_profiles enable row level security;
alter table public.guardian_contacts enable row level security;
alter table public.otp_codes enable row level security;
alter table public.trips enable row level security;
alter table public.location_pings enable row level security;
alter table public.trip_events enable row level security;
alter table public.alerts enable row level security;
alter table public.alert_recipients enable row level security;
alter table public.notifications enable row level security;
alter table public.safety_tips enable row level security;
alter table public.faqs enable row level security;
alter table public.audio_safety_sessions enable row level security;

insert into public.safety_tips (title, body, category)
values
  ('Share live location', 'Always share your live location with at least one guardian before starting a trip.', 'trip'),
  ('Choose visible roads', 'Use well-lit and busy roads especially during evening hours in Kathmandu.', 'trip')
on conflict do nothing;

insert into public.faqs (question, answer, category, display_order)
values
  ('What happens if I move off route?', 'SafeYatra starts a short countdown. If you do not mark yourself safe, your guardians are notified with your latest location.', 'alerts', 1),
  ('Who can see my location?', 'Your live location is shared only with selected guardians during active monitoring or an SOS alert.', 'privacy', 2),
  ('Can I edit guardian contacts?', 'Yes. Add, edit, reorder, or remove trusted guardians from your profile.', 'guardians', 3)
on conflict do nothing;
