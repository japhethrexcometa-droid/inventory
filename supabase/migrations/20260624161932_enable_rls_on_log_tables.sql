-- Security hardening: these log tables should not be exposed through anon/authenticated client access.
-- No permissive policies are added here, so normal client roles remain blocked by default.
-- IF EXISTS keeps the migration safe across environments where one log table has not been created.
ALTER TABLE IF EXISTS public.qr_token_rotation_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.token_generation_log ENABLE ROW LEVEL SECURITY;