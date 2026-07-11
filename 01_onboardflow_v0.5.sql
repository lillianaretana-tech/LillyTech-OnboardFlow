-- LillyTech OnboardFlow v0.5
-- Ejecutar en el proyecto Supabase general.
-- Todas las tablas usan prefijo of_.

create extension if not exists "pgcrypto";

create table if not exists public.of_tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  logo_url text,
  portal_name text default 'Centro de Inducción',
  primary_color text default '#0B132B',
  accent_color text default '#C9782A',
  minimum_passing_grade numeric(5,2) default 80,
  late_tolerance_minutes integer default 5,
  show_lillytech_branding boolean default true,
  active boolean default true,
  created_at timestamptz default now()
);

create table if not exists public.of_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  tenant_id uuid not null references public.of_tenants(id) on delete cascade,
  full_name text not null,
  role text not null check (role in ('owner','admin','hr','instructor','supervisor','management')),
  active boolean default true,
  created_at timestamptz default now()
);

create table if not exists public.of_people (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.of_tenants(id) on delete cascade,
  full_name text not null,
  document_id text not null,
  email text,
  phone text,
  current_relationship text not null default 'candidate'
    check (current_relationship in ('candidate','employee','former_employee','external')),
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(tenant_id, document_id)
);

create table if not exists public.of_employment_eligibility (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.of_tenants(id) on delete cascade,
  person_id uuid not null references public.of_people(id) on delete cascade,
  eligibility_status text not null default 'eligible'
    check (eligibility_status in ('eligible','review_required','not_eligible')),
  valid_from date default current_date,
  valid_until date,
  internal_notes text,
  updated_by uuid not null references public.of_profiles(id),
  updated_at timestamptz default now(),
  unique(tenant_id, person_id)
);

create table if not exists public.of_projects (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.of_tenants(id) on delete cascade,
  name text not null,
  requires_medical_modules boolean default false,
  active boolean default true,
  unique(tenant_id, name)
);

create table if not exists public.of_candidates (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.of_tenants(id) on delete cascade,
  person_id uuid not null references public.of_people(id) on delete cascade,
  project_id uuid references public.of_projects(id),
  position_name text,
  interviewing_supervisor_id uuid not null references public.of_profiles(id),
  proposed_induction_date date,
  status text not null default 'pending_hr_review'
    check (status in ('pending_hr_review','returned_for_correction','approved_by_hr','invited','registered','in_induction','pending_module','approved_for_hire','not_approved','absent','cancelled')),
  created_at timestamptz default now()
);

create unique index if not exists of_one_open_candidate_process
on public.of_candidates(tenant_id, person_id)
where status in ('pending_hr_review','returned_for_correction','approved_by_hr','invited','registered','in_induction','pending_module');

create table if not exists public.of_sessions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.of_tenants(id) on delete cascade,
  title text not null default 'Inducción de primer ingreso',
  session_date date not null,
  start_time time not null,
  meeting_url text,
  status text not null default 'scheduled'
    check (status in ('scheduled','registration_open','in_progress','closed','cancelled')),
  created_by uuid references public.of_profiles(id),
  created_at timestamptz default now()
);

create table if not exists public.of_modules (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.of_tenants(id) on delete cascade,
  name text not null,
  module_order integer not null,
  duration_minutes integer,
  has_exam boolean default false,
  required boolean default true,
  medical_only boolean default false,
  active boolean default true,
  unique(tenant_id, name)
);

create table if not exists public.of_session_candidates (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.of_sessions(id) on delete cascade,
  candidate_id uuid not null references public.of_candidates(id) on delete cascade,
  invited_at timestamptz,
  registered_at timestamptz,
  joined_at timestamptz,
  left_at timestamptz,
  attendance_status text not null default 'invited'
    check (attendance_status in ('invited','registered','waiting_room','present','late','absent','incomplete')),
  late_authorized_by uuid references public.of_profiles(id),
  late_justification text,
  unique(session_id,candidate_id)
);

create table if not exists public.of_access_codes (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.of_tenants(id) on delete cascade,
  session_candidate_id uuid not null references public.of_session_candidates(id) on delete cascade,
  code_hash text not null,
  expires_at timestamptz not null,
  max_attempts integer not null default 6 check (max_attempts between 1 and 10),
  failed_attempts integer not null default 0,
  status text not null default 'active' check (status in ('active','used','locked','expired','revoked')),
  generated_by uuid not null references public.of_profiles(id),
  generated_at timestamptz default now(),
  used_at timestamptz,
  last_attempt_at timestamptz
);

create unique index if not exists of_one_active_code_per_candidate
on public.of_access_codes(session_candidate_id)
where status='active';

create table if not exists public.of_module_progress (
  id uuid primary key default gen_random_uuid(),
  session_candidate_id uuid not null references public.of_session_candidates(id) on delete cascade,
  module_id uuid not null references public.of_modules(id),
  attempt_number integer not null default 1,
  started_at timestamptz,
  completed_at timestamptz,
  attendance_minutes integer default 0,
  score numeric(5,2),
  status text not null default 'pending'
    check (status in ('pending','in_progress','completed','interrupted','must_repeat','approved','failed')),
  unique(session_candidate_id,module_id,attempt_number)
);

create table if not exists public.of_incidents (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.of_tenants(id) on delete cascade,
  session_candidate_id uuid not null references public.of_session_candidates(id) on delete cascade,
  module_id uuid references public.of_modules(id),
  incident_type text not null,
  description text,
  occurred_at timestamptz default now(),
  reported_by_user uuid references public.of_profiles(id),
  reported_by_candidate boolean default false,
  status text not null default 'open' check (status in ('open','reviewed','resolved')),
  resolution text,
  resolved_by uuid references public.of_profiles(id),
  resolved_at timestamptz
);

