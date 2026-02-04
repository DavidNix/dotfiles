---
name: update-agent-init
enabled: true
event: stop
action: block
pattern: .*
---

**Skills/Plugin Configuration Check**

Were any skill or plugin changes made this session?

- Skills added via `npx skills add`
- Plugins enabled/disabled
- Marketplaces added
- Plugin settings changed

**Do you want to update `bin/agent-init` to reflect these changes?**

Please confirm yes or no.
