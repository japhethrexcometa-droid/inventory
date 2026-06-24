-- Initial inventory schema with Supabase Auth-aware Row Level Security.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE public.app_role AS ENUM ('owner', 'admin', 'manager', 'staff', 'viewer');
CREATE TYPE public.member_status AS ENUM ('active', 'invited', 'disabled');
CREATE TYPE public.location_type AS ENUM ('warehouse', 'store', 'stockroom', 'other');
CREATE TYPE public.stock_movement_type AS ENUM ('initial', 'purchase', 'sale', 'adjustment', 'transfer_in', 'transfer_out', 'return', 'damage');

CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  full_name text,
  avatar_url text,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.organizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text NOT NULL UNIQUE,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT organizations_slug_format CHECK (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$')
);

CREATE TABLE public.organization_members (
  organization_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.app_role NOT NULL DEFAULT 'staff',
  status public.member_status NOT NULL DEFAULT 'active',
  invited_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (organization_id, user_id)
);

CREATE TABLE public.locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  name text NOT NULL,
  type public.location_type NOT NULL DEFAULT 'warehouse',
  address text,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (organization_id, name),
  UNIQUE (organization_id, id)
);

CREATE TABLE public.categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (organization_id, name),
  UNIQUE (organization_id, id)
);

CREATE TABLE public.suppliers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  name text NOT NULL,
  contact_name text,
  email text,
  phone text,
  address text,
  notes text,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (organization_id, name),
  UNIQUE (organization_id, id)
);

CREATE TABLE public.products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  category_id uuid,
  supplier_id uuid,
  sku text NOT NULL,
  barcode text,
  name text NOT NULL,
  description text,
  unit text NOT NULL DEFAULT 'pc',
  cost_price numeric(12,2) NOT NULL DEFAULT 0 CHECK (cost_price >= 0),
  sale_price numeric(12,2) NOT NULL DEFAULT 0 CHECK (sale_price >= 0),
  reorder_level numeric(12,3) NOT NULL DEFAULT 0 CHECK (reorder_level >= 0),
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (organization_id, sku),
  UNIQUE (organization_id, barcode),
  UNIQUE (organization_id, id),
  FOREIGN KEY (organization_id, category_id) REFERENCES public.categories(organization_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (organization_id, supplier_id) REFERENCES public.suppliers(organization_id, id) ON DELETE RESTRICT
);

CREATE TABLE public.stock_levels (
  organization_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  product_id uuid NOT NULL,
  location_id uuid NOT NULL,
  quantity numeric(14,3) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  reserved_quantity numeric(14,3) NOT NULL DEFAULT 0 CHECK (reserved_quantity >= 0),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (product_id, location_id),
  CONSTRAINT stock_levels_reserved_lte_quantity CHECK (reserved_quantity <= quantity),
  FOREIGN KEY (organization_id, product_id) REFERENCES public.products(organization_id, id) ON DELETE CASCADE,
  FOREIGN KEY (organization_id, location_id) REFERENCES public.locations(organization_id, id) ON DELETE CASCADE
);

CREATE TABLE public.stock_movements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  product_id uuid NOT NULL,
  location_id uuid NOT NULL,
  movement_type public.stock_movement_type NOT NULL,
  quantity_delta numeric(14,3) NOT NULL CHECK (quantity_delta <> 0),
  unit_cost numeric(12,2) CHECK (unit_cost IS NULL OR unit_cost >= 0),
  reference_type text,
  reference_id uuid,
  notes text,
  performed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL DEFAULT auth.uid(),
  created_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (organization_id, product_id) REFERENCES public.products(organization_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (organization_id, location_id) REFERENCES public.locations(organization_id, id) ON DELETE RESTRICT
);

CREATE TABLE public.audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE,
  actor_id uuid REFERENCES auth.users(id) ON DELETE SET NULL DEFAULT auth.uid(),
  action text NOT NULL,
  entity_table text NOT NULL,
  entity_id uuid,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX organization_members_user_id_idx ON public.organization_members(user_id);
