import type { On, TurnStepChunk } from 'claude-code'
import { expect, mock, test } from 'claude-code/testing'
import type { Engine } from 'claude-code/testing'

const sse = (...events: object[]) => events.map(e => `data: ${JSON.stringify(e)}\n\n`).join('') + 'data: [DONE]\n\n'

const REPLY = sse(
  { choices: [{ delta: { role: 'assistant', content: 'Looking' } }] },
  { choices: [{ delta: { tool_calls: [{ index: 0, id: 'call_1', function: { name: 'Read', arguments: '' } }] } }] },
  { choices: [{ delta: { tool_calls: [{ index: 0, function: { arguments: '{"file_path": "/repo/a.ts"}' } }] } }] },
  { choices: [{ delta: {}, finish_reason: 'tool_calls' }] },
  { choices: [], usage: { prompt_tokens: 120, completion_tokens: 30 } },
)

function world(on: On, { isUp = true } = {}) {
  mock.clock(on)
  const calls = { claude: 0, bodies: [] as string[], toasts: [] as string[] }
  on('ui.toast', async (_, e) => {
    calls.toasts.push(e.text)
    return { value: undefined }
  })
  on('ui.log', async () => ({ value: undefined }))
  on('agent.list', async () => ({
    value: [{ id: 'a1', type: 'Explore', description: 'find', status: 'running' as const }],
  }))
  on('process.run', async () => ({
    value: { exitCode: isUp ? 0 : 7, stdout: isUp ? '200' : '000', stderr: '', isStdoutTruncated: false, isStderrTruncated: false },
  }))
  on('session.cwd', async () => ({ value: '/repo' }))
  on('session.messages', async () => ({
    value: [
      {
        role: 'user' as const,
        content: [
          { type: 'text', text: 'Where is foo defined?' },
          { type: 'text', text: '<system-reminder>Deliver your report through SubagentHandback.</system-reminder>' },
        ],
      },
      { role: 'assistant' as const, content: [{ type: 'tool_use', id: 'toolu_1', name: 'Bash', input: { command: 'rg foo' } }] },
      { role: 'user' as const, content: [{ type: 'tool_result', tool_use_id: 'toolu_1', content: 'a.ts:3: foo()' }] },
    ],
  }))
  // Split the stream mid-line, as a socket would.
  on('process.spawn', async function* (_, e) {
    calls.bodies.push(e.input ?? '')
    yield { stream: 'stdout' as const, text: REPLY.slice(0, 50) }
    yield { stream: 'stdout' as const, text: REPLY.slice(50) }
    return { value: { code: 0, signal: null } }
  })
  on('turn.step', async function* (_, e) {
    calls.claude += 1
    yield { kind: 'text' as const, index: 0, text: 'from claude' }
    return { turnId: e.turnId, index: e.index, answer: 'from claude', toolUses: [], stopReason: 'end_turn' as const, usage: null }
  })
  return calls
}

async function step($: Engine, agentId?: string) {
  const stream = $.turn.step({ turnId: 't1', index: 0, model: 'claude-haiku-5-5', messageCount: 3, ...(agentId && { agentId }) })
  const chunks: TurnStepChunk[] = []
  let read = await stream.next()
  while (!read.done) {
    chunks.push(read.value)
    read = await stream.next()
  }
  // The kit hands the result back as the generator's return value.
  return { chunks, result: read.value }
}

test('an Explore step is answered by the local model, tool call included', async ($, on) => {
  const calls = world(on)
  const { chunks, result } = await step($, 'a1')

  expect(calls.claude).toBe(0)
  const sent = JSON.parse(calls.bodies[0] ?? '{}')
  expect(sent.model).toBe('nixlab/large1')
  expect(sent.reasoning_effort).toBe('low')
  expect(sent.tools.map((t: { function: { name: string } }) => t.function.name)).toEqual(['Read', 'Bash', 'SubagentHandback'])
  expect(sent.messages[0].role).toBe('system')
  expect(sent.messages.slice(1)).toEqual([
    { role: 'user', content: 'Where is foo defined?\n\n<system-reminder>Deliver your report through SubagentHandback.</system-reminder>' },
    { role: 'assistant', content: '', tool_calls: [{ id: 'toolu_1', type: 'function', function: { name: 'Bash', arguments: '{"command":"rg foo"}' } }] },
    { role: 'tool', tool_call_id: 'toolu_1', content: 'a.ts:3: foo()' },
  ])

  expect(chunks).toEqual([
    { kind: 'text', index: 0, text: 'Looking' },
    { kind: 'tool', index: 1, id: 'call_1', name: 'Read' },
    { kind: 'input', index: 1, json: '{"file_path": "/repo/a.ts"}' },
    {
      kind: 'stop',
      stopReason: 'tool_use',
      usage: { model: 'nixlab/large1', input_tokens: 120, output_tokens: 30, cache_read_input_tokens: 0, cache_creation_input_tokens: 0 },
    },
  ])
  expect(result.answer).toBe('Looking')
  expect(result.toolUses).toEqual([{ name: 'Read', input: { file_path: '/repo/a.ts' } }])
  expect(calls.toasts).toEqual(['Explore → nixlab/large1'])
})

test('the main loop stays on Claude', async ($, on) => {
  const calls = world(on)
  const { result } = await step($)
  expect(calls.claude).toBe(1)
  expect(calls.bodies).toEqual([])
  expect(result.answer).toBe('from claude')
})

test('an unreachable endpoint leaves the agent on Claude', async ($, on) => {
  const calls = world(on, { isUp: false })
  const { result } = await step($, 'a1')
  expect(calls.claude).toBe(1)
  expect(calls.bodies).toEqual([])
  expect(result.answer).toBe('from claude')
  expect(calls.toasts).toEqual(['nixlab/large1 unreachable: Explore runs on Claude'])
})
