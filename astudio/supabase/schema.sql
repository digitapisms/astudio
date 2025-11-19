-- Actor Studio Global - Initial Schema
-- Run this script inside the Supabase SQL Editor.

create extension if not exists "uuid-ossp";

-- ---------- Enumerations ----------
do $$
begin
  if not exists (select 1 from pg_type where typname = 'account_role') then
    create type public.account_role as enum ('artist', 'producer', 'admin', 'editor', 'viewer', 'staff');
  end if;
  if not exists (select 1 from pg_type where typname = 'profile_status') then
    create type public.profile_status as enum ('pending', 'approved', 'rejected', 'suspended');
  end if;
  if not exists (select 1 from pg_type where typname = 'application_status') then
    create type public.application_status as enum ('draft', 'submitted', 'shortlisted', 'declined', 'hired');
  end if;
  if not exists (select 1 from pg_type where typname = 'audition_status') then
    create type public.audition_status as enum ('pending', 'confirmed', 'submitted', 'reviewed', 'cancelled');
  end if;
  if not exists (select 1 from pg_type where typname = 'conversation_role') then
    create type public.conversation_role as enum ('member', 'moderator', 'owner');
  end if;
  if not exists (select 1 from pg_type where typname = 'review_visibility') then
    create type public.review_visibility as enum ('public', 'hidden');
  end if;
  if not exists (select 1 from pg_type where typname = 'verification_status') then
    create type public.verification_status as enum ('pending', 'approved', 'rejected');
  end if;
  if not exists (select 1 from pg_type where typname = 'report_status') then
    create type public.report_status as enum ('submitted', 'under_review', 'resolved', 'dismissed');
  end if;
  if not exists (select 1 from pg_type where typname = 'course_level') then
    create type public.course_level as enum ('beginner', 'intermediate', 'advanced');
  end if;
  if not exists (select 1 from pg_type where typname = 'notification_type') then
    create type public.notification_type as enum ('profile', 'audition', 'casting', 'system');
  end if;
end$$;

-- ---------- Helper Functions ----------
create or replace function public.is_staff() returns boolean as $$
begin
  return exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.account_role in ('admin','editor','staff')
  );
end;
$$ language plpgsql security definer;

create or replace function public.is_admin() returns boolean as $$
begin
  return exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.account_role = 'admin'
  );
end;
$$ language plpgsql security definer;

