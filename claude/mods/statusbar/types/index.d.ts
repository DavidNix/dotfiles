export type Bar = {
  model: string
  effort: string | null
}

declare module 'claude-code' {
  interface PluginState {
    statusbar: { bar: Bar | null }
  }
}
