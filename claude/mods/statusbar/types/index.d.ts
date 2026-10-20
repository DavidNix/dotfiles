export type Bar = {
  model: string
  effort: string | null
  /** ctrl+t's level for this session, sent on each main-loop request in place of the default. */
  override: 'low' | 'medium' | 'high' | 'xhigh' | 'max' | null
  /** The session's own level on the last main-loop request, before the override. */
  base: string | number | null
}

declare module 'claude-code' {
  interface PluginState {
    statusbar: { bar: Bar | null }
  }
}
