-- ==========================================
-- GESTÃO GABINETE - DATABASE SCHEMA
-- Script unificado para inicialização do Supabase
-- ==========================================

-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;

-- ==========================================
-- 1. Tabelas de Configuração e RBAC
-- ==========================================

CREATE TABLE public.roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text NOT NULL UNIQUE,
  can_upload boolean NOT NULL DEFAULT false,
  can_send_email boolean NOT NULL DEFAULT false,
  can_view_all boolean NOT NULL DEFAULT false,
  is_system boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text,
  email text,
  avatar_url text,
  telefone text,
  role text NOT NULL DEFAULT 'colaborador',
  role_id uuid REFERENCES public.roles(id),
  theme text DEFAULT 'light' CHECK (theme IN ('light', 'dark')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.modules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text NOT NULL UNIQUE,
  icon text NOT NULL DEFAULT 'Layout',
  description text,
  is_active boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  is_system boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.role_module_permissions (
  role_id uuid NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
  module_id uuid NOT NULL REFERENCES public.modules(id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, module_id)
);

-- ==========================================
-- 2. Funções Helper (RBAC e Helpers)
-- ==========================================

CREATE OR REPLACE FUNCTION get_my_role()
RETURNS text LANGUAGE sql SECURITY DEFINER AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION get_my_can_upload()
RETURNS boolean LANGUAGE sql SECURITY DEFINER AS $$
  SELECT COALESCE(r.can_upload, false)
  FROM profiles p
  LEFT JOIN roles r ON r.id = p.role_id
  WHERE p.id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION get_my_can_send_email()
RETURNS boolean LANGUAGE sql SECURITY DEFINER AS $$
  SELECT COALESCE(r.can_send_email, false)
  FROM profiles p
  LEFT JOIN roles r ON r.id = p.role_id
  WHERE p.id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION get_my_can_view_all()
RETURNS boolean LANGUAGE sql SECURITY DEFINER AS $$
  SELECT COALESCE(r.can_view_all, false)
  FROM profiles p
  JOIN roles r ON r.id = p.role_id
  WHERE p.id = auth.uid();
$$;

-- ==========================================
-- 3. Triggers Padrão (updated_at, auth, role_sync)
-- ==========================================

CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, avatar_url, telefone)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data ->> 'full_name',
    NEW.email,
    NEW.raw_user_meta_data ->> 'avatar_url',
    NEW.raw_user_meta_data ->> 'telefone'
  );
  RETURN NEW;
END;
$$;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION handle_new_user();

CREATE OR REPLACE FUNCTION sync_profile_role()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  v_slug TEXT;
BEGIN
  IF NEW.role_id IS NOT NULL THEN
    SELECT slug INTO v_slug FROM public.roles WHERE id = NEW.role_id;
    NEW.role := CASE WHEN v_slug = 'admin' THEN 'admin' ELSE 'colaborador' END;
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER set_profile_role BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION sync_profile_role();

-- ==========================================
-- 4. Tabelas de Domínio (Pessoas, Agenda, etc)
-- ==========================================