CREATE INDEX locations_organization_id_idx ON public.locations(organization_id);
CREATE INDEX categories_organization_id_idx ON public.categories(organization_id);
CREATE INDEX suppliers_organization_id_idx ON public.suppliers(organization_id);
CREATE INDEX products_organization_id_idx ON public.products(organization_id);
CREATE INDEX products_category_id_idx ON public.products(category_id);
CREATE INDEX products_supplier_id_idx ON public.products(supplier_id);
CREATE INDEX stock_levels_organization_id_idx ON public.stock_levels(organization_id);
CREATE INDEX stock_levels_location_id_idx ON public.stock_levels(location_id);
CREATE INDEX stock_movements_organization_id_created_at_idx ON public.stock_movements(organization_id, created_at DESC);
CREATE INDEX stock_movements_product_id_created_at_idx ON public.stock_movements(product_id, created_at DESC);
CREATE INDEX audit_logs_organization_id_created_at_idx ON public.audit_logs(organization_id, created_at DESC);

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER set_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_organizations_updated_at
BEFORE UPDATE ON public.organizations
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_organization_members_updated_at
BEFORE UPDATE ON public.organization_members
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_locations_updated_at
BEFORE UPDATE ON public.locations
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_categories_updated_at
BEFORE UPDATE ON public.categories
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_suppliers_updated_at
BEFORE UPDATE ON public.suppliers
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_products_updated_at
BEFORE UPDATE ON public.products
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_stock_levels_updated_at
BEFORE UPDATE ON public.stock_levels
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE FUNCTION public.apply_stock_movement()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.stock_levels (organization_id, product_id, location_id, quantity, updated_at)
  VALUES (NEW.organization_id, NEW.product_id, NEW.location_id, NEW.quantity_delta, now())
  ON CONFLICT (product_id, location_id) DO UPDATE
  SET quantity = public.stock_levels.quantity + EXCLUDED.quantity,
      updated_at = now();

  RETURN NEW;
END;
$$;

CREATE TRIGGER apply_stock_movement_after_insert
AFTER INSERT ON public.stock_movements
FOR EACH ROW EXECUTE FUNCTION public.apply_stock_movement();

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.email, ''),
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', NEW.raw_user_meta_data ->> 'name'),
    NEW.raw_user_meta_data ->> 'avatar_url'
  )
  ON CONFLICT (id) DO UPDATE
  SET email = EXCLUDED.email,
      full_name = COALESCE(public.profiles.full_name, EXCLUDED.full_name),
      avatar_url = COALESCE(public.profiles.avatar_url, EXCLUDED.avatar_url),
      updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE OR REPLACE FUNCTION public.is_org_member(target_org_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.organization_members om
    WHERE om.organization_id = target_org_id
      AND om.user_id = auth.uid()
      AND om.status = 'active'
  );
$$;

CREATE OR REPLACE FUNCTION public.has_org_role(target_org_id uuid, allowed_roles public.app_role[])
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.organization_members om
    WHERE om.organization_id = target_org_id
      AND om.user_id = auth.uid()
      AND om.status = 'active'
      AND om.role = ANY(allowed_roles)
  );
$$;

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organization_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own profile"
ON public.profiles FOR SELECT
TO authenticated
USING (id = auth.uid());

CREATE POLICY "Users can update own profile"
ON public.profiles FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

CREATE POLICY "Members can read organizations"
ON public.organizations FOR SELECT
TO authenticated
USING (public.is_org_member(id));

CREATE POLICY "Authenticated users can create organizations"
ON public.organizations FOR INSERT
TO authenticated
WITH CHECK (created_by = auth.uid());

CREATE POLICY "Owners and admins can update organizations"
ON public.organizations FOR UPDATE
TO authenticated
USING (public.has_org_role(id, ARRAY['owner', 'admin']::public.app_role[]))
WITH CHECK (public.has_org_role(id, ARRAY['owner', 'admin']::public.app_role[]));

CREATE POLICY "Members can read memberships"
ON public.organization_members FOR SELECT
TO authenticated
USING (public.is_org_member(organization_id));

CREATE POLICY "Organization creators can add first owner membership"
ON public.organization_members FOR INSERT
TO authenticated
WITH CHECK (
  user_id = auth.uid()
  AND role = 'owner'
  AND status = 'active'
  AND EXISTS (
    SELECT 1 FROM public.organizations o
    WHERE o.id = organization_id
      AND o.created_by = auth.uid()
  )
);