-- ---------- Profiles ----------
create table if not exists public.profiles (
  id uuid primary key references auth.users on delete cascade,
  email text unique,
  full_name text not null,
  account_role account_role not null default 'artist',
  status profile_status not null default 'pending',
  gender text,
  age integer,
  location text,
  profession text,
  bio text,
  skills text[],
  languages text[],
  avatar_url text,
  banner_url text,
  instagram text,
  youtube text,
  tiktok text,
  website text,
  featured_rank smallint,
  approved_by uuid references auth.users,
  approved_at timestamptz,
  review_notes text,
  is_visible boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_profiles_role on public.profiles(account_role);
create index if not exists idx_profiles_status on public.profiles(status);
create index if not exists idx_profiles_location on public.profiles using gin (to_tsvector('simple', coalesce(location, '')));
create index if not exists idx_profiles_full_name on public.profiles using gin (to_tsvector('simple', coalesce(full_name, '')));

alter table public.profiles enable row level security;

create policy "Public can read approved profiles"
  on public.profiles
  for select
  using (
    status = 'approved'
    or auth.uid() = id
    or public.is_staff()
  );

create policy "Users insert their own profile"
  on public.profiles
  for insert
  with check (auth.uid() = id);

create policy "Users edit their pending profile"
  on public.profiles
  for update
  using (
    auth.uid() = id
    and status in ('pending','rejected')
  )
  with check (
    auth.uid() = id
  );

create policy "Staff can manage all profiles"
  on public.profiles
  for all
  using (public.is_staff())
  with check (public.is_staff());

-- ---------- Profile Reviews ----------
create table if not exists public.profile_reviews (
  id uuid primary key default uuid_generate_v4(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  reviewer_id uuid not null references auth.users on delete cascade,
  status profile_status not null,
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists idx_profile_reviews_profile on public.profile_reviews(profile_id);

alter table public.profile_reviews enable row level security;

create policy "Staff manage profile reviews"
  on public.profile_reviews
  for all
  using (public.is_staff())
  with check (public.is_staff());

-- ---------- Portfolio Media ----------
create table if not exists public.portfolio_media (
  id uuid primary key default uuid_generate_v4(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text,
  media_url text not null,
  thumbnail_url text,
  media_type text not null default 'link',
  tags text[],
  sort_order integer not null default 0,
  is_public boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_portfolio_profile on public.portfolio_media(profile_id);
create index if not exists idx_portfolio_sort on public.portfolio_media(profile_id, sort_order);

alter table public.portfolio_media enable row level security;

create policy "Public view visible portfolio"
  on public.portfolio_media
  for select
  using (
    exists (
      select 1
      from public.profiles p
      where p.id = portfolio_media.profile_id
        and (
          p.is_visible
          or auth.uid() = p.id
          or public.is_staff()
        )
    )
  );

create policy "Owners manage their portfolio"
  on public.portfolio_media
  for all
  using (auth.uid() = profile_id or public.is_staff())
  with check (auth.uid() = profile_id or public.is_staff());

-- ---------- Casting calls ----------
create table if not exists public.castings (
  id uuid primary key default uuid_generate_v4(),
  created_by uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text not null,
  category text,
  budget text,
  city text,
  country text,
  location text,
  application_deadline date,
  shoot_date date,
  requirements jsonb,
  is_published boolean default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_castings_created_by on public.castings(created_by);
create index if not exists idx_castings_city on public.castings(city);
create index if not exists idx_castings_category on public.castings(category);
create index if not exists idx_castings_ts on public.castings using gin (to_tsvector('english', title || ' ' || coalesce(description, '')));

alter table public.castings enable row level security;

create policy "Published castings are public"
  on public.castings
  for select
  using (
    is_published
    or auth.uid() = created_by
    or public.is_staff()
  );

create policy "Producers manage their castings"
  on public.castings
  for all
  using (auth.uid() = created_by or public.is_staff())
  with check (auth.uid() = created_by or public.is_staff());

-- ---------- Applications ----------
create table if not exists public.applications (
  id uuid primary key default uuid_generate_v4(),
  casting_id uuid not null references public.castings(id) on delete cascade,
  talent_id uuid not null references public.profiles(id) on delete cascade,
  cover_letter text,
  media_urls text[],
  status application_status not null default 'submitted',
  submitted_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists idx_applications_unique
  on public.applications(casting_id, talent_id);

create index if not exists idx_applications_status on public.applications(status);

alter table public.applications enable row level security;

create policy "Talent manage their applications"
  on public.applications
  for all
  using (auth.uid() = talent_id)
  with check (auth.uid() = talent_id);

create policy "Producers see applications to their casting"
  on public.applications
  for select
  using (
    auth.uid() = (
      select created_by from public.castings where id = applications.casting_id
    ) or public.is_staff()
  );

-- ---------- Audition Requests ----------
create table if not exists public.auditions (
  id uuid primary key default uuid_generate_v4(),
  casting_id uuid not null references public.castings(id) on delete cascade,
  talent_id uuid not null references public.profiles(id) on delete cascade,
  requested_by uuid not null references public.profiles(id) on delete cascade,
  application_id uuid references public.applications(id) on delete set null,
  status audition_status not null default 'pending',
  request_type text not null default 'self_tape',
  instructions text,
  meeting_link text,
  scheduled_at timestamptz,
  due_date timestamptz,
  submission_url text,
  reviewer_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_auditions_casting on public.auditions(casting_id);
create index if not exists idx_auditions_talent on public.auditions(talent_id);

alter table public.auditions enable row level security;

create policy "Talent view their auditions"
  on public.auditions
  for select
  using (auth.uid() = talent_id or public.is_staff());

create policy "Producers manage their auditions"
  on public.auditions
  for all
  using (
    auth.uid() = (
      select created_by from public.castings where id = auditions.casting_id
    ) or public.is_staff()
  )
  with check (
    auth.uid() = (
      select created_by from public.castings where id = auditions.casting_id
    ) or public.is_staff()
  );

-- ---------- Trigger to keep updated_at fresh ----------
create or replace function public.touch_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger on_update_profiles
  before update on public.profiles
  for each row
  execute procedure public.touch_updated_at();

create trigger on_update_castings
  before update on public.castings
  for each row
  execute procedure public.touch_updated_at();

create trigger on_update_applications
  before update on public.applications
  for each row
  execute procedure public.touch_updated_at();

create trigger on_update_portfolio_media
  before update on public.portfolio_media
  for each row
  execute procedure public.touch_updated_at();

create trigger on_update_auditions
  before update on public.auditions
  for each row
  execute procedure public.touch_updated_at();

-- ---------- Messaging ----------
create table if not exists public.conversations (
  id uuid primary key default uuid_generate_v4(),
  title text,
  created_by uuid not null references public.profiles(id) on delete cascade,
  casting_id uuid references public.castings(id) on delete set null,
  is_group boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.conversation_participants (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  role conversation_role not null default 'member',
  last_read_at timestamptz,
  joined_at timestamptz not null default now(),
  primary key (conversation_id, profile_id)
);

create table if not exists public.messages (
  id uuid primary key default uuid_generate_v4(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  content text not null,
  attachment_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.conversations enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.messages enable row level security;

create policy "Participants read conversations"
  on public.conversations
  for select
  using (
    exists (
      select 1
      from public.conversation_participants cp
      where cp.conversation_id = conversations.id
        and cp.profile_id = auth.uid()
    ) or public.is_staff()
  );

create policy "Owners manage conversations"
  on public.conversations
  for all
  using (
    exists (
      select 1
      from public.conversation_participants cp
      where cp.conversation_id = conversations.id
        and cp.profile_id = auth.uid()
        and cp.role in ('owner','moderator')
    ) or public.is_staff()
  )
  with check (
    exists (
      select 1
      from public.conversation_participants cp
      where cp.conversation_id = conversations.id
        and cp.profile_id = auth.uid()
        and cp.role in ('owner','moderator')
    ) or public.is_staff()
  );

create policy "Participants manage membership"
  on public.conversation_participants
  for all
  using (
    profile_id = auth.uid()
    or exists (
      select 1
      from public.conversation_participants cp
      where cp.conversation_id = conversation_participants.conversation_id
        and cp.profile_id = auth.uid()
        and cp.role in ('owner','moderator')
    ) or public.is_staff()
  )
  with check (
    profile_id = auth.uid()
    or exists (
      select 1
      from public.conversation_participants cp
      where cp.conversation_id = conversation_participants.conversation_id
        and cp.profile_id = auth.uid()
        and cp.role in ('owner','moderator')
    ) or public.is_staff()
  );

create policy "Participants manage messages"
  on public.messages
  for all
  using (
    sender_id = auth.uid()
    or exists (
      select 1
      from public.conversation_participants cp
      where cp.conversation_id = messages.conversation_id
        and cp.profile_id = auth.uid()
    ) or public.is_staff()
  )
  with check (
    sender_id = auth.uid()
    or public.is_staff()
  );

create trigger on_update_conversations
  before update on public.conversations
  for each row
  execute procedure public.touch_updated_at();

create trigger on_update_messages
  before update on public.messages
  for each row
  execute procedure public.touch_updated_at();

-- ---------- Reviews & Ratings ----------
create table if not exists public.profile_feedback (
  id uuid primary key default uuid_generate_v4(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  reviewer_id uuid not null references public.profiles(id) on delete cascade,
  rating smallint not null check (rating between 1 and 5),
  title text,
  comment text,
  visibility review_visibility not null default 'public',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (profile_id, reviewer_id)
);

create index if not exists idx_feedback_profile on public.profile_feedback(profile_id);
create index if not exists idx_feedback_reviewer on public.profile_feedback(reviewer_id);

alter table public.profile_feedback enable row level security;

create policy "Talent view public feedback"
  on public.profile_feedback
  for select
  using (
    visibility = 'public'
    or profile_id = auth.uid()
    or reviewer_id = auth.uid()
    or public.is_staff()
  );

create policy "Reviewers manage own feedback"
  on public.profile_feedback
  for all
  using (reviewer_id = auth.uid() or public.is_staff())
  with check (reviewer_id = auth.uid() or public.is_staff());

create trigger on_update_profile_feedback
  before update on public.profile_feedback
  for each row
  execute procedure public.touch_updated_at();

create table if not exists public.identity_verifications (
  id uuid primary key default uuid_generate_v4(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  document_type text,
  document_url text not null,
  status verification_status not null default 'pending',
  reviewer_id uuid references public.profiles(id),
  reviewer_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_identity_profile on public.identity_verifications(profile_id);

alter table public.identity_verifications enable row level security;

create policy "Users manage their verification"
  on public.identity_verifications
  for all
  using (profile_id = auth.uid() or public.is_staff())
  with check (profile_id = auth.uid() or public.is_staff());

create table if not exists public.safety_reports (
  id uuid primary key default uuid_generate_v4(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  target_profile_id uuid references public.profiles(id) on delete cascade,
  category text not null,
  description text,
  status report_status not null default 'submitted',
  resolution_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create policy "Reporter views their reports"
  on public.safety_reports
  for select
  using (reporter_id = auth.uid() or public.is_staff());

create policy "Reporters create new reports"
  on public.safety_reports
  for insert
  with check (reporter_id = auth.uid());

create policy "Staff updates reports"
  on public.safety_reports
  for update using (public.is_staff()) with check (public.is_staff());

alter table public.safety_reports enable row level security;

create table if not exists public.policy_acknowledgements (
  id uuid primary key default uuid_generate_v4(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  policy_key text not null,
  policy_version text not null,
  acknowledged_at timestamptz not null default now(),
  metadata jsonb,
  unique(profile_id, policy_key, policy_version)
);

alter table public.policy_acknowledgements enable row level security;

create policy "Users manage their acknowledgements"
  on public.policy_acknowledgements
  for all
  using (profile_id = auth.uid() or public.is_staff())
  with check (profile_id = auth.uid() or public.is_staff());

create trigger on_update_identity_verifications
  before update on public.identity_verifications
  for each row
  execute procedure public.touch_updated_at();

create trigger on_update_safety_reports
  before update on public.safety_reports
  for each row
  execute procedure public.touch_updated_at();

-- ---------- Metrics ----------
create table if not exists public.profile_metrics (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  profile_views bigint not null default 0,
  saves bigint not null default 0,
  audition_invites bigint not null default 0,
  last_profile_view timestamptz,
  updated_at timestamptz not null default now()
);

alter table public.profile_metrics enable row level security;

create policy "Owners access metrics"
  on public.profile_metrics
  for all
  using (profile_id = auth.uid() or public.is_staff())
  with check (profile_id = auth.uid() or public.is_staff());

create trigger on_update_profile_metrics
  before update on public.profile_metrics
  for each row
  execute procedure public.touch_updated_at();

-- ---------- Notifications ----------
create table if not exists public.notifications (
  id uuid primary key default uuid_generate_v4(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text,
  notification_type notification_type not null default 'system',
  metadata jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.notifications enable row level security;

create policy "Owners read notifications"
  on public.notifications
  for select
  using (profile_id = auth.uid() or public.is_staff());

create policy "Owners manage notifications"
  on public.notifications
  for update
  using (profile_id = auth.uid() or public.is_staff())
  with check (profile_id = auth.uid() or public.is_staff());

create policy "System inserts notifications"
  on public.notifications
  for insert
  with check (profile_id = auth.uid() or public.is_staff());

create trigger on_update_notifications
  before update on public.notifications
  for each row
  execute procedure public.touch_updated_at();

-- ---------- Learning: Courses & Training ----------
create table if not exists public.learning_courses (
  id uuid primary key default uuid_generate_v4(),
  title text not null,
  description text,
  level course_level not null default 'beginner',
  duration_minutes integer,
  cover_image_url text,
  tags text[],
  is_published boolean not null default false,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.learning_lessons (
  id uuid primary key default uuid_generate_v4(),
  course_id uuid not null references public.learning_courses(id) on delete cascade,
  title text not null,
  content text,
  video_url text,
  order_index integer not null default 0,
  duration_minutes integer,
  has_quiz boolean default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.learning_quizzes (
  id uuid primary key default uuid_generate_v4(),
  course_id uuid not null references public.learning_courses(id) on delete cascade,
  lesson_id uuid references public.learning_lessons(id) on delete cascade,
  title text not null,
  passing_score integer not null default 70,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.learning_quiz_questions (
  id uuid primary key default uuid_generate_v4(),
  quiz_id uuid not null references public.learning_quizzes(id) on delete cascade,
  prompt text not null,
  options jsonb not null,
  correct_option text not null,
  explanation text
);

create table if not exists public.learning_progress (
  id uuid primary key default uuid_generate_v4(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  course_id uuid not null references public.learning_courses(id) on delete cascade,
  completed_lessons jsonb default '[]'::jsonb,
  status text not null default 'in_progress',
  last_lesson_id uuid,
  completed_at timestamptz,
  last_accessed_at timestamptz,
  unique (profile_id, course_id)
);

create table if not exists public.learning_quiz_attempts (
  id uuid primary key default uuid_generate_v4(),
  quiz_id uuid not null references public.learning_quizzes(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  score integer not null,
  passed boolean not null,
  answers jsonb,
  created_at timestamptz not null default now()
);

alter table public.learning_courses enable row level security;
alter table public.learning_lessons enable row level security;
alter table public.learning_quizzes enable row level security;
alter table public.learning_quiz_questions enable row level security;
alter table public.learning_progress enable row level security;
alter table public.learning_quiz_attempts enable row level security;

create policy "Published courses visible"
  on public.learning_courses
  for select
  using (is_published or public.is_staff());

create policy "Staff manage courses"
  on public.learning_courses
  for all
  using (public.is_staff())
  with check (public.is_staff());

create policy "Lessons follow course visibility"
  on public.learning_lessons
  for select
  using (
    exists (
      select 1
      from public.learning_courses c
      where c.id = learning_lessons.course_id
        and (c.is_published or public.is_staff())
    )
  );

create policy "Quizzes follow course visibility"
  on public.learning_quizzes
  for select
  using (
    exists (
      select 1
      from public.learning_courses c
      where c.id = learning_quizzes.course_id
        and (c.is_published or public.is_staff())
    )
  );

create policy "Quiz question visibility"
  on public.learning_quiz_questions
  for select
  using (
    exists (
      select 1
      from public.learning_quizzes q
      join public.learning_courses c on c.id = q.course_id
      where q.id = learning_quiz_questions.quiz_id
        and (c.is_published or public.is_staff())
    )
  );

create policy "Learner progress access"
  on public.learning_progress
  for select
  using (profile_id = auth.uid() or public.is_staff());

create policy "Update own progress"
  on public.learning_progress
  for insert with check (profile_id = auth.uid());

create policy "Learner progress updates"
  on public.learning_progress
  for update
  using (profile_id = auth.uid() or public.is_staff())
  with check (profile_id = auth.uid() or public.is_staff());

create policy "Quiz attempts access"
  on public.learning_quiz_attempts
  for select
  using (profile_id = auth.uid() or public.is_staff());

create policy "Create quiz attempts"
  on public.learning_quiz_attempts
  for insert
  with check (profile_id = auth.uid() or public.is_staff());

create trigger on_update_learning_courses
  before update on public.learning_courses
  for each row
  execute procedure public.touch_updated_at();

create trigger on_update_learning_lessons
  before update on public.learning_lessons
  for each row
  execute procedure public.touch_updated_at();

create trigger on_update_learning_quizzes
  before update on public.learning_quizzes
  for each row
  execute procedure public.touch_updated_at();
