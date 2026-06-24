-- Security hardening: these log tables should not be exposed through anon/authenticated client access.
-- No permissive policies are added here, so normal client roles remain blocked by default.
ALTER TABLE public.qr_token_rotation_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.token_generation_log ENABLE ROW LEVEL SECURITY;