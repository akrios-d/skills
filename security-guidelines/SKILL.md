---
name: security-guidelines
description: "Apply this skill on any security-relevant code change, in any language or stack. Triggers: handling external/user input, error handling and responses, secrets and configuration, outbound network/API calls, logging, authentication/authorization, or dependency management. Enforces universal principles: validate and sanitize input at the boundary; never expose internal details or stack traces to callers; keep secrets out of source control; set explicit timeouts on outbound calls; never log secrets or PII; apply least privilege; and scan dependencies for known vulnerabilities. For stack-specific mechanics (e.g. Spring), use the matching stack security skill alongside this one."
---

# Security Guidelines (language-agnostic)

Universal security principles that apply to any repository, language, or framework. For
stack-specific mechanisms (annotations, config files, HTTP clients, build tooling), use the
relevant stack security skill (e.g. `spring-boot-security`) on top of these.

## 1. Validate input at the boundary

- Validate and sanitize **every** external input (request params, bodies, headers,
  uploaded files, message payloads) before any logic uses it.
- Enforce type, length, range, and format. Reject by default; allow-list, don't deny-list.
- Never trust the client. Re-check on the server even if the UI already validated.

## 2. Don't leak internals in errors

- Never return stack traces, exception messages, SQL, or internal identifiers to callers.
- Log the detail internally; return a clean, generic message and an appropriate status code.
- Map upstream/dependency failures to meaningful statuses — don't blanket everything as 500.

## 3. Keep secrets out of source

- No credentials, tokens, or keys in source or committed config.
- Use environment variables or a secrets manager; reference them by name.
- Ensure `.gitignore` covers local secret files (`.env`, key files, etc.).

## 4. Set timeouts and limits on outbound calls

- Every outbound network/API/DB call needs explicit connect and read timeouts — a slow
  dependency must not exhaust threads/connections.
- Consider retries with backoff and circuit-breaking where a dependency can fail.

## 5. Logging

- **Never log** passwords, tokens, secrets, full query results, or PII (names, emails, tax
  IDs, etc.).
- Log with enough context to debug (IDs, the operation, status) at the right level.
- Don't run `DEBUG`/verbose logging in production.

## 6. Authentication & authorization

- Confirm where authn/authz is enforced; don't assume an upstream layer covers it.
- Apply least privilege to credentials, tokens, DB users, and service accounts.

## 7. Dependencies

- Scan dependencies (including transitive) for known CVEs regularly.
- Flag and address High/Critical vulnerabilities — don't silently accept them.
