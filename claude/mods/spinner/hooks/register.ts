import type { Register } from 'claude-code'

// What the turn is doing, in place of the spinner's whimsical verb
// (Metamorphosing...). Only the word changes: the engine still draws the
// elapsed time and tokens after it.
const SPINNER_WORDS = {
  requesting: 'Waiting',
  thinking: 'Thinking',
  responding: 'Writing',
  'tool-input': 'Preparing tool call',
  'tool-use': 'Running tools',
} as const

export const register: Register = on => {
  // The desktop's word already names the step (Creating notes.md).
  on('ui.render', { component: 'Spinner' }, ($, e, next) =>
    e.surface === 'terminal' ? next({ ...e, props: { ...e.props, word: SPINNER_WORDS[e.props.mode] } }) : next(e),
  )

  // The line closing each turn (Baked for 3s) keeps its time.
  on('ui.render', { component: 'TurnDuration' }, ($, e, next) => next({ ...e, props: { ...e.props, word: 'Worked' } }))
}
