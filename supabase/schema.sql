-- =====================================================================
-- Agenda de Aulas Particulares — banco de dados (Supabase / PostgreSQL)
-- Cole este arquivo inteiro no "SQL Editor" do Supabase e clique em Run.
-- =====================================================================

create extension if not exists btree_gist;

-- Intervalo de horas (ex.: 14:00–15:30), usado para detectar sobreposição.
-- Formato [início, fim): uma aula que termina 15:00 não conflita com outra que começa 15:00.
do $$ begin
  create type public.faixa_horario as range (subtype = time);
exception when duplicate_object then null; end $$;

-- ---------------------------------------------------------------------
-- Tabelas
-- ---------------------------------------------------------------------

-- Quem pode entrar no sistema e com qual papel
create table if not exists public.perfis (
  user_id uuid primary key references auth.users (id) on delete cascade,
  papel   text not null check (papel in ('recepcao', 'professor'))
);

create table if not exists public.professores (
  id      bigint generated always as identity primary key,
  nome    text not null,
  user_id uuid unique references auth.users (id) on delete set null  -- login do professor
);

create table if not exists public.salas (
  id   bigint generated always as identity primary key,
  nome text not null
);

create table if not exists public.alunos (
  id       bigint generated always as identity primary key,
  nome     text not null,
  telefone text
);

-- Horários em que cada professor pode dar aula (ele mesmo cadastra)
create table if not exists public.disponibilidades (
  id           bigint generated always as identity primary key,
  professor_id bigint not null references public.professores (id) on delete cascade,
  dia_semana   smallint not null check (dia_semana between 0 and 6),  -- 0 = domingo
  inicio       time not null,
  fim          time not null,
  constraint disp_tarde_noite check (inicio >= '13:00' and fim <= '22:00'),
  constraint disp_minimo_1h   check (fim - inicio >= interval '1 hour'),
  constraint disp_sem_sobreposicao exclude using gist (
    professor_id with =, dia_semana with =, public.faixa_horario(inicio, fim) with &&)
);

create table if not exists public.aulas (
  id           bigint generated always as identity primary key,
  data         date not null,
  inicio       time not null,
  fim          time not null,
  aluno_id     bigint not null references public.alunos (id),
  professor_id bigint not null references public.professores (id),
  sala_id      bigint not null references public.salas (id),
  status       text not null default 'agendada'
               check (status in ('agendada', 'cancelada', 'realizada', 'falta')),
  criado_em    timestamptz not null default now(),

  -- Regras de horário
  constraint aula_tarde_noite  check (inicio >= '13:00' and fim <= '22:00'),
  constraint aula_minimo_1h    check (fim - inicio >= interval '1 hour'),
  constraint aula_de_30_em_30  check (extract(minute from inicio) in (0, 30)
                                      and extract(epoch from fim - inicio)::int % 1800 = 0),

  -- Ninguém em dois lugares ao mesmo tempo (aulas canceladas não contam)
  constraint conflito_professor exclude using gist (
    professor_id with =, data with =, public.faixa_horario(inicio, fim) with &&)
    where (status <> 'cancelada'),
  constraint conflito_sala exclude using gist (
    sala_id with =, data with =, public.faixa_horario(inicio, fim) with &&)
    where (status <> 'cancelada'),
  constraint conflito_aluno exclude using gist (
    aluno_id with =, data with =, public.faixa_horario(inicio, fim) with &&)
    where (status <> 'cancelada')
);

create index if not exists aulas_data_idx on public.aulas (data);

-- ---------------------------------------------------------------------
-- A aula precisa estar dentro da disponibilidade do professor
-- ---------------------------------------------------------------------
create or replace function public.checar_disponibilidade() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'agendada' and not exists (
    select 1 from disponibilidades d
    where d.professor_id = new.professor_id
      and d.dia_semana = extract(dow from new.data)
      and d.inicio <= new.inicio and d.fim >= new.fim
  ) then
    raise exception 'Professor não está disponível nesse horário.' using errcode = 'P0001';
  end if;
  return new;
end $$;

drop trigger if exists aulas_disponibilidade on public.aulas;
create trigger aulas_disponibilidade
  before insert or update of data, inicio, fim, professor_id, status on public.aulas
  for each row execute function public.checar_disponibilidade();

