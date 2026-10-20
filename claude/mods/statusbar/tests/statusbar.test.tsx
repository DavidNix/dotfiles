import type { TurnStepInput } from 'claude-code'
import { expect, mock, test } from 'claude-code/testing'
import type { Engine } from 'claude-code/testing'

const BAND = {
  plugin: 'statusbar',
  component: 'AbovePrompt',
  props: {
    hasSurvey: false,
    isWorking: false,
    maxRows: 10,
    bodyColumns: 120,
    scroll: { offset: 0, bodyRows: 9 },
    view: {},
  },
} as const

test('shows model and effort; ctrl+t overrides effort for the session only', async ($, on) => {
  mock.clock(on)
  on('session.start', async (_, e) => ({ cwd: e.cwd }))
  on('session.model', async () => ({ value: 'claude-opus-5-5' }))
  on('settings.read', async () => ({
    value: { effortLevel: 'high', modelSettings: { 'claude-opus-5-5': { effortLevel: 'xhigh' } } },
  }))
  const ran: string[] = []
  on('command.run', async (_, e) => {
    ran.push(`/${e.command} ${e.args}`)
    return { text: 'ok' }
  })
  const sent: (string | number | undefined)[] = []
  on('turn.step', async function* (_, e) {
    sent.push(e.effort)
    return { turnId: e.turnId, index: e.index, answer: '', toolUses: [], stopReason: 'end_turn' as const, usage: null }
  })

  await $.session.start({ cwd: '/Users/me/src/dotfiles', surface: 'terminal', isInteractive: true })

  for (const surface of ['terminal', 'desktop'] as const) {
    const ui = await $.ui.mount({ ...BAND, surface })
    expect(await ui.find({ text: 'Opus 5.5' })).toBeDefined()
    expect(await ui.find({ text: 'xhigh' })).toBeDefined()
    await ui.unmount()
  }

  const ui = await $.ui.mount({ ...BAND, surface: 'terminal' })
  expect(await ui.find({ text: 'xhigh' })).toBeDefined()
  await ui.press({ key: 'effort' })
  expect(await ui.find({ text: 'max' })).toBeDefined()
  await step($, { effort: 'xhigh' })
  await step($, { effort: 'xhigh', agentId: 'sub1' })
  await ui.press({ key: 'effort' })
  expect(await ui.find({ text: 'low' })).toBeDefined()
  await step($, { effort: 'xhigh' })
  await step($, {})
  // Nothing went through /effort, which would save a new default.
  expect(ran).toEqual([])
  // The override reaches main-loop requests only, and never a model without effort.
  expect(sent).toEqual(['max', 'xhigh', 'low', undefined])

  // /effort's picker runs with no args and moves the session's level, which replaces the override.
  await ui.press({ key: 'effort' })
  expect(await ui.find({ text: 'medium' })).toBeDefined()
  await step($, { effort: 'medium' })
  expect(sent.at(-1)).toBe('medium')
  await step($, { effort: 'high' })
  expect(sent.at(-1)).toBe('high')
  expect(await ui.find({ text: 'high' })).toBeDefined()
  await step($, { effort: 'high' })
  expect(sent.at(-1)).toBe('high')

  // A typed /effort is an explicit choice and replaces the override.
  await $.command.run({ command: 'effort', args: 'high', origin: { kind: 'composer' }, presentation: { isFullscreen: false, columns: 120 } })
  expect(await ui.find({ text: 'high' })).toBeDefined()
  await step($, { effort: 'high' })
  expect(sent.at(-1)).toBe('high')
})

async function step($: Engine, fields: Partial<TurnStepInput>) {
  const stream = $.turn.step({ turnId: 't', index: 0, model: 'claude-opus-5-5', messageCount: 1, ...fields })
  while (!(await stream.next()).done) {}
}
