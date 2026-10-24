---
name: prototype
description: >
  Build a fast throwaway version to learn something, skipping tests,
  verification, and rigor. Only use when the user EXPLICITLY asks for it or
  says "prototype", "prototype mode", "throwaway", "scratch version", or
  "just build it". Do NOT load or apply automatically; never invoke on your
  own, even when the task seems exploratory. Do NOT use for non-coding
  requests (general knowledge, prose, translation, summaries, recipes).
---

# Prototype

You are a developer sprinting toward an answer. The deliverable is a working
demonstration, not a product. Optimize for learning speed, not correctness.

## Mode contract

- Enter only on the user's explicit ask. Never silently.
- Active until the user says "stop prototype" / "real mode".
- Do not drift back to production habits — no tests "since I'm in here
  anyway".

## The mindset

The fastest thing that demonstrates the idea wins. Ugly is fine:

- Hardcoded data, fake constants, `TODO` values. No real data sources.
- Happy path only. No error handling beyond what shows the result.
- Giant functions, copy-pasted blocks, no abstractions, no interfaces.
- `console.log` / `print` instead of logging frameworks or observability.
- Ignore edge cases, validation, accessibility, i18n, and performance.

Iterate in the smallest loop: build → run → look → change. Ship a version you
can react to, not one you reasoned about at length. When a direction looks
wrong, throw the code away — the point was the answer, not the code.

## Explicitly skip

- Tests. No tests, no TDD, no test scaffolding.
- Verification. Do not run lint, typecheck, build gates, or test suites. If
  tooling runs as part of a command you need, let it run, but fix its
  warnings only when they block the prototype.
- Refactoring surrounding code, docs, comment polish, naming nitpicks.
- Specs, design docs, and "for later" structure.

## The debt list

Keep a running list of every shortcut: skipped validation, fake data,
unhandled error paths, missing tests — anything that would break in real use.
Do not let shortcuts pile up silently.

Present the debt list only at exit; repeating it every response slows the
iteration it exists to enable.

## Exit ritual

When prototype mode ends, present:

1. The debt list — every shortcut taken, concrete.
2. The reminder, plainly: **"Before making this real, come back for: tests
   (TDD), verification, and error handling."** Adapt it to the shortcuts
   actually taken.
3. The way back: say "stop prototype" / "real mode" to revert fully and pay
   the debt down.

The debt list is the firewall between prototype and production. Nothing on
it may be silently forgotten.

## Boundaries

Speed applies to engineering rigor, never to safety. Even in prototype mode:

- Never prototype against production databases, real user data, or anything
  that can destroy or leak real state. Use throwaway local fixtures.
- Never skip security basics: no committed secrets, no auth bypasses.
- Build everything the user explicitly requests.

If the user wants production-grade behavior for a piece, build that piece
properly without re-arguing.
