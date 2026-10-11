import type { EngineInterface, Register } from 'claude-code'

export const register: Register = (on, options) => {
  const model = String(options.model)
  const routed = new Set(String(options.agents).split(',').map(s => s.trim()).filter(Boolean))

  // Every step of a routed agent names the model, whatever the agent's
  // definition or the Agent call asked for. The engine drops effort for a
  // model that takes none.
  on('turn.step', async function* ($, e, next) {
    const type = e.agentId === undefined ? undefined : await typeOf($, e.agentId)
    if (type === undefined || !routed.has(type)) {
      return yield* next(e)
    }
    return yield* next({ ...e, model })
  })
}

// Module state starts over on a reload; all of it can be learned again.
const agentTypes = new Map<string, string>()

async function typeOf($: EngineInterface, agentId: string): Promise<string | undefined> {
  if (!agentTypes.has(agentId)) {
    for (const agent of await $.agent.list()) {
      agentTypes.set(agent.id, agent.type)
    }
  }
  return agentTypes.get(agentId)
}