create table if not exists public.of_reprogramming (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.of_tenants(id) on delete cascade,
  candidate_id uuid not null references public.of_candidates(id) on delete cascade,
  module_id uuid references public.of_modules(id),
  from_session_id uuid references public.of_sessions(id),
  to_session_id uuid references public.of_sessions(id),
  scope text not null check (scope in ('single_module','full_induction')),
  reason text not null,
  authorized_by_supervisor uuid not null references public.of_profiles(id),
  created_at timestamptz default now()
);

create table if not exists public.of_final_results (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.of_tenants(id) on delete cascade,
  session_candidate_id uuid not null unique references public.of_session_candidates(id) on delete cascade,
  average_score numeric(5,2),
  final_status text not null
    check (final_status in ('pending','approved_for_hire','not_approved','repeat_module','absent')),
  generated_at timestamptz default now(),
  reviewed_by uuid references public.of_profiles(id)
);

create table if not exists public.of_audit_logs (
  id bigint generated always as identity primary key,
  tenant_id uuid references public.of_tenants(id) on delete cascade,
  actor_id uuid references public.of_profiles(id),
  entity_type text not null,
  entity_id uuid,
  action text not null,
  details jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);

create or replace function public.of_current_tenant_id()
returns uuid language sql stable security definer set search_path=public
as $$ select tenant_id from public.of_profiles where id=auth.uid() and active=true limit 1 $$;

create or replace function public.of_check_eligibility(p_document_id text)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  v_profile public.of_profiles;
  v_person public.of_people;
  v_elig public.of_employment_eligibility;
begin
  select * into v_profile from public.of_profiles where id=auth.uid() and active=true;
  if v_profile.id is null or v_profile.role not in ('owner','admin','hr','supervisor') then
    raise exception 'No autorizado';
  end if;

  select * into v_person
  from public.of_people
  where tenant_id=v_profile.tenant_id
    and regexp_replace(document_id,'[^A-Za-z0-9]','','g')=
        regexp_replace(p_document_id,'[^A-Za-z0-9]','','g')
  limit 1;

  if v_person.id is null then
    return jsonb_build_object('status','eligible','exists',false,'message','Apto para continuar');
  end if;

  select * into v_elig
  from public.of_employment_eligibility
  where tenant_id=v_profile.tenant_id and person_id=v_person.id
  limit 1;

  if v_elig.id is null then
    return jsonb_build_object('status','eligible','exists',true,'message','Apto para continuar');
  end if;

  if v_profile.role='supervisor' then
    return jsonb_build_object(
      'status',v_elig.eligibility_status,
      'exists',true,
      'message',case v_elig.eligibility_status
        when 'eligible' then 'Apto para continuar'
        when 'review_required' then 'Revisión de Recursos Humanos'
        else 'No elegible para contratación'
      end
    );
  end if;

  return jsonb_build_object(
    'status',v_elig.eligibility_status,
    'exists',true,
    'message','Registro encontrado',
    'internal_notes',v_elig.internal_notes
  );
end;
$$;

alter table public.of_tenants enable row level security;
alter table public.of_profiles enable row level security;
alter table public.of_people enable row level security;
alter table public.of_employment_eligibility enable row level security;
alter table public.of_projects enable row level security;
alter table public.of_candidates enable row level security;
alter table public.of_sessions enable row level security;
alter table public.of_modules enable row level security;
alter table public.of_session_candidates enable row level security;
alter table public.of_access_codes enable row level security;
alter table public.of_module_progress enable row level security;
alter table public.of_incidents enable row level security;
alter table public.of_reprogramming enable row level security;
alter table public.of_final_results enable row level security;
alter table public.of_audit_logs enable row level security;

create policy "of_profiles_read_same_tenant" on public.of_profiles
for select to authenticated using (tenant_id=public.of_current_tenant_id());

create policy "of_tenants_read_own" on public.of_tenants
for select to authenticated using (id=public.of_current_tenant_id());

create policy "of_people_same_tenant" on public.of_people
for all to authenticated using (tenant_id=public.of_current_tenant_id())
with check (tenant_id=public.of_current_tenant_id());

create policy "of_eligibility_same_tenant" on public.of_employment_eligibility
for all to authenticated using (tenant_id=public.of_current_tenant_id())
with check (tenant_id=public.of_current_tenant_id());

create policy "of_projects_same_tenant" on public.of_projects
for all to authenticated using (tenant_id=public.of_current_tenant_id())
with check (tenant_id=public.of_current_tenant_id());

create policy "of_candidates_same_tenant" on public.of_candidates
for all to authenticated using (tenant_id=public.of_current_tenant_id())
with check (tenant_id=public.of_current_tenant_id());

create policy "of_sessions_same_tenant" on public.of_sessions
for all to authenticated using (tenant_id=public.of_current_tenant_id())
with check (tenant_id=public.of_current_tenant_id());

create policy "of_modules_same_tenant" on public.of_modules
for all to authenticated using (tenant_id=public.of_current_tenant_id())
with check (tenant_id=public.of_current_tenant_id());

create policy "of_incidents_same_tenant" on public.of_incidents
for all to authenticated using (tenant_id=public.of_current_tenant_id())
with check (tenant_id=public.of_current_tenant_id());

create policy "of_reprogramming_same_tenant" on public.of_reprogramming
for all to authenticated using (tenant_id=public.of_current_tenant_id())
with check (tenant_id=public.of_current_tenant_id());

create policy "of_results_same_tenant" on public.of_final_results
for all to authenticated using (tenant_id=public.of_current_tenant_id())
with check (tenant_id=public.of_current_tenant_id());

grant execute on function public.of_check_eligibility(text) to authenticated;

-- Completar políticas específicas por rol antes de producción.
-- Nunca publicar service_role.
