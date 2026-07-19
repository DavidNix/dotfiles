---
name: security-review
description: Defensive security review and hardening of application code, configuration, dependencies, and tests using current OWASP guidance. Use only when the user explicitly asks for a security review, security audit, vulnerability review, or security hardening. Do not use for general code review.
---

## Security Review Instructions

Review the specified code exclusively for security vulnerabilities and meaningful hardening opportunities. Do not report ordinary correctness, style, maintainability, or performance concerns unless they create a plausible security impact.

Perform the entire review yourself. Do not delegate to subagents or use the Task tool for discovery, analysis, verification, or any other part of the review. Keep the work defensive: inspect authorized local code and configuration, do not probe live systems, and do not provide destructive exploitation steps.

### What to Review

If `$ARGUMENTS` specifies files, paths, commits, or a target branch, review that scope. Otherwise, review uncommitted changes in the current repository. If there are no uncommitted changes, review the branch compared with its upstream main or master branch.

For a diff-based review, inspect surrounding call paths and existing controls when needed to determine whether a changed line is exploitable. Do not turn a scoped review into an unrequested whole-repository audit.

### Review Standard

Use these as the baseline:

- OWASP Top 10:2025 for application-security risk coverage
- OWASP ASVS 5.0.0 for concrete control expectations
- OWASP Secure Code Review and Cheat Sheet Series for review methods and defensive patterns
- Technology-specific OWASP guidance, such as the API Security Top 10, only when applicable

Do not claim ASVS compliance from a code review. Cite an ASVS requirement only when its exact versioned identifier is known; never invent an identifier.

### Review Method

1. Identify relevant assets, entry points, trust boundaries, identities, and sensitive operations.
2. Identify attacker-controlled sources, including requests, headers, cookies, files, messages, external APIs, stored user content, and environment-dependent data.
3. Trace that data through validation and transformation to sensitive sinks such as database queries, shells, templates, DOM APIs, file paths, URL fetches, deserializers, logs, and response headers.
4. Verify authentication, authorization, isolation, integrity, and failure behavior at each affected boundary.
5. Check whether existing tests exercise the security control and its bypass cases.
6. Report a vulnerability only when repository evidence supports a credible attack path. Label defense-in-depth improvements as hardening, not as proven vulnerabilities.

### OWASP Top 10:2025 Coverage

**A01 - Broken Access Control**
- Missing server-side authorization, IDOR/BOLA, horizontal or vertical privilege escalation
- Cross-tenant access, unsafe role changes, insecure direct access to administrative functions
- Controls applied only in the UI, inconsistent policy enforcement, or fail-open decisions

**A02 - Security Misconfiguration**
- Unsafe defaults, debug behavior, verbose errors, permissive CORS, missing relevant browser protections
- Exposed management surfaces, insecure TLS assumptions, unnecessary features or privileges
- Hardcoded secrets or sensitive values committed to configuration

**A03 - Software Supply Chain Failures**
- Unpinned or untrusted dependencies, missing lockfile integrity, risky install scripts
- Untrusted CI actions, excessive CI credentials, unsafe artifact provenance or update paths
- Known-vulnerable dependencies only when supported by current evidence; do not infer vulnerability from age alone

**A04 - Cryptographic Failures**
- Weak or home-grown cryptography, insecure password storage, predictable tokens or random values
- Incorrect nonce, IV, signature, certificate, or key handling
- Sensitive data exposed in transit, at rest, in logs, caches, URLs, or error messages

**A05 - Injection**
- SQL, NoSQL, ORM, OS command, argument, LDAP, XPath, template, expression-language, CRLF, and code injection
- Cross-site scripting through unsafe rendering, DOM sinks, template escape hatches, or unsafe URLs
- Untrusted data reaching an interpreter without parameterization, contextual encoding, sanitization, or strict allow-listing

**A06 - Insecure Design**
- Missing abuse controls, rate or resource limits, replay protection, tenant boundaries, or secure defaults
- Security-sensitive workflow bypasses, race conditions, and state transitions an attacker can manipulate
- Trust placed in clients, internal services, or stored data without an appropriate boundary control

**A07 - Authentication Failures**
- Weak login, account recovery, MFA, credential change, or re-authentication flows
- Session fixation, weak token generation, missing rotation or invalidation, unsafe cookie attributes
- Brute-force, credential-stuffing, enumeration, JWT, OAuth, or SSO implementation weaknesses

