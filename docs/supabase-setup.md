# Supabase Setup

Project: `inventory`
Project ref: `jjypcucugbtmfjynhuvh`
Project URL: `https://jjypcucugbtmfjynhuvh.supabase.co`
Region shown in dashboard: Oceania (Sydney), `ap-southeast-2`

## GitHub Connection

The GitHub repository is:

`https://github.com/japhethrexcometa-droid/inventory`

In the Supabase dashboard, connect this repository from the project home page or GitHub integration area. After connecting, use migrations in `supabase/migrations/` as the source of truth for database changes.

## Secrets Rules

- Do not commit `.env.local` or any real `.env` file.
- The anon key is browser-safe only when Row Level Security policies are correct.
- The service role key must stay server-only.
- The database password must stay local or in a secure deployment secret store.
- Rotate the database password because it was shared in chat.

## Engineering Rules For This Project

- Design schema changes as SQL migrations.
- Enable Row Level Security on app tables before exposing them to the client.
- Write separate policies for `select`, `insert`, `update`, and `delete`.
- Test allowed and denied cases for user-owned and role-protected data.
- Use server-side code for privileged operations that require service role access.