---
description: Reviews security by invoking the security-review skill exactly as written.
mode: subagent
hidden: true
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
