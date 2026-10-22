-- Neovim 0.12+: a quiet code reader with explicit saves and lightweight editing.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Options ---------------------------------------------------------------------
vim.opt.number = true
vim.opt.mouse = 'a'
vim.opt.showmode = true
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.swapfile = false
vim.opt.autowrite = false
vim.opt.autowriteall = false
vim.opt.confirm = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = 'yes'
vim.opt.updatetime = 250
vim.opt.timeoutlen = 400
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.inccommand = 'split'
vim.opt.cursorline = true
vim.opt.scrolloff = 8
vim.opt.showmatch = true
vim.opt.virtualedit = 'onemore'
vim.opt.shiftround = true
vim.opt.winborder = 'rounded'
vim.opt.diffopt = { 'internal', 'filler', 'closeoff', 'indent-heuristic', 'inline:word', 'linematch:60' }
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

local group = vim.api.nvim_create_augroup('review-config', { clear = true })
local function map(mode, keys, action, desc)
  vim.keymap.set(mode, keys, action, { desc = desc })
end

map('n', '<Esc>', '<cmd>nohlsearch<cr>', 'Clear search highlights')
map('i', 'jk', '<Esc>', 'Exit insert mode')
map('n', ';', ':', 'Command mode')
map('n', '<leader>qq', '<cmd>qa<cr>', 'Quit all')
map('n', '<leader>w', '<C-w>v<C-w>l', 'Vertical split')
map('n', '<leader>h', '<C-w>s<C-w>j', 'Horizontal split')
map('n', '<leader>=', '<C-w>=', 'Equalize splits')
map('n', '<leader>e', '<cmd>Explore<cr>', 'Browse directory')
map('n', '<C-n>', '<cmd>Explore<cr>', 'Browse directory')
map('n', 'j', 'gj', 'Next visual line')
map('n', 'k', 'gk', 'Previous visual line')
map('x', '<', '<gv', 'Indent left')
map('x', '>', '>gv', 'Indent right')
map('t', '<Esc><Esc>', '<C-\\><C-n>', 'Exit terminal mode')
-- Ctrl+h/j/k/l belongs to Herdr. Use Ctrl+w h/j/k/l for Neovim splits.

vim.api.nvim_create_autocmd('TextYankPost', {
  group = group,
  callback = function() vim.hl.on_yank() end,
})

-- Packages --------------------------------------------------------------------
-- Parsers are installed explicitly, never in response to opening a new language.
local parsers = {
  'bash', 'css', 'diff', 'dockerfile', 'go', 'gomod', 'hcl', 'html',
  'javascript', 'json', 'lua', 'luadoc', 'markdown', 'markdown_inline',
  'python', 'query', 'rust', 'scss', 'terraform', 'toml', 'tsx', 'typescript', 'vim', 'vimdoc', 'yaml',
}

local function install_parsers(update)
  if vim.fn.executable('tree-sitter') == 0 then
    vim.notify('Install tree-sitter-cli, then run :TSInstallConfigured', vim.log.levels.WARN)
    return
  end
  local ts = require('nvim-treesitter')
  local task = update and ts.update(parsers) or ts.install(parsers)
  task:wait(300000)
end

vim.api.nvim_create_autocmd('PackChanged', {
  group = group,
  callback = function(ev)
    if ev.data.spec.name == 'nvim-treesitter' and ev.data.kind ~= 'delete' then
      vim.cmd.packadd('nvim-treesitter')
      install_parsers(ev.data.kind == 'update')
    end
  end,
})

