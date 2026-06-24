# Database Schema

The inventory database is Supabase Auth-aware and organization-scoped.

## Core Flow

1. A user signs up through Supabase Auth.
2. `public.handle_new_user()` creates a matching `profiles` row.
3. The user creates an `organizations` row with `created_by = auth.uid()`.
4. The user creates the first `organization_members` row as `owner` for that organization.
5. Locations, categories, suppliers, products, stock levels, stock movements, and audit logs are all scoped by `organization_id`.

## Access Model

- `owner` and `admin`: manage organization, members, inventory setup, stock, and audit visibility.
- `manager`: manage locations, categories, suppliers, products, stock levels, and stock movements.
- `staff`: create stock movements and manage stock levels.
- `viewer`: read organization inventory data only.

## Security Model

- Row Level Security is enabled on every app table.
- Anonymous users have no direct app-table access.
- Authenticated users are limited by organization membership and role policies.
- Composite foreign keys keep product, category, supplier, location, stock, and movement records inside the same organization.
- `stock_movements` insertions update `stock_levels` through a database trigger.
- Service-role access must remain server-only.