import { atom, read, update } from 'claude-code'
import type { EngineInterface, ModelEffort, Register, ThemeKey } from 'claude-code'

import type { Bar } from '../types'

const bar = atom({ plugin: 'statusbar', key: 'bar' } as const, null)

const LEVELS: readonly ModelEffort[] = ['low', 'medium', 'high', 'xhigh', 'max']
// Any engine action works here as long as nothing in the chat binds a handler
// to it; the effort slider's own handler only exists while that dialog is open.
// claude/keybindings.json binds ctrl+t to it.
const CYCLE_ACTION = 'effortSlider:increaseEffort'

const EFFORT_COLOR: Record<string, ThemeKey> = {
  low: 'subtle',
  medium: 'success',
  high: 'suggestion',
  xhigh: 'warning',
  max: 'error',
}

// Model and effort above the prompt. Context, directory and branch are the
// status line's (bin/claude-statusline), which has no room for a button.
export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const started = await next(e)
    await refresh($, { effort: await settingsEffort($) })
    return started
  })

  // ctrl+t's level rides on each main-loop request rather than going through
  // /effort, which would save it as the default for new sessions. A model
  // that takes no effort (e.effort absent) is sent none. A session level that
  // moved since the last step was set by /effort's picker, which runs with no
  // args, and replaces ctrl+t's as a typed /effort does.
  on('turn.step', async function* ($, e, next) {
    if (e.agentId !== undefined) {
      return yield* next(e)
    }
    if (e.effort !== undefined) {
      const effort = e.effort
      await patch($, b => (b.base !== null && b.base !== effort ? { base: effort, override: null } : { base: effort }))
    }
    const override = (await read($, bar))?.override ?? null
    const step = override !== null && e.effort !== undefined ? { ...e, effort: override } : e
    const response = yield* next(step)
    await refresh($, { effort: step.effort === undefined ? null : String(step.effort) })
    return response
  })

  // /effort, /model and the rest. A typed /effort is an explicit choice, so it
  // replaces ctrl+t's.
  on('command.run', async ($, e, next) => {
    const ran = await next(e)
    const level = e.args.trim()
    if (e.command === 'effort' && (LEVELS.some(l => l === level) || level === 'auto')) {
      await patch($, () => ({ effort: level, override: null }))
    }
    await refresh($)
    return ran
  }).catch(($, e, next) => next(e))

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const b = await read($, bar)
    if (b === null || e.props.hasSurvey) {
      return next(e)
    }

    const { Box, Button, Text } = $.ui.resolve(e)
    const effort = b.override ?? b.effort

    return (
      <Box width={e.props.bodyColumns} justifyContent="flex-end">
        <Text bold>{modelName(b.model)}</Text>
        <Text dimColor>{' · '}</Text>
        <Button key="effort" plain action={CYCLE_ACTION} onPress={() => cycleEffort($)}>
          <Text color={(effort && EFFORT_COLOR[effort]) || 'subtle'}>{effort ?? 'effort'}</Text>
        </Button>
      </Box>
    )
  })
}

// Session only: the override lives in $.state, which ends with the session.
async function cycleEffort($: EngineInterface) {
  const b = await read($, bar)
  const current = b?.override ?? b?.effort
  const from = LEVELS.findIndex(l => l === current)
  const level = LEVELS[(from + 1) % LEVELS.length] ?? 'high'
  await patch($, () => ({ override: level }))
}

async function refresh($: EngineInterface, changes: Partial<Bar> = {}) {
  try {
    const model = await $.session.model()
    await update($, bar, b => ({ effort: null, override: null, base: null, ...b, model, ...changes }))
  } catch (error) {
    $.ui.log(`statusbar: refresh failed: ${String(error)}`, { to: 'debug' })
  }
}

async function patch($: EngineInterface, fn: (b: Bar) => Partial<Bar>) {
  await update($, bar, b => (b === null ? b : { ...b, ...fn(b) }))
}

async function settingsEffort($: EngineInterface): Promise<string | null> {
  const settings = (await $.settings.read()) as {
    effortLevel?: string
    modelSettings?: Record<string, { effortLevel?: string }>
  }
  const model = await $.session.model()
  return settings.modelSettings?.[model]?.effortLevel ?? settings.effortLevel ?? null
}

// claude-opus-5-5 → Opus 5.5, claude-sonnet-5-5[1m] → Sonnet 5.5 (1M)
function modelName(id: string): string {
  const m = /^claude-([a-z]+)-(\d+)(?:-(\d{1,2}))?(?:-\d{8})?(\[1m\])?$/.exec(id)
  if (!m) {
    return id
  }
  const [, family = '', major, minor, oneM] = m
  const version = minor ? `${major}.${minor}` : major
  return `${family[0]?.toUpperCase()}${family.slice(1)} ${version}${oneM ? ' (1M)' : ''}`
}
