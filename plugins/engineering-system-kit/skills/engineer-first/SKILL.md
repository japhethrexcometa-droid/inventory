---
name: engineer-first
description: Full-stack engineering operating procedure for Codex. Use before and during software work that involves engineering design, fixing, debugging, architecture, system flow, authentication, authorization, application security, Git/GitHub version control, Supabase backend/auth/security, feature implementation, refactoring, integrations, performance, reliability, tests, deployment readiness, plugin or skill creation, or any request where Codex should think and act like an engineer before changing a system.
---

# Engineer First

## Operating Principle

Start every engineering task by understanding the system before changing it. Treat code, configuration, data flow, user experience, authentication, authorization, security boundaries, tests, runtime behavior, and deployment constraints, repository history, and backend provider constraints as one connected system.

Use this skill to bring an engineer's mindset to the work: design carefully, debug from evidence, protect the system, implement with existing patterns, verify behavior, and explain tradeoffs plainly.

## First Pass

1. Clarify the requested outcome, the affected users, and the expected behavior.
2. Inspect the repository structure, relevant files, scripts, configuration, and existing conventions.
3. Identify the current system flow: inputs, identity, permissions, state, processing, side effects, outputs, and failure paths.
4. Name the engineering lens that matters most: design, debugging, architecture, authentication, authorization, security, version control, Supabase/backend, full-stack implementation, reliability, performance, data, UI, integration, or deployment.
5. Choose the smallest change that solves the problem while preserving the surrounding system.
6. Verify with the strongest practical check available: tests, build, typecheck, lint, local run, logs, or focused manual inspection.

## Engineering Lenses

### Design Engineering

Use when creating or reshaping features, APIs, workflows, UI, schemas, or modules.

- Define the user or system problem before designing the solution.
- Prefer existing patterns and local abstractions over new structure.
- Keep interfaces explicit: inputs, outputs, contracts, ownership, permissions, and error behavior.
- Design for maintainability first, then convenience.
- Avoid broad rewrites unless the current shape blocks the requested outcome.

### Fixing And Debugging

Use when behavior is broken, inconsistent, slow, flaky, insecure, or unclear.

- Reproduce or reason from concrete evidence before editing.
- Trace the path from symptom to source: UI/event, API, service, auth/session layer, persistence, job, or external dependency.
- Check recent changes, assumptions, boundary cases, null/empty states, race conditions, permissions, environment variables, and serialization.
- Make the fix as close to the root cause as practical.
- Add or update focused tests when the bug can reasonably regress.

### Architecture Engineering

Use when the work affects boundaries, modules, services, scaling, security, deployment, or long-term maintainability.

- Map components and ownership before changing contracts.
- Preserve stable public interfaces unless the request explicitly includes migration.
- Consider coupling, data ownership, trust boundaries, failure isolation, observability, configuration, and rollback.
- Prefer incremental migration paths over big-bang changes.
- Document important architectural decisions in code, tests, or existing docs only when they will help future maintainers.

### Flow And System Engineering

Use when the system has multi-step behavior, background jobs, inventory/order flows, integrations, data pipelines, auth flows, or state transitions.

- Identify each state transition and who owns it.
- Check validation, authentication, authorization, idempotency, retries, duplicate events, partial failure, and cleanup paths.
- Keep business rules centralized where the codebase already centralizes them.
- Make hidden assumptions visible through names, tests, guards, or structured errors.

### Authentication And Authorization Engineering

Use when work touches login, signup, sessions, tokens, roles, permissions, user identity, account recovery, API access, admin features, or tenant/data ownership.

- Identify who the actor is, how identity is established, and where trust begins.
- Separate authentication from authorization: prove identity first, then check what the actor may do.
- Enforce authorization on the server side or trusted boundary, not only in the UI.
- Check direct object access risks: users must not access records by guessing IDs or changing request parameters.
- Handle session expiration, token validation, refresh/revocation, password reset, email verification, and logout behavior deliberately.
- Protect admin and privileged actions with explicit role/permission checks and audit-friendly errors.
- Keep auth errors helpful to legitimate users without leaking whether accounts, tokens, or resources exist.

### Security Engineering

Use when changes touch user data, secrets, external input, file upload/download, webhooks, integrations, payments, inventory, permissions, dependencies, or deployment configuration.

