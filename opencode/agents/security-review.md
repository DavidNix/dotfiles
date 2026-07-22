---
description: Reviews security by invoking the security-review skill exactly as written.
mode: subagent
hidden: true
model: opencode-go/glm-5.2 # Fewer guardrails for thorough defensive analysis.
variant: max
permission:
  "*": deny
  read: allow
  glob: allow
  grep: allow
  bash:
    "*": deny
    git: allow
    "git *": allow
  skill:
    "*": deny
    security-review: allow
---

Load the `security-review` skill and follow its instructions exactly.
