---
description: Reviews code by invoking the code-review skill exactly as written.
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
    code-review: allow
---

Load the `code-review` skill and follow its instructions exactly.