CREATE TABLE public.pessoa (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  full_name text NOT NULL,
  pronoun text DEFAULT 'Sr.',
  address text,
  neighborhood text,
  city text,
  housing_type text,
  phone text,
  birth_date date,
  email text,
  cpf text UNIQUE,
  cnpj text UNIQUE,
  facebook_url text,
  instagram_url text,
  reference text,
  notes text,
  person_type text DEFAULT 'Pessoa' CHECK (person_type IN ('Pessoa', 'Autoridade', 'Entidade', 'Empresa')),
  cep text,
  latitude numeric,
  longitude numeric,
  address_number text,
  destino text,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE public.dependentes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pessoa_id uuid NOT NULL REFERENCES public.pessoa(id) ON DELETE CASCADE,
  full_name text NOT NULL,
  birth_date date,
  cpf text,
  kinship text,
  phone text,
  notes text,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE public.agenda (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  titulo_compromisso text NOT NULL,
  tipo text CHECK (tipo IN ('Reunião', 'Visita', 'Outros')),
  data date NOT NULL,
  horario_inicio time without time zone NOT NULL,
  horario_fim time without time zone,
  local text,
  pessoa_id uuid REFERENCES public.pessoa(id) ON DELETE SET NULL,
  descricao text,
  lembrar boolean DEFAULT false,
  user_id uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE public.requerimento (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  numero_requerimento text NOT NULL,
  data_sessao date NOT NULL,
  titulo text NOT NULL,
  pessoa_id uuid REFERENCES public.pessoa(id) ON DELETE SET NULL,
  resposta_recebida text CHECK (resposta_recebida IN ('Sim', 'Não', 'Novo Requerimento', 'Delação de Prazo')),
  status text DEFAULT 'Apresentado' CHECK (status IN ('Apresentado', 'Aguardando Resposta', 'Respondido', 'Não Respondido')),
  numero_oficio text,
  data_protocolo date,
  informacoes_adicionais text,
  arquivo_pdf_url text,
  user_id uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE public.requerimento_arquivos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  requerimento_id uuid NOT NULL REFERENCES public.requerimento(id) ON DELETE CASCADE,
  nome_arquivo text NOT NULL,
  arquivo_url text NOT NULL,
  tamanho_bytes bigint,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE public.atendimento (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id),
  conversa_ia text,
  conversa_pessoa text,
  data_conversa timestamptz DEFAULT now(),
  whatsapp text,
  status text DEFAULT 'recebido' CHECK (status IN ('recebido', 'verificado', 'em atendimento', 'concluído')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

DO $$ BEGIN
  CREATE TYPE public.anotacao_status AS ENUM ('recebido', 'lido', 'resolvendo', 'concluído');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

CREATE TABLE public.anotacoes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  whatsapp text NOT NULL,
  descricao_anotacao text NOT NULL,
  data_hora timestamptz DEFAULT now(),
  status public.anotacao_status DEFAULT 'recebido'::public.anotacao_status,
  user_id uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE public.activity_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id),
  user_email text,
  user_name text,
  action text NOT NULL,
  table_name text,
  record_id text,
  description text,
  metadata jsonb DEFAULT '{}'::jsonb,
  ip_address text,
  created_at timestamptz DEFAULT now()
);

-- ==========================================
-- 5. Habilitar RLS em todas as tabelas
-- ==========================================

ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.role_module_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pessoa ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dependentes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agenda ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.requerimento ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.requerimento_arquivos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.atendimento ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.anotacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- 6. Políticas de RLS Base (Conforme rbac_documentation)
-- ==========================================

-- Roles, Modules, Role_Module_Permissions: Leitura para todos logados, Escrita apenas Admin
CREATE POLICY "Leitura autenticada" ON public.roles FOR SELECT TO authenticated USING (true);
CREATE POLICY "Escrita admin" ON public.roles FOR ALL TO authenticated USING (get_my_role() = 'admin');

CREATE POLICY "Leitura autenticada" ON public.modules FOR SELECT TO authenticated USING (true);
CREATE POLICY "Escrita admin" ON public.modules FOR ALL TO authenticated USING (get_my_role() = 'admin');

CREATE POLICY "Leitura autenticada" ON public.role_module_permissions FOR SELECT TO authenticated USING (true);
CREATE POLICY "Escrita admin" ON public.role_module_permissions FOR ALL TO authenticated USING (get_my_role() = 'admin');

-- Profiles
CREATE POLICY "Leitura próprio perfil" ON public.profiles FOR SELECT TO authenticated USING (auth.uid() = id);
CREATE POLICY "Leitura admin" ON public.profiles FOR SELECT TO authenticated USING (get_my_role() = 'admin');
CREATE POLICY "Escrita próprio" ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id);
CREATE POLICY "Escrita admin" ON public.profiles FOR ALL TO authenticated USING (get_my_role() = 'admin');

-- Políticas baseadas em get_my_can_view_all() e autenticação geral:
CREATE POLICY "Pessoa geral" ON public.pessoa FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Agenda leitura" ON public.agenda FOR SELECT TO authenticated USING (get_my_can_view_all() OR user_id = auth.uid());
CREATE POLICY "Agenda escrita" ON public.agenda FOR ALL TO authenticated USING (get_my_can_upload());

-- Obs: As policies das tabelas de negócio podem variar, sugerimos políticas iniciais de permissão total para authenticated, e refinar via UI do Supabase de acordo com o gabinete.
CREATE POLICY "Permissao Total Autenticado" ON public.requerimento FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Permissao Total Autenticado" ON public.atendimento FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Permissao Total Autenticado" ON public.anotacoes FOR ALL TO authenticated USING (true) WITH CHECK (true);
