-- 1. Create oficios_seq table
CREATE TABLE IF NOT EXISTS public.oficios_seq (
    ano integer PRIMARY KEY,
    ultimo_numero integer NOT NULL DEFAULT 0,
    created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 2. Enable RLS on oficios_seq
ALTER TABLE public.oficios_seq ENABLE ROW LEVEL SECURITY;

-- RLS policies for oficios_seq
CREATE POLICY "Users can view oficios_seq" ON public.oficios_seq
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Users can insert oficios_seq" ON public.oficios_seq
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Users can update oficios_seq" ON public.oficios_seq
    FOR UPDATE TO authenticated USING (true);

-- 3. Create oficios table
CREATE TABLE IF NOT EXISTS public.oficios (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    numero text,
    data_emissao date NOT NULL DEFAULT CURRENT_DATE,
    destinatario_tratamento text,
    destinatario_nome text NOT NULL,
    destinatario_cargo text,
    assunto text NOT NULL,
    conteudo text,
    assinatura_nome text,
    assinatura_cargo text,
    status text NOT NULL DEFAULT 'Rascunho'::text,
    created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
    created_by uuid REFERENCES auth.users(id),
    solicitante text,
    resposta text
);

-- 4. Enable RLS on oficios
ALTER TABLE public.oficios ENABLE ROW LEVEL SECURITY;

-- RLS policies for oficios
CREATE POLICY "Oficios read access" ON public.oficios
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Oficios insert access" ON public.oficios
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Oficios update access" ON public.oficios
    FOR UPDATE TO authenticated USING (true);

CREATE POLICY "Oficios delete access" ON public.oficios
    FOR DELETE TO authenticated USING (true);

-- 5. Create trigger function generate_oficio_numero()
CREATE OR REPLACE FUNCTION public.generate_oficio_numero()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  current_year integer;
  next_num integer;
BEGIN
  current_year := extract(year from NEW.data_emissao);
  
  -- Insere o ano (começando em 1) ou incrementa se já existir
  INSERT INTO public.oficios_seq (ano, ultimo_numero)
  VALUES (current_year, 1)
  ON CONFLICT (ano) DO UPDATE
  SET ultimo_numero = public.oficios_seq.ultimo_numero + 1
  RETURNING ultimo_numero INTO next_num;
  
  -- Formata a string (ex: Ofício n. 876/2026)
  NEW.numero := 'Ofício n. ' || next_num || '/' || current_year;
  
  RETURN NEW;
END;
$function$;

-- 6. Create trigger trg_generate_oficio_numero
CREATE TRIGGER trg_generate_oficio_numero
    BEFORE INSERT ON public.oficios
    FOR EACH ROW
    EXECUTE FUNCTION public.generate_oficio_numero();
