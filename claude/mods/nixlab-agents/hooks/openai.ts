import type { TurnStepChunk, TurnStepInput, TurnStepResult, TurnStopReason, TurnUsage } from 'claude-code'

// The conversation as $.session.messages({ as: 'api' }) gives it.
type Block = { type: string; [field: string]: unknown }
type ApiMessage = { role: 'user' | 'assistant'; content: Block[] }

type Part = { type: 'text'; text: string } | { type: 'image_url'; image_url: { url: string } }
type ToolCall = { id: string; type: 'function'; function: { name: string; arguments: string } }
export type ChatMessage =
  | { role: 'system'; content: string }
  | { role: 'user'; content: string | Part[] }
  | { role: 'assistant'; content: string; tool_calls?: ToolCall[] }
  | { role: 'tool'; tool_call_id: string; content: string }

const str = (value: unknown): string => (typeof value === 'string' ? value : '')

export function toChatMessages(messages: readonly ApiMessage[]): ChatMessage[] {
  const out: ChatMessage[] = []
  for (const message of messages) {
    if (message.role === 'assistant') {
      const toolCalls = message.content
        .filter(b => b.type === 'tool_use')
        .map(b => ({
          id: str(b.id),
          type: 'function' as const,
          function: { name: str(b.name), arguments: JSON.stringify(b.input ?? {}) },
        }))
      out.push({ role: 'assistant', content: textOf(message.content), ...(toolCalls.length > 0 && { tool_calls: toolCalls }) })
      continue
    }

    // Tool results must directly follow the assistant turn that called them;
    // the rest of the user message (reminders, the prompt, images) comes after.
    const images: Part[] = []
    for (const b of message.content) {
      if (b.type !== 'tool_result') {
        continue
      }
      const content = typeof b.content === 'string' ? [{ type: 'text', text: b.content }] : ((b.content ?? []) as Block[])
      images.push(...imagesOf(content))
      const text = textOf(content) || '(no output)'
      out.push({ role: 'tool', tool_call_id: str(b.tool_use_id), content: b.is_error === true ? `Error: ${text}` : text })
    }
    images.push(...imagesOf(message.content))
    const text = textOf(message.content)
    if (images.length > 0) {
      out.push({ role: 'user', content: [...(text ? [{ type: 'text' as const, text }] : []), ...images] })
    } else if (text) {
      out.push({ role: 'user', content: text })
    }
  }
  return out
}

function textOf(blocks: readonly Block[]): string {
  return blocks
    .map(b => (b.type === 'text' ? str(b.text) : b.type === 'document' ? '[document omitted]' : ''))
    .filter(Boolean)
    .join('\n\n')
}

function imagesOf(blocks: readonly Block[]): Part[] {
  return blocks.flatMap(b => {
    const source = b.type === 'image' ? (b.source as { type?: string; media_type?: string; data?: string; url?: string }) : undefined
    if (source?.type === 'base64') {
      return [{ type: 'image_url' as const, image_url: { url: `data:${source.media_type};base64,${source.data}` } }]
    }
    return source?.type === 'url' && source.url ? [{ type: 'image_url' as const, image_url: { url: source.url } }] : []
  })
}

type Delta = {
  content?: string | null
  reasoning_content?: string | null
  tool_calls?: { index: number; id?: string; function?: { name?: string; arguments?: string } }[]
}
type StreamEvent = {
  choices?: { delta?: Delta; finish_reason?: string | null }[]
  usage?: { prompt_tokens?: number; completion_tokens?: number } | null
}

/**
 * Turns an OpenAI chat-completions SSE stream into turn.step chunks: text and
 * reasoning as they arrive, each tool call as a `tool` chunk then its `input`.
 */
export class StreamTranslator {
  /** True once the server sent its first event: from then on the step is the local model's. */
  hasStarted = false
  private pending = ''
  private block = -1
  private openKind: 'text' | 'thinking' | null = null
  private answer = ''
  private tools = new Map<number, { block: number; id: string; name: string; args: string }>()
  private finishReason: string | null = null
  private usage: TurnUsage | null = null

  constructor(private readonly model: string) {}

  feed(text: string): TurnStepChunk[] {
    const lines = (this.pending + text).split('\n')
    this.pending = lines.pop() ?? ''
    return lines.flatMap(line => {
      const data = line.startsWith('data:') ? line.slice(5).trim() : ''
      if (data === '' || data === '[DONE]') {
        return []
      }
      try {
        const event = JSON.parse(data) as StreamEvent
        this.hasStarted = true
        return this.onEvent(event)
      } catch {
        return []
      }
    })
  }

  /** The stop chunk and the step's result; `error` ends a stream that broke off. */
  finish(e: TurnStepInput, error?: string): { chunks: TurnStepChunk[]; result: TurnStepResult } {
    const chunks = error ? this.piece('text', `\n\n[${this.model}: ${error}]`) : []
    const toolUses = [...this.tools.values()].map(t => ({ name: t.name, input: parseArgs(t.args) }))
    const stopReason: TurnStopReason =
      toolUses.length > 0 && !error ? 'tool_use' : this.finishReason === 'length' ? 'max_tokens' : 'end_turn'
    chunks.push({ kind: 'stop', stopReason, usage: this.usage })
    return {
      chunks,
      result: { turnId: e.turnId, index: e.index, answer: this.answer, toolUses, stopReason, usage: this.usage },
    }
  }

  private onEvent(event: StreamEvent): TurnStepChunk[] {
    if (event.usage) {
      this.usage = {
        model: this.model,
        input_tokens: event.usage.prompt_tokens ?? 0,
        output_tokens: event.usage.completion_tokens ?? 0,
        cache_read_input_tokens: 0,
        cache_creation_input_tokens: 0,
      }
    }
    const choice = event.choices?.[0]
    if (!choice) {
      return []
    }
    const delta = choice.delta ?? {}
    const out: TurnStepChunk[] = []
    if (delta.reasoning_content) {
      out.push(...this.piece('thinking', delta.reasoning_content))
    }
    if (delta.content) {
      out.push(...this.piece('text', delta.content))
    }
    for (const call of delta.tool_calls ?? []) {
      let tool = this.tools.get(call.index)
      if (!tool) {
        this.block += 1
        this.openKind = null
        // Anthropic ids are [A-Za-z0-9_-]; a later step may go to Claude.
        const id = (call.id ?? `call_${this.block}`).replace(/[^A-Za-z0-9_-]/g, '_')
        tool = { block: this.block, id, name: call.function?.name ?? '', args: '' }
        this.tools.set(call.index, tool)
        out.push({ kind: 'tool', index: tool.block, id: tool.id, name: tool.name })
      }
      const args = call.function?.arguments
      if (args) {
        tool.args += args
        out.push({ kind: 'input', index: tool.block, json: args })
      }
    }
    if (choice.finish_reason) {
      this.finishReason = choice.finish_reason
    }
    return out
  }

  private piece(kind: 'text' | 'thinking', text: string): TurnStepChunk[] {
    if (this.openKind !== kind) {
      this.block += 1
      this.openKind = kind
    }
    if (kind === 'text') {
      this.answer += text
    }
    return [{ kind, index: this.block, text }]
  }
}

function parseArgs(json: string): unknown {
  try {
    return JSON.parse(json || '{}')
  } catch {
    return {}
  }
}
