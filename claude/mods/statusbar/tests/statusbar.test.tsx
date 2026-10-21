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

const SAVED = '{ "effortLevel": "xhigh" }'

test('shows model and effort; ctrl+t sets effort for this session only', async ($, on) => {
  mock.clock(on)
  on('session.start', async (_, e) => ({ cwd: e.cwd }))
  on('session.model', async () => ({ value: 'claude-opus-5-5' }))
  on('settings.read', async () => ({
    value: { effortLevel: 'high', modelSettings: { 'claude-opus-5-5': { effortLevel: 'xhigh' } } },
  }))
  on('env.get', async (_, e) => ({ value: e.name === 'HOME' ? '/Users/me' : undefined }))
  let file = SAVED
  const writes: [string, string][] = []
  on('fs.read', async () => ({ value: file }))
  on('fs.write', async (_, e) => {
    writes.push([e.path, e.text])
    file = e.text
    return { value: undefined }
  })
  const ran: string[] = []
  on('command.run', async (_, e) => {
    ran.push(`/${e.command} ${e.args}`)
    // max is session-only in /effort, so only the other levels save.
    if (e.args !== 'max') {
      file = `{ "effortLevel": "${e.args}" }`
    }
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

  // ctrl+t sets the session's level through /effort, and wraps after max.
  const ui = await $.ui.mount({ ...BAND, surface: 'terminal' })
  await ui.press({ key: 'effort' })
  expect(await ui.find({ text: 'max' })).toBeDefined()
  await ui.press({ key: 'effort' })
  expect(await ui.find({ text: 'low' })).toBeDefined()
  expect(ran).toEqual(['/effort max', '/effort low'])
  // /effort's saved default is put back, so new sessions keep it.
  expect(writes).toEqual([['/Users/me/.claude/settings.json', SAVED]])

  // Requests keep the session's level, and the bar follows it, as after /effort's picker.
  await step($, { effort: 'medium' })
  expect(await ui.find({ text: 'medium' })).toBeDefined()
  await step($, { effort: 'xhigh', agentId: 'sub1' })
  expect(await ui.find({ text: 'medium' })).toBeDefined()
  expect(sent).toEqual(['medium', 'xhigh'])

  // A typed /effort shows before the next request.
  await $.command.run({ command: 'effort', args: 'high', origin: { kind: 'composer' }, presentation: { isFullscreen: false, columns: 120 } })
  expect(await ui.find({ text: 'high' })).toBeDefined()
})

async function step($: Engine, fields: Partial<TurnStepInput>) {
  const stream = $.turn.step({ turnId: 't', index: 0, model: 'claude-opus-5-5', messageCount: 1, ...fields })
  while (!(await stream.next()).done) {}
}
