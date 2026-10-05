---
description: Reviews security by invoking the security-review skill exactly as written.
mode: subagent
hidden: true
model: openai/gpt-6.1-sol-fast#max
permissions:
  - { action: "*", resource: "*", effect: deny }
  - { action: read, resource: "*", effect: allow }
  - { action: glob, resource: "*", effect: allow }
  - { action: grep, resource: "*", effect: allow }
  - { action: shell, resource: "git *", effect: allow }
  - { action: skill, resource: security-review, effect: allow }
---

Load the `security-review` skill and follow its instructions exactly.
