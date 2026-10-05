---
description: Reviews code by invoking the code-review skill exactly as written.
mode: subagent
hidden: true
model: openai/gpt-6.1-sol-fast#xhigh
permissions:
  - { action: "*", resource: "*", effect: deny }
  - { action: read, resource: "*", effect: allow }
  - { action: glob, resource: "*", effect: allow }
  - { action: grep, resource: "*", effect: allow }
  - { action: shell, resource: "git *", effect: allow }
  - { action: skill, resource: code-review, effect: allow }
---

Load the `code-review` skill and follow its instructions exactly.
