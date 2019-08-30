set nocompatible "gets rid of all the crap that Vim does to be vi compatible
filetype off

" Vundle
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'gmarik/Vundle.vim'
Plugin 'fatih/vim-go'
Plugin 'scrooloose/nerdtree'
Plugin 'kien/ctrlp.vim'
Plugin 'tpope/vim-commentary'
Plugin 'mileszs/ack.vim'
Plugin 'tpope/vim-surround'
Plugin 'bling/vim-airline'
" Plugin 'YankRing.vim'
Plugin 'tpope/vim-rails'
Plugin 'vim-ruby/vim-ruby'
Plugin 'godlygeek/tabular'
Plugin 'plasticboy/vim-markdown'
Plugin 'elixir-editors/vim-elixir'
Plugin 'hashivim/vim-terraform'

call vundle#end()

syntax enable  
filetype plugin indent on

" if has('clipboard')
"     if has('unnamedplus')  " When possible use + register for copy-paste
        " set clipboard=unnamed,unnamedplus
    " else         " On mac and Windows, use * register for copy-paste
        set clipboard=unnamed
    " endif
" endif

" terminal colors
set t_Co=256

" fixes airline plugin bug
set laststatus=2

let g:go_disable_autoinstall = 0
" let g:neocomplete#enable_at_startup = 1

colorscheme jellybeans

" NERDTree Plugin Settings
" ========================
map <C-n> :NERDTreeToggle<CR>
let NERDTreeShowHidden=1
" always show nerdtree buffer when opening a file
let NERDTreeQuitOnOpen = 0
" close nerdtree buffer if it's the only one open
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif

set modelines=0 "security feature

" Allow for cursor beyond last character
set virtualedit=onemore

set autowrite " automatically :write before running commands
set history=1000
set showcmd  " show incomplete commands
" set spell

" sane searching
set ignorecase "ignore case when searching
set smartcase "ignore case if search string all lowercase
set incsearch "show search matches as you type
set hlsearch "highlight search terms
" nnoremap / /\v
" vnoremap / /\v

" TABS
" ======
" Global
set shiftwidth=4
set tabstop=4
set softtabstop=4
set smarttab 

" line wrapping
set wrap
set textwidth=79
set formatoptions=qrnl
set colorcolumn=85

" backups
" set nowritebackup
set noswapfile
" set nobackup

" misc
let mapleader=","

set number  
set hidden
set expandtab
set backspace=indent,eol,start "allow backspacing over everything in insert mode
set autoindent
set copyindent
set shiftround
set showmatch
set cursorline
set visualbell
set ttyfast

" undo settings
if has('persistent_undo')
    set undofile                " So is persistent undo ...
    set undolevels=1000         " Maximum number of changes that can be undone
    set undoreload=10000        " Maximum number lines to save for undo on a buffer reload
endif

set pastetoggle=<F2>

nnoremap ; :

"forces you to do it the vim way 
map <up> <nop>
map <down> <nop>
map <left> <nop>
map <right> <nop>
inoremap <up> <nop>
inoremap <down> <nop>
inoremap <left> <nop>
inoremap <right> <nop>
nnoremap j gj
nnoremap k gk

" Easy window navigation
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l
nnoremap <leader>w <C-w>v<C-w>l
nnoremap <leader>h <C-w>s<C-w>j
set splitright
set splitbelow

" disable the help key
inoremap <F1> <ESC>
nnoremap <F1> <ESC>
vnoremap <F1> <ESC>

" clears search buffer when you type ,/
nmap <silent> ,/ :nohlsearch<CR>

" copy the line and insert = for each character
nnoremap <leader>1 yypVr= 

" save when losing focus
au FocusLost * :wa

" ack shortcut
nnoremap <leader>a :Ack 

" get back to normal mode quickly
inoremap jk <Esc>

" remap ctlp plugin settings
let g:ctrlp_map = ''
nnoremap <leader>f :CtrlP<CR>
nnoremap <leader>b :CtrlPBuffer<CR>

" Find merge conflict markers
map <leader>fc /\v^[<\|=>]{7}( .*\|$)<CR>

" Visual shifting (does not exit Visual mode)
vnoremap < <gv
vnoremap > >gv

" Adjust viewports to the same size
map <Leader>= <C-w>=


" LANGUAGE SPECIFIC
"
" Ruby
" ======
autocmd FileType ruby,yml setlocal expandtab shiftwidth=2 tabstop=2 softtabstop=2

" Fastlane
au BufRead,BufNewFile Fastfile set filetype=ruby

" Go Language
" =============
" godef
au FileType go nmap <Leader>ds <Plug>(go-def-split)
au FileType go nmap <Leader>dv <Plug>(go-def-vertical)
au FileType go nmap <Leader>dt <Plug>(go-def-tab)

" godoc
au FileType go nmap <Leader>gd <Plug>(go-doc)
au FileType go nmap <Leader>gv <Plug>(go-doc-vertical)

" open Godoc in the browser
au FileType go nmap <Leader>gb <Plug>(go-doc-browser)

" Show a list of interfaces which is implemented by the type under your cursor 
au FileType go nmap <Leader>s <Plug>(go-implements)

" gorename
au FileType go nmap <Leader>e <Plug>(go-rename)

" Enable goimports to automatically insert import paths instead of gofmt
let g:go_fmt_command = "goimports"

" Disable markdown folding
let g:vim_markdown_folding_disabled=1

" YAML
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab

" Terraform
" https://github.com/hashivim/vim-terraform
let g:terraform_align=1
let g:terraform_fold_sections=1
let g:terraform_fmt_on_save=1


" FUNCTIONS
" ===========

" Save all annoying vim dotfiles to special directories
function! InitializeDirectories()
    let parent = $HOME
    let prefix = 'vim'
    let dir_list = {
                \ 'backup': 'backupdir',
                \ 'views': 'viewdir',
                \ 'swap': 'directory' }

    if has('persistent_undo')
        let dir_list['undo'] = 'undodir'
    endif

    " To specify a different directory in which to place the vimbackup,
    " vimviews, vimundo, and vimswap files/directories, add the following to
    " your .vimrc.before.local file:
    "   let g:spf13_consolidated_directory = <full path to desired directory>
    "   eg: let g:spf13_consolidated_directory = $HOME . '/.vim/'
    if exists('g:spf13_consolidated_directory')
        let common_dir = g:spf13_consolidated_directory . prefix
    else
        let common_dir = parent . '/.' . prefix
    endif

    for [dirname, settingname] in items(dir_list)
        let directory = common_dir . dirname . '/'
        if exists("*mkdir")
            if !isdirectory(directory)
                call mkdir(directory)
            endif
        endif
        if !isdirectory(directory)
            echo "Warning: Unable to create backup directory: " . directory
            echo "Try: mkdir -p " . directory
        else
            let directory = substitute(directory, " ", "\\\\ ", "g")
            exec "set " . settingname . "=" . directory
        endif
    endfor
endfunction
call InitializeDirectories()