**A08 - Software or Data Integrity Failures**
- Unsafe deserialization, unverified webhooks, artifacts, updates, redirects, or imported data
- Missing signatures, replay controls, or integrity checks at security-sensitive boundaries
- Mass assignment or unsafe binding that lets callers alter protected fields

**A09 - Security Logging and Alerting Failures**
- Missing audit events for authentication, authorization, privilege, and sensitive-data operations
- Secrets or personal data in logs, log injection, mutable audit trails, or unusable event context
- Important security failures swallowed without a reliable detection path

**A10 - Mishandling of Exceptional Conditions**
- Fail-open authorization or validation, unsafe fallback behavior, partial security-sensitive transactions
- Resource exhaustion, unbounded allocation or recursion, and attacker-triggered crash loops
- Cleanup, rollback, or error paths that expose data or leave privileges and state inconsistent

### Required Injection Checks

**SQL and query injection**
- Prefer prepared statements and parameterized queries that keep code separate from data.
- Trace concatenated or interpolated values in raw SQL, ORM query languages, stored procedures, and dynamic filters.
- Require strict allow-list mapping for dynamic identifiers such as table names, column names, and sort directions that cannot be parameterized.
- Do not accept escaping user input as the primary defense. Check database least privilege to limit impact.

**Cross-site scripting**
- Trace all untrusted and stored data to HTML, attribute, URL, CSS, and JavaScript contexts.
- Prefer framework auto-escaping and safe sinks such as `textContent`; flag unsafe escape hatches such as raw HTML rendering when data is not safely sanitized.
- Require encoding appropriate to the output context. When rich HTML is intentionally supported, require a maintained HTML sanitizer and ensure later processing does not invalidate sanitization.
- Treat Content Security Policy and Trusted Types as defense in depth. Do not present CSP, a WAF, or global request filtering as a substitute for safe rendering.

### Additional Checks When Applicable

- CSRF, SSRF, path traversal, unsafe file upload, XXE, open redirect, and request smuggling
- Cache poisoning or sensitive response caching, prototype pollution, and unsafe object merging
- API property- and function-level authorization, GraphQL limits, WebSocket authorization
- Memory unsafety, integer overflow, TOCTOU, unsafe foreign-function boundaries
- Prompt injection, excessive tool permissions, and data exfiltration paths in AI-enabled features

### Finding Quality

Each finding must:

- Point to the narrowest useful `file:line` location
- Identify the attacker-controlled source, missing or bypassed control, and sensitive sink or operation
- State required preconditions and realistic confidentiality, integrity, or availability impact
- Distinguish observed evidence from assumptions
- Assign severity from exploitability and impact, not merely from its OWASP category
- Include one most appropriate remediation and a concrete verification approach

Do not report speculative checklist items. If configuration or runtime behavior is unknown and materially affects exploitability, ask a question or lower confidence rather than presenting the issue as certain.

### Output Format

Omit empty severity sections. Order findings by severity, then confidence.

```markdown
# Security Review Findings

## Critical - MUST FIX

### SEC-C1: [Short vulnerability title]
**File**: `path/to/file.ts:123`
**Type**: Vulnerability
**Category**: OWASP A05:2025 / CWE-89
**Confidence**: High
**Evidence**: The attacker-controlled data flow and missing or bypassed control.
**Attack path**: Preconditions and the shortest credible path to exploitation.
**Impact**: Concrete confidentiality, integrity, or availability impact.
**Recommended solution**: The single most appropriate concrete fix.
**Verification**: A focused regression test or safe validation procedure.

---

## High - Should Fix

### SEC-H1: [Title]
...

## Medium - Fix When Practical

### SEC-M1: [Title]
...

## Low - Hardening

### SEC-L1: [Title]
**Type**: Hardening
...

## Questions

### SEC-Q1: [Question]
Explain which security conclusion depends on the answer.
```

Use `SEC-C`, `SEC-H`, `SEC-M`, `SEC-L`, and `SEC-Q` identifiers. Include only one **Recommended solution** for every finding; do not list alternatives. Examples are optional and should appear only when needed to make a complex fix unambiguous.

If no findings are discovered, state that explicitly and list only material residual risks or testing gaps, such as unavailable runtime configuration, dependency advisory data, or dynamic testing.
