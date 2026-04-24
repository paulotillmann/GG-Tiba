-- ==========================================
-- GESTÃO GABINETE - SEED DATA
-- Insere os dados iniciais do RBAC necessários
-- ==========================================

-- 1. Inserir Roles (Perfis)
INSERT INTO public.roles (name, slug, can_upload, can_send_email, can_view_all, is_system)
VALUES 
  ('Administrador', 'admin', true, true, true, true),
  ('Colaborador', 'colaborador', true, false, false, true),
  ('Visitante', 'visitante', false, false, false, true)
ON CONFLICT (slug) DO NOTHING;

-- 2. Inserir Módulos Iniciais (Telas)
INSERT INTO public.modules (name, slug, icon, description, sort_order, is_system)
VALUES
  ('Dashboard', 'dashboard', 'LayoutDashboard', 'Visão geral do gabinete', 1, true),
  ('Pessoas e Entidades', 'pessoas', 'Users', 'Gestão de contatos', 2, true),
  ('Agenda', 'agenda', 'Calendar', 'Compromissos', 3, true),
  ('Requerimentos', 'requerimentos', 'FileText', 'Gestão de requerimentos', 4, true),
  ('Atendimento (WhatsApp)', 'atendimento', 'MessageSquare', 'Integração de mensagens', 5, false),
  ('Anotações', 'anotacoes', 'StickyNote', 'Quadro Kanban de anotações', 6, false),
  ('Configurações', 'configuracoes', 'Settings', 'Gestão do sistema', 99, true)
ON CONFLICT (slug) DO NOTHING;

-- 3. Vincular Perfil Admin a todos os módulos
DO $$ 
DECLARE
  v_admin_id uuid;
  v_module RECORD;
BEGIN
  SELECT id INTO v_admin_id FROM public.roles WHERE slug = 'admin' LIMIT 1;
  
  IF v_admin_id IS NOT NULL THEN
    FOR v_module IN SELECT id FROM public.modules LOOP
      INSERT INTO public.role_module_permissions (role_id, module_id)
      VALUES (v_admin_id, v_module.id)
      ON CONFLICT DO NOTHING;
    END LOOP;
  END IF;
END $$;
