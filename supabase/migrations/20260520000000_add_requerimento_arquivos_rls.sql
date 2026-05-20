-- Add RLS policy for requerimento_arquivos
CREATE POLICY "Permissao Total Autenticado" ON public.requerimento_arquivos FOR ALL TO authenticated USING (true) WITH CHECK (true);
