-- 1. Registrar o módulo de Ofícios na tabela public.modules
INSERT INTO public.modules (name, slug, icon, description, sort_order, is_system)
VALUES ('Ofícios', 'oficios', 'FileText', 'Gestão e emissão de ofícios do gabinete', 7, false)
ON CONFLICT (slug) DO UPDATE 
SET name = EXCLUDED.name,
    icon = EXCLUDED.icon,
    description = EXCLUDED.description,
    sort_order = EXCLUDED.sort_order;

-- 2. Vincular o módulo de Ofícios ao perfil 'admin'
DO $$ 
DECLARE
  v_admin_role_id uuid;
  v_module_id uuid;
BEGIN
  SELECT id INTO v_admin_role_id FROM public.roles WHERE slug = 'admin' LIMIT 1;
  SELECT id INTO v_module_id FROM public.modules WHERE slug = 'oficios' LIMIT 1;
  
  IF v_admin_role_id IS NOT NULL AND v_module_id IS NOT NULL THEN
    INSERT INTO public.role_module_permissions (role_id, module_id)
    VALUES (v_admin_role_id, v_module_id)
    ON CONFLICT DO NOTHING;
  END IF;
END $$;

-- 3. Vincular o módulo de Ofícios ao perfil 'colaborador'
DO $$ 
DECLARE
  v_colab_role_id uuid;
  v_module_id uuid;
BEGIN
  SELECT id INTO v_colab_role_id FROM public.roles WHERE slug = 'colaborador' LIMIT 1;
  SELECT id INTO v_module_id FROM public.modules WHERE slug = 'oficios' LIMIT 1;
  
  IF v_colab_role_id IS NOT NULL AND v_module_id IS NOT NULL THEN
    INSERT INTO public.role_module_permissions (role_id, module_id)
    VALUES (v_colab_role_id, v_module_id)
    ON CONFLICT DO NOTHING;
  END IF;
END $$;
