import { expect, test } from 'claude-code/testing'

test('the spinner names what the turn is doing and the closing line says Worked', async ($, on) => {
  // Stands in for the engine's own drawing: records what reached it.
  const drawn: Record<string, unknown>[] = []
  on('ui.render', async ($, e) => {
    drawn.push(e.props as Record<string, unknown>)
    const { Text } = $.ui.resolve(e)
    return <Text>{String((e.props as { word?: string }).word)}</Text>
  })

  const modes = {
    requesting: 'Waiting',
    thinking: 'Thinking',
    responding: 'Writing',
    'tool-input': 'Preparing tool call',
    'tool-use': 'Running tools',
  } as const
  for (const [mode, word] of Object.entries(modes) as [keyof typeof modes, string][]) {
    const props = { word: 'Metamorphosing', message: null, suffix: '…', mode }
    const ui = await $.ui.mount({ plugin: 'spinner', surface: 'terminal', component: 'Spinner', props })
    expect(await ui.find({ text: word })).toBeDefined()
    expect(drawn.at(-1)).toEqual({ ...props, word })
    await ui.unmount()
  }

  // The desktop's word already names the step.
  const desktop = await $.ui.mount({
    plugin: 'spinner',
    surface: 'desktop',
    component: 'Spinner',
    props: { word: 'Creating notes.md', message: null, suffix: '…', mode: 'tool-use' },
  })
  expect(await desktop.find({ text: 'Creating notes.md' })).toBeDefined()
  await desktop.unmount()

  const done = await $.ui.mount({
    plugin: 'spinner',
    surface: 'terminal',
    component: 'TurnDuration',
    props: { word: 'Baked', durationMs: 3000 },
  })
  expect(await done.find({ text: 'Worked' })).toBeDefined()
  expect(drawn.at(-1)).toEqual({ word: 'Worked', durationMs: 3000 })
})