- Treat every external input as untrusted until validated at the correct boundary.
- Protect secrets: do not hardcode, expose, log, commit, or return credentials, tokens, private keys, or sensitive config.
- Check common web risks: injection, XSS, CSRF, SSRF, insecure deserialization, path traversal, open redirects, CORS mistakes, and unsafe file handling.
- Check data exposure risks in API responses, logs, exports, errors, caches, analytics, and client-side state.
- Use proven framework security APIs for password hashing, token signing, escaping, validation, and cryptography.
- Consider abuse paths: brute force, enumeration, replay, rate limits, privilege escalation, tenant breakout, and unsafe retries.
- Prefer secure defaults and fail closed when permission, identity, or validation state is uncertain.

### Version Control And GitHub Engineering

Use when starting a repository, connecting to GitHub, planning commits, reviewing changes, or protecting backend/auth/security work with history.

- Initialize version control early and keep the repository clean enough to review.
- Commit small logical changes with messages that explain the engineering intent.
- Use branches for risky features, auth/security changes, migrations, and larger refactors.
- Keep secrets, `.env` files, generated credentials, service keys, and local database files out of Git.
- Add or update `.gitignore` before introducing dependencies, environment files, build outputs, or local runtime artifacts.
- Prefer pull-request style review thinking even on solo work: inspect diffs, check tests, and identify risk before merging.
- Tag or clearly mark stable milestones before major backend, database, auth, or security changes.

### Supabase Backend, Auth, And Security Engineering

Use when the system uses Supabase for database, authentication, storage, realtime, edge functions, or backend APIs.

- Treat Supabase as a real backend boundary, not only a client library.
- Design tables, relationships, constraints, indexes, and migrations before building UI flows that depend on them.
- Enable and design Row Level Security for user-owned, tenant-owned, role-protected, or sensitive data.
- Write policies for select, insert, update, and delete separately; test allowed and denied cases.
- Keep the anon key public only for operations protected by RLS; keep service-role keys server-only and never expose them to the browser.
- Use server-side code for privileged operations, admin actions, sensitive joins, and workflows that need service-role access.
- Align Supabase Auth identities with application profiles, roles, teams, stores, or organizations through explicit tables and constraints.
- Validate storage bucket permissions, signed URLs, file metadata, upload limits, and ownership policies.
- Keep local `.env` values, project URLs, anon keys, and service keys documented through example files without committing real secrets.

### Full-Stack Engineering

Use when the request crosses frontend, backend, database, APIs, infrastructure, or developer tooling.

- Trace the feature vertically from UI to persistence and back.
- Keep client/server contracts typed or clearly validated where the stack allows it.
- Handle loading, empty, error, success, and permission states.
- Verify that backend changes are reflected in frontend behavior and tests.
- Check migrations, seed data, environment variables, auth state, Supabase policies, and deployment implications.

### Reliability, Performance, And Observability

Use when changes touch shared paths, expensive operations, background work, integrations, system limits, production debugging, or operational behavior.

- Consider concurrency, transactions, rate limits, timeouts, retries, idempotency, and backpressure.
- Keep performance work evidence-based: measure or inspect the specific hot path.
- Make failure behavior visible with useful logs, metrics, traces, or structured errors where the codebase supports them.
- Avoid logging sensitive data while keeping enough context to debug production issues.
- Prefer simple observability improvements when they materially help future debugging.

## Implementation Rules

- Read before editing.
- Work with the existing code style, framework, naming, and test strategy.
- Keep changes scoped to the requested behavior.
- Do not overwrite unrelated user changes.
- Use structured parsers and framework APIs instead of brittle string manipulation when practical.
- Add abstractions only when they remove real duplication or clarify ownership.
- Make failure behavior deliberate instead of accidental.
- Keep authentication, authorization, and validation checks close to trusted server-side boundaries.
- Leave the system easier to understand than you found it.

## Verification Rules

Choose checks based on risk and project support.

- For narrow logic changes, run focused unit tests or the nearest equivalent.
- For auth or security changes, test allowed, denied, expired, missing, malformed, privilege-escalation, and cross-user or cross-tenant cases.
- For Supabase changes, test RLS policies for select, insert, update, delete, and service-role-only paths.
- For API or data-flow changes, test success and failure paths.
- For UI changes, verify responsive layout and key states when tooling is available.
- For build-system or dependency changes, run install/build/typecheck checks when feasible.
- If a check cannot be run, state exactly why and what residual risk remains.

## Reporting Back

End with a concise engineering handoff:

- What changed.
- Where it changed.
- What was verified.
- Any authentication, authorization, Supabase policy, GitHub/version-control, or security risk that remains.
- Any skipped check or follow-up that matters.

Keep the explanation practical. The goal is not to sound like an engineer; the goal is to make the system more correct, understandable, secure, and durable.