CREATE POLICY "Owners and admins can manage memberships"
ON public.organization_members FOR ALL
TO authenticated
USING (public.has_org_role(organization_id, ARRAY['owner', 'admin']::public.app_role[]))
WITH CHECK (public.has_org_role(organization_id, ARRAY['owner', 'admin']::public.app_role[]));

CREATE POLICY "Members can read locations"
ON public.locations FOR SELECT
TO authenticated
USING (public.is_org_member(organization_id));

CREATE POLICY "Managers can manage locations"
ON public.locations FOR ALL
TO authenticated
USING (public.has_org_role(organization_id, ARRAY['owner', 'admin', 'manager']::public.app_role[]))
WITH CHECK (public.has_org_role(organization_id, ARRAY['owner', 'admin', 'manager']::public.app_role[]));

CREATE POLICY "Members can read categories"
ON public.categories FOR SELECT
TO authenticated
USING (public.is_org_member(organization_id));

CREATE POLICY "Managers can manage categories"
ON public.categories FOR ALL
TO authenticated
USING (public.has_org_role(organization_id, ARRAY['owner', 'admin', 'manager']::public.app_role[]))
WITH CHECK (public.has_org_role(organization_id, ARRAY['owner', 'admin', 'manager']::public.app_role[]));

CREATE POLICY "Members can read suppliers"
ON public.suppliers FOR SELECT
TO authenticated
USING (public.is_org_member(organization_id));

CREATE POLICY "Managers can manage suppliers"
ON public.suppliers FOR ALL
TO authenticated
USING (public.has_org_role(organization_id, ARRAY['owner', 'admin', 'manager']::public.app_role[]))
WITH CHECK (public.has_org_role(organization_id, ARRAY['owner', 'admin', 'manager']::public.app_role[]));

CREATE POLICY "Members can read products"
ON public.products FOR SELECT
TO authenticated
USING (public.is_org_member(organization_id));

CREATE POLICY "Managers can manage products"
ON public.products FOR ALL
TO authenticated
USING (public.has_org_role(organization_id, ARRAY['owner', 'admin', 'manager']::public.app_role[]))
WITH CHECK (public.has_org_role(organization_id, ARRAY['owner', 'admin', 'manager']::public.app_role[]));

CREATE POLICY "Members can read stock levels"
ON public.stock_levels FOR SELECT
TO authenticated
USING (public.is_org_member(organization_id));

CREATE POLICY "Staff can manage stock levels"
ON public.stock_levels FOR ALL
TO authenticated
USING (public.has_org_role(organization_id, ARRAY['owner', 'admin', 'manager', 'staff']::public.app_role[]))
WITH CHECK (public.has_org_role(organization_id, ARRAY['owner', 'admin', 'manager', 'staff']::public.app_role[]));

CREATE POLICY "Members can read stock movements"
ON public.stock_movements FOR SELECT
TO authenticated
USING (public.is_org_member(organization_id));

CREATE POLICY "Staff can create stock movements"
ON public.stock_movements FOR INSERT
TO authenticated
WITH CHECK (
  performed_by = auth.uid()
  AND public.has_org_role(organization_id, ARRAY['owner', 'admin', 'manager', 'staff']::public.app_role[])
);

CREATE POLICY "Managers can update stock movements"
ON public.stock_movements FOR UPDATE
TO authenticated
USING (public.has_org_role(organization_id, ARRAY['owner', 'admin', 'manager']::public.app_role[]))
WITH CHECK (public.has_org_role(organization_id, ARRAY['owner', 'admin', 'manager']::public.app_role[]));

CREATE POLICY "Admins can read audit logs"
ON public.audit_logs FOR SELECT
TO authenticated
USING (public.has_org_role(organization_id, ARRAY['owner', 'admin']::public.app_role[]));

CREATE POLICY "System can create audit logs for members"
ON public.audit_logs FOR INSERT
TO authenticated
WITH CHECK (actor_id = auth.uid() AND public.is_org_member(organization_id));
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.organizations TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.organization_members TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.locations TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.categories TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.suppliers TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.products TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.stock_levels TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.stock_movements TO authenticated;
GRANT SELECT, INSERT ON public.audit_logs TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_org_member(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.has_org_role(uuid, public.app_role[]) TO authenticated;