-- ---------------------------------------------------------------------
-- Funções de apoio para as permissões
-- ---------------------------------------------------------------------
create or replace function public.eh_recepcao() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from perfis where user_id = auth.uid() and papel = 'recepcao');
$$;

create or replace function public.meu_professor_id() returns bigint
language sql stable security definer set search_path = public as $$
  select id from professores where user_id = auth.uid();
$$;

-- A recepção dá acesso a um professor pelo e-mail (o usuário precisa já existir no Supabase)
create or replace function public.vincular_professor(p_professor_id bigint, p_email text) returns void
language plpgsql security definer set search_path = public as $$
declare v_user uuid;
begin
  if not eh_recepcao() then raise exception 'Só a recepção pode dar acesso.'; end if;
  select id into v_user from auth.users where lower(email) = lower(trim(p_email));
  if v_user is null then
    raise exception 'Nenhum usuário com o e-mail %. Crie o usuário no Supabase (Authentication → Add user).', p_email;
  end if;
  update professores set user_id = null where user_id = v_user;
  update professores set user_id = v_user where id = p_professor_id;
  insert into perfis (user_id, papel) values (v_user, 'professor')
    on conflict (user_id) do update set papel = excluded.papel;
end $$;

-- ---------------------------------------------------------------------
-- Permissões (Row Level Security)
--   Recepção: vê e altera tudo.
--   Professor: vê só as próprias aulas e os alunos dessas aulas,
--              e altera só a própria disponibilidade.
-- ---------------------------------------------------------------------
alter table public.perfis           enable row level security;
alter table public.professores      enable row level security;
alter table public.salas            enable row level security;
alter table public.alunos           enable row level security;
alter table public.disponibilidades enable row level security;
alter table public.aulas            enable row level security;

drop policy if exists perfis_ler on public.perfis;
create policy perfis_ler on public.perfis for select to authenticated
  using (user_id = auth.uid() or public.eh_recepcao());
drop policy if exists perfis_recepcao on public.perfis;
create policy perfis_recepcao on public.perfis for all to authenticated
  using (public.eh_recepcao()) with check (public.eh_recepcao());

drop policy if exists professores_ler on public.professores;
create policy professores_ler on public.professores for select to authenticated
  using (public.eh_recepcao() or user_id = auth.uid());
drop policy if exists professores_recepcao on public.professores;
create policy professores_recepcao on public.professores for all to authenticated
  using (public.eh_recepcao()) with check (public.eh_recepcao());

drop policy if exists salas_ler on public.salas;
create policy salas_ler on public.salas for select to authenticated using (true);
drop policy if exists salas_recepcao on public.salas;
create policy salas_recepcao on public.salas for all to authenticated
  using (public.eh_recepcao()) with check (public.eh_recepcao());

drop policy if exists alunos_ler on public.alunos;
create policy alunos_ler on public.alunos for select to authenticated
  using (public.eh_recepcao() or exists (
    select 1 from public.aulas a
    where a.aluno_id = alunos.id and a.professor_id = public.meu_professor_id()));
drop policy if exists alunos_recepcao on public.alunos;
create policy alunos_recepcao on public.alunos for all to authenticated
  using (public.eh_recepcao()) with check (public.eh_recepcao());

drop policy if exists aulas_ler on public.aulas;
create policy aulas_ler on public.aulas for select to authenticated
  using (public.eh_recepcao() or professor_id = public.meu_professor_id());
drop policy if exists aulas_recepcao on public.aulas;
create policy aulas_recepcao on public.aulas for all to authenticated
  using (public.eh_recepcao()) with check (public.eh_recepcao());

drop policy if exists disp_ler on public.disponibilidades;
create policy disp_ler on public.disponibilidades for select to authenticated
  using (public.eh_recepcao() or professor_id = public.meu_professor_id());
drop policy if exists disp_alterar on public.disponibilidades;
create policy disp_alterar on public.disponibilidades for all to authenticated
  using (public.eh_recepcao() or professor_id = public.meu_professor_id())
  with check (public.eh_recepcao() or professor_id = public.meu_professor_id());

grant usage on schema public to authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant execute on function public.vincular_professor(bigint, text) to authenticated;
