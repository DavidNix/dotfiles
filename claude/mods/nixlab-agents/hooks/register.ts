import type { EngineInterface, Register } from 'claude-code'

import { StreamTranslator, toChatMessages } from './openai'
import { agentSetup } from './prompts'

const HEALTH_TTL_MS = 60_000
const MAX_TOKENS = 32_000

export const register: Register = (on, options) => {
  const baseUrl = String(options.baseUrl).replace(/\/+$/, '')
  const model = String(options.model)
  const effort = String(options.effort)
  const routed = new Set(String(options.agents).split(',').map(s => s.trim()).filter(Boolean))

  on('turn.step', async function* ($, e, next) {
    const type = e.agentId === undefined ? undefined : await typeOf($, e.agentId)
    if (e.agentId === undefined || type === undefined || !routed.has(type)) {
      return yield* next(e)
    }
    if (!(await isUp($, baseUrl))) {
      announce($, e.agentId, `${model} unreachable: ${type} runs on Claude`)
      return yield* next(e)
    }
    const messages = await $.session.messages({ as: 'api', agentId: e.agentId })
    if (!Array.isArray(messages)) {
      return yield* next(e)
    }
    announce($, e.agentId, `${type} → ${model}`)

    const today = new Date(await $.clock.now()).toISOString().slice(0, 10)
    const hasHandback = JSON.stringify(messages).includes('SubagentHandback')
    const { system, tools } = agentSetup(type, { cwd: await $.session.cwd(), today, hasHandback })
    const body = JSON.stringify({
      model,
      stream: true,
      stream_options: { include_usage: true },
      max_tokens: MAX_TOKENS,
      reasoning_effort: effort,
      messages: [{ role: 'system', content: system }, ...toChatMessages(messages)],
      tools,
    })

    // curl rather than $.http.fetch: it streams, and an interrupt ends this
    // loop, which kills the request with it.
    const stream = $.process.spawn({
      argv: [
        'curl', '-sS', '-N', '--fail-with-body', '--connect-timeout', '5',
        '-H', 'content-type: application/json', '-H', 'authorization: Bearer local',
        '--data-binary', '@-', `${baseUrl}/chat/completions`,
      ],
      input: body,
    })
    const translator = new StreamTranslator(model)
    let output = ''
    let failure: string | undefined
    try {
      for await (const piece of stream) {
        if (piece.stream === 'stderr' || !translator.hasStarted) {
          output = (output + piece.text).slice(-2000)
        }
        if (piece.stream === 'stdout') {
          yield* translator.feed(piece.text)
        }
      }
      const exit = await stream.result
      if (exit && exit.code !== 0) {
        failure = `curl exited ${exit.code ?? exit.signal}: ${output.trim()}`
      }
    } catch (error) {
      failure = String(error)
    }

    // Nothing reached the transcript yet (refused, over its context, down):
    // this step goes to Claude instead.
    if (!translator.hasStarted) {
      $.ui.log(`nixlab-agents: ${type} step fell back to Claude: ${failure ?? output.trim()}`, { to: 'debug' })
      $.ui.toast(`${model} failed; this ${type} step runs on Claude`)
      return yield* next(e)
    }
    const { chunks, result } = translator.finish(e, failure && 'stream ended early')
    if (failure) {
      $.ui.log(`nixlab-agents: ${type} stream broke off: ${failure}`, { to: 'debug' })
    }
    yield* chunks
    return result
  })
}

// Module state starts over on a reload; all of it can be learned again.
const agentTypes = new Map<string, string>()
const announced = new Set<string>()
let health: { isUp: boolean; checkedAt: number } | undefined

async function typeOf($: EngineInterface, agentId: string): Promise<string | undefined> {
  if (!agentTypes.has(agentId)) {
    for (const agent of await $.agent.list()) {
      agentTypes.set(agent.id, agent.type)
    }
  }
  return agentTypes.get(agentId)
}

// Work machines have no nixlab: a quick probe, remembered for a minute, so
// those agents simply stay on Claude.
async function isUp($: EngineInterface, baseUrl: string): Promise<boolean> {
  const now = await $.clock.now()
  if (health && now - health.checkedAt < HEALTH_TTL_MS) {
    return health.isUp
  }
  const probe = await $.process
    .run(['curl', '-sS', '-m', '3', '-o', '/dev/null', '-w', '%{http_code}', `${baseUrl}/models`])
    .catch(() => undefined)
  health = { isUp: probe?.exitCode === 0 && probe.stdout.trim() === '200', checkedAt: now }
  return health.isUp
}

function announce($: EngineInterface, agentId: string, text: string) {
  if (!announced.has(agentId)) {
    announced.add(agentId)
    $.ui.toast(text)
  }
}
