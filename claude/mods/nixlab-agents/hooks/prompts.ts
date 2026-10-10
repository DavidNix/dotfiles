// The engine keeps each built-in agent's system prompt and tool schemas to
// itself, so the local model gets these instead. The tools are the engine's
// own (it runs them, permission checks included); only their schemas are
// restated here, trimmed to what the local agents need.

type Tool = {
  type: 'function'
  function: { name: string; description: string; parameters: Record<string, unknown> }
}

const tool = (name: string, description: string, properties: Record<string, unknown>, required: string[]): Tool => ({
  type: 'function',
  function: { name, description, parameters: { type: 'object', properties, required } },
})

const READ = tool(
  'Read',
  'Read a file from the local filesystem. Returns its lines prefixed with line numbers. For large files, read the part you need with offset and limit.',
  {
    file_path: { type: 'string', description: 'Absolute path of the file to read' },
    offset: { type: 'number', description: 'Line number to start reading from' },
    limit: { type: 'number', description: 'Number of lines to read' },
  },
  ['file_path'],
)

const BASH = tool(
  'Bash',
  'Run a shell command (zsh on macOS) in the working directory and return its output. Search with rg (ripgrep) for content and fd or find for file names.',
  {
    command: { type: 'string', description: 'The command to run' },
    description: { type: 'string', description: 'What the command does, in 5-10 words, for the user watching' },
    timeout: { type: 'number', description: 'Timeout in milliseconds (default 120000, max 600000)' },
  },
  ['command', 'description'],
)

const EDIT = tool(
  'Edit',
  'Replace an exact string in a file. Read the file first; old_string must match exactly, including indentation, and be unique unless replace_all is set.',
  {
    file_path: { type: 'string', description: 'Absolute path of the file to modify' },
    old_string: { type: 'string', description: 'The exact text to replace' },
    new_string: { type: 'string', description: 'The replacement text' },
    replace_all: { type: 'boolean', description: 'Replace every occurrence (default false)' },
  },
  ['file_path', 'old_string', 'new_string'],
)

const WRITE = tool(
  'Write',
  'Write a file, replacing it if it exists. Prefer Edit for changes to existing files.',
  {
    file_path: { type: 'string', description: 'Absolute path of the file to write' },
    content: { type: 'string', description: 'The full file content' },
  },
  ['file_path', 'content'],
)

// Claude Code collects a subagent's report through this tool and keeps
// nudging until it is called; it says so in a reminder when it applies.
const HANDBACK = tool(
  'SubagentHandback',
  'Deliver your final report to your caller. Only this reaches the caller; plain text does not. The call ends your run, so make it your last step.',
  { message: { type: 'string', description: 'Your full final report' } },
  ['message'],
)

const EXPLORE_PROMPT = `You are a read-only code search agent working for another AI coding agent. Find what it asked for and report back.

- Search with Bash: rg for content, fd or find for file names, ls, git log/show/grep. Read files with Read using absolute paths; for large files read only the parts you need.
- Never change anything: no file writes or shell redirection into files, no git commands that change state, no installs.
- Make independent searches in parallel by calling several tools in one response.
- Your report is all the caller sees. Answer directly and concisely, cite locations as path:line, and say what you could not find.`

const GENERAL_PROMPT = `You are an agent working for another AI coding agent. Complete the task it gave you, then report back.

- Read files with Read using absolute paths. Search with Bash: rg, fd, ls, git. Change files with Edit (exact string replacement, after reading the file) or Write (new files).
- Do what was asked and nothing more. Match the style of the surrounding code.
- Make independent tool calls in parallel by calling several tools in one response.
- Your report is all the caller sees: say what you did and found and anything left undone, citing locations as path:line.`

/** general-purpose may change files; every other routed type is read-only. */
export function agentSetup(
  type: string,
  { cwd, today, hasHandback }: { cwd: string; today: string; hasHandback: boolean },
): { system: string; tools: Tool[] } {
  const isGeneral = type === 'general-purpose'
  const finish = hasHandback
    ? '\n- When you are done, call SubagentHandback with your full report as `message`. It must be your last call.'
    : '\n- When you are done, reply with your full report as your final message.'
  const environment = `\n\nWorking directory: ${cwd}\nPlatform: macOS\nToday's date: ${today}`
  return {
    system: (isGeneral ? GENERAL_PROMPT : EXPLORE_PROMPT) + finish + environment,
    tools: [...(isGeneral ? [READ, BASH, EDIT, WRITE] : [READ, BASH]), ...(hasHandback ? [HANDBACK] : [])],
  }
}
