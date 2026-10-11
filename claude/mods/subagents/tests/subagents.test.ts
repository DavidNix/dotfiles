import type { On } from 'claude-code'
import { expect, test } from 'claude-code/testing'
import type { Engine } from 'claude-code/testing'

function world(on: On) {
  const models: string[] = []
  on('agent.list', async () => ({
    value: [
      { id: 'a1', type: 'Explore', description: 'find', status: 'running' as const },
      { id: 'a2', type: 'general-purpose', description: 'do', status: 'running' as const },
      { id: 'a3', type: 'Plan', description: 'plan', status: 'running' as const },
    ],
  }))
  on('turn.step', async function* (_, e) {
    models.push(e.model)
    yield { kind: 'text' as const, index: 0, text: 'done' }
    return { turnId: e.turnId, index: e.index, answer: 'done', toolUses: [], stopReason: 'end_turn' as const, usage: null }
  })
  return models
}

async function step($: Engine, model: string, agentId?: string) {
  const stream = $.turn.step({ turnId: 't1', index: 0, model, messageCount: 1, ...(agentId && { agentId }) })
  let read = await stream.next()
  while (!read.done) {
    read = await stream.next()
  }
  return read.value
}

test('Explore steps run on Sonnet and general-purpose steps on Opus', async ($, on) => {
  const models = world(on)
  await step($, 'claude-haiku-5-5', 'a1')
  const result = await step($, 'claude-sonnet-5-5', 'a2')
  expect(models).toEqual(['claude-sonnet-5-5', 'claude-opus-5-5'])
  expect(result.answer).toBe('done')
})

test('routes come from options', { options: { routes: ' Plan = claude-haiku-5-5 , Explore=' } }, async ($, on) => {
  const models = world(on)
  await step($, 'claude-opus-5-5', 'a1')
  await step($, 'claude-opus-5-5', 'a3')
  expect(models).toEqual(['claude-opus-5-5', 'claude-haiku-5-5'])
})

test('other agent types and the main loop keep their model', async ($, on) => {
  const models = world(on)
  await step($, 'claude-opus-5-5', 'a3')
  await step($, 'claude-opus-5-5')
  expect(models).toEqual(['claude-opus-5-5', 'claude-opus-5-5'])
})