vim.pack.add({
  { src = 'https://github.com/neovim/nvim-lspconfig' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
  { src = 'https://github.com/ibhagwan/fzf-lua' },
  { src = 'https://github.com/lewis6991/gitsigns.nvim' },
  { src = 'https://github.com/folke/which-key.nvim' },
  { src = 'https://github.com/Shatur/neovim-ayu' },
  { src = 'https://github.com/NMAC427/guess-indent.nvim' },
}, { confirm = false })

vim.api.nvim_create_user_command('TSInstallConfigured', function()
  install_parsers(false)
end, { desc = 'Install the configured syntax parsers' })

require('ayu').setup { mirage = false }
vim.cmd.colorscheme('ayu-dark')
require('guess-indent').setup {}
require('which-key').setup { delay = 300, icons = { mappings = false } }
require('which-key').add {
  { '<leader>s', group = 'Search' },
  { '<leader>g', group = 'Git' },
  { '<leader>q', group = 'Quit' },
}

-- Syntax and folding ----------------------------------------------------------
vim.api.nvim_create_autocmd('FileType', {
  group = group,
  callback = function(ev)
    if vim.bo[ev.buf].buftype ~= '' then return end
    if not vim.wo.diff then vim.wo.foldmethod = 'manual' end
    local size = vim.uv.fs_stat(vim.api.nvim_buf_get_name(ev.buf))
    if (size and size.size > 1024 * 1024) or vim.api.nvim_buf_line_count(ev.buf) > 20000 then
      vim.treesitter.stop(ev.buf)
      return
    end
    if vim.treesitter.get_parser(ev.buf) then
      vim.treesitter.start(ev.buf)
      if not vim.wo.diff then
        vim.wo.foldmethod = 'expr'
        vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
        vim.wo.foldlevel = 99
      end
    end
  end,
})

-- File and symbol navigation --------------------------------------------------
local fzf = require('fzf-lua')
fzf.setup {
  defaults = { file_icons = false, git_icons = false, color_icons = false },
  winopts = { width = 0.9, height = 0.85 },
}
fzf.register_ui_select()
map('n', '<leader><leader>', fzf.files, 'Find files')
map('n', '<leader>sf', fzf.files, 'Find files')
map('n', '<leader>sg', fzf.live_grep, 'Search project text')
map('n', '<leader>sw', fzf.grep_cword, 'Search word under cursor')
map('n', '<leader>sb', fzf.buffers, 'Find open buffers')
map('n', '<leader>s.', fzf.oldfiles, 'Recent files')
map('n', '<leader>sr', fzf.resume, 'Resume search')
map('n', '<leader>ss', fzf.builtin, 'Choose a picker')
map('n', '<leader>sh', fzf.helptags, 'Search help')
map('n', '<leader>sk', fzf.keymaps, 'Search keymaps')
map('n', '<leader>sd', fzf.diagnostics_workspace, 'Search diagnostics')
map('n', '<leader>se', vim.diagnostic.open_float, 'Show diagnostic')
map('n', '<leader>/', fzf.blines, 'Search current buffer')
map('n', '<leader>sn', function()
  fzf.files { cwd = vim.fn.stdpath('config') }
end, 'Find Neovim config files')

-- Git review ------------------------------------------------------------------
map('n', '<leader>gg', fzf.git_status, 'Changed files with diff previews')
map('n', '<leader>gh', fzf.git_hunks, 'Find Git hunks')
require('gitsigns').setup {
  signs = {
    add = { text = '+' }, change = { text = '~' }, delete = { text = '_' },
    topdelete = { text = '‾' }, changedelete = { text = '~' },
  },
  current_line_blame = false,
  on_attach = function(buf)
    local gs = require('gitsigns')
    local function gitmap(keys, action, desc)
      vim.keymap.set('n', keys, action, { buffer = buf, desc = desc })
    end
    for keys, direction in pairs({ [']c'] = 'next', ['[c'] = 'prev' }) do
      gitmap(keys, function()
        if vim.wo.diff then
          vim.cmd.normal { keys, bang = true }
        else
          gs.nav_hunk(direction)
        end
      end, direction .. ' change')
    end
    gitmap('<leader>gp', gs.preview_hunk, 'Preview hunk')
    gitmap('<leader>gi', gs.preview_hunk_inline, 'Preview hunk inline')
    gitmap('<leader>gd', gs.diffthis, 'Diff buffer against index')
    gitmap('<leader>gD', function() gs.diffthis('HEAD') end, 'Diff buffer against HEAD')
    gitmap('<leader>gb', gs.blame_line, 'Blame current line')
  end,
}

-- Language servers ------------------------------------------------------------
-- Ansible uses a distinct filetype so the generic YAML server stays out of it.
vim.filetype.add {
  extension = { tf = 'terraform', tfvars = 'terraform-vars' },
  pattern = {
    ['.*/ansible/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/playbooks?/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/tasks/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/handlers/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/group_vars/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/host_vars/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/playbook%.ya?ml'] = 'yaml.ansible',
  },
}

vim.diagnostic.config {
  virtual_text = false,
  virtual_lines = false,
  severity_sort = true,
  underline = { severity = vim.diagnostic.severity.ERROR },
  float = { border = 'rounded', source = 'if_many' },
}

vim.api.nvim_create_autocmd('LspAttach', {
  group = group,
  callback = function(ev)
    local function lspmap(keys, action, desc)
      vim.keymap.set('n', keys, action, { buffer = ev.buf, desc = desc })
    end
    lspmap('gd', fzf.lsp_definitions, 'Go to definition')
    lspmap('grd', fzf.lsp_definitions, 'Go to definition')
    lspmap('grD', vim.lsp.buf.declaration, 'Go to declaration')
    lspmap('grr', fzf.lsp_references, 'Find references')
    lspmap('gri', fzf.lsp_implementations, 'Find implementations')
    lspmap('grt', fzf.lsp_typedefs, 'Go to type definition')
    lspmap('gO', fzf.lsp_document_symbols, 'Find document symbols')
    lspmap('gW', fzf.lsp_live_workspace_symbols, 'Find workspace symbols')
    lspmap('<leader>f', function() vim.lsp.buf.format { async = true } end, 'Format buffer')
    -- K, grn, gra, Ctrl+x Ctrl+o, and structural selection use native defaults.
  end,
})

-- Use Ansible's script interpreter; Homebrew's private venv is not on PATH.
local ansible_python = 'python3'
local ansible = vim.fn.exepath('ansible')
if ansible ~= '' then
  local shebang = vim.fn.readfile(ansible, '', 1)[1] or ''
  local python = shebang:match('^#!(/%S+)')
  if python and vim.fs.basename(python):match('^python') and vim.fn.executable(python) == 1 then
    ansible_python = python
  end
end

local servers = {
  gopls = {},
  pyright = {
    before_init = function(_, config)
      local python = config.root_dir and vim.fs.joinpath(config.root_dir, '.venv', 'bin', 'python')
      if not python or vim.fn.executable(python) == 0 then
        python = vim.env.VIRTUAL_ENV and vim.fs.joinpath(vim.env.VIRTUAL_ENV, 'bin', 'python')
      end
      if python and vim.fn.executable(python) == 1 then
        config.settings.python.pythonPath = python
      end
    end,
    settings = { python = { analysis = { diagnosticMode = 'openFilesOnly' } } },
  },
  tsc = {
    settings = { ['js/ts'] = {
      referencesCodeLens = { enabled = false },
      implementationsCodeLens = { enabled = false },
    } },
  },
  lua_ls = {
    settings = { Lua = {
      runtime = { version = 'LuaJIT' },
      workspace = { library = { vim.env.VIMRUNTIME }, checkThirdParty = false },
    } },
  },
  cssls = {},
  terraformls = {
    -- The upstream configuration enables CodeLens; keep the reading view quiet.
    on_attach = function(_, buf) vim.lsp.codelens.enable(false, { bufnr = buf }) end,
  },
  ansiblels = {
    root_markers = { 'ansible.cfg', '.ansible-lint', '.git' },
    settings = { ansible = {
      python = { interpreterPath = ansible_python },
      validation = { lint = { enabled = false } },
    } },
  },
  rust_analyzer = { settings = { ['rust-analyzer'] = { checkOnSave = false } } },
  bashls = {},
  yamlls = {
    settings = { yaml = { schemas = {
      ['https://json.schemastore.org/github-workflow.json'] = '/.github/workflows/*',
      ['https://json.schemastore.org/github-action.json'] = '/action.{yml,yaml}',
      kubernetes = { 'k8s/**/*.yaml', 'k8s/**/*.yml', 'kubernetes/**/*.yaml', 'kubernetes/**/*.yml' },
    } } },
  },
  jsonls = { settings = { json = { validate = { enable = true } } } },
  taplo = {},
  html = {},
  dockerls = {},
}

for name, config in pairs(servers) do
  vim.lsp.config(name, config)
  vim.lsp.enable(name)
end
