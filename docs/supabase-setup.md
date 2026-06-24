# Supabase Setup

Project: `inventory`
Project ref: `jjypcucugbtmfjynhuvh`
Project URL: `https://jjypcucugbtmfjynhuvh.supabase.co`
Region shown in dashboard: Oceania (Sydney), `ap-southeast-2`

## GitHub Connection

The GitHub repository is:

`https://github.com/japhethrexcometa-droid/inventory`

In the Supabase dashboard, connect this repository from the project home page or GitHub integration area. After connecting, use migrations in `supabase/migrations/` as the source of truth for database changes.

## Local Control Path

Use Supabase CLI plus migrations for backend control:

1. Install or run the Supabase CLI locally.
2. Authenticate with a Supabase access token or `supabase login`.
3. Link this repository to project ref `jjypcucugbtmfjynhuvh`.
4. Create SQL migrations under `supabase/migrations/`.
5. Apply migrations through the CLI after reviewing schema, auth, and RLS changes.

Use `SUPABASE_PROJECT_REF=jjypcucugbtmfjynhuvh`. Do not use the REST URL as the project ref.

## Secrets Rules

- Do not commit `.env.local` or any real `.env` file.
- The anon/publishable key is browser-safe only when Row Level Security policies are correct.
- The service role key must stay server-only.
- The database password must stay local or in a secure deployment secret store.
- Supabase access tokens must stay local and must not be committed.
- Rotate the database password and service-role key if they were shared in chat or screenshots.

## Engineering Rules For This Project

- Design schema changes as SQL migrations.
- Enable Row Level Security on app tables before exposing them to the client.
- Write separate policies for `select`, `insert`, `update`, and `delete`.
- Test allowed and denied cases for user-owned and role-protected data.
- Use server-side code for privileged operations that require service role access.
- Never use service-role access in browser code.

## Applying Migrations

Use the local helper so the database password is prompted at runtime and never committed:

```powershell
C:\Users\ASUS\.cache\codex-runtimes\codex-primary-runtime\dependencies\bin\pnpm.cmd run supabase:push
```

To preview pending migrations first:

```powershell
C:\Users\ASUS\.cache\codex-runtimes\codex-primary-runtime\dependencies\bin\pnpm.cmd run supabase:push:dry-run
```

The helper clears `SUPABASE_DB_PASSWORD` from the process after the command finishes.