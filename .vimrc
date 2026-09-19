" ============================================
" 🔇 SILÊNCIO ABSOLUTO - INÍCIO OBRIGATÓRIO
" ============================================

set noerrorbells
set novisualbell
set t_vb=
set belloff=all
set backspace=indent,eol,start
set shortmess+=cI
set t_te=
"set t_kb=
"set t_kD=
set listchars=tab:»\ ,trail:·,extends:>,precedes:<,nbsp:+

" Mapeamento silencioso para Backspace
"inoremap <silent> <BS> <C-g>u<BS>
"inoremap <silent> <C-h> <C-g>u<C-h>

" ============================================
" BASE CORE
" ============================================

set number relativenumber
set tabstop=4
set shiftwidth=4
set list
" ⭐ REMOVIDO: set listchars=tab:~·,trail:·
set clipboard=unnamed
set guicursor=  " Desativa controle de cursor no terminal
set clipboard=unnamedplus

" ============================================
" FUNÇÕES E STATUS
" ============================================

function! Modified_Get()
	return &modified ? '[+]' : '[?]'
endfunction

set statusline=\ [FILENAME:\ %t]
set statusline+=\ %=
set statusline+=\ [TYPE:\ %Y]
set statusline+=\ [LINE:\ %l/%L\ :\ %c]
set statusline+=\ [%p%%]
set statusline+=\ %{Modified_Get()}\ 
set laststatus=2
set shortmess+=atI
set cmdheight=1

" ============================================
" SYNTAX E CORES
" ============================================

syntax on

let g:netrw_banner=0
let g:netrw_liststyle=3
let g:netrw_winsize=35

colorscheme default

highlight LineNr ctermfg=255
highlight SpecialKey ctermfg=235
highlight Function ctermfg=11
highlight Constant ctermfg=11
highlight Statement ctermfg=11
highlight String ctermfg=11
highlight StatusLine ctermbg=NONE ctermfg=255 cterm=NONE
highlight StatusLineNC ctermbg=NONE ctermfg=255 cterm=NONE
highlight Normal ctermbg=NONE
highlight NonText ctermfg=238 ctermbg=NONE

" ============================================
" ATALHOS
" ============================================

let mapleader = " "
nnoremap <leader>e :e .<CR>
nnoremap <leader>f :Files<CR>
nnoremap <leader>wq :q<CR>
nnoremap <leader>ww :w<CR>
nnoremap <C-a> gg<S-v>G

" Auto-fechamento
inoremap ( ()<Left>
inoremap { {}<Left>
inoremap [ []<Left>
inoremap " ""<Left>
inoremap ' ''<Left>
inoremap < <><Left>

" Janelas
nnoremap <leader>wv :vsplit<CR>
nnoremap <leader>ws :split<CR>
nnoremap <leader>wh <C-w>h
nnoremap <leader>wl <C-w>l
nnoremap <leader>wj <C-w>j
nnoremap <leader>wk <C-w>k

" Copiar e Colar
" Copiar para a área de transferência do Windows usando o atalho universal
vnoremap <C-c> "+y

" Atalhos usando o seu Leader (Espaço) para copiar e colar por fora
vnoremap <leader>y "+y
nnoremap <leader>y "+y
nnoremap <leader>p "+p
nnoremap <leader>P "+P

" ============================================
" COMPORTAMENTO
" ============================================

set smartindent
set autoindent
set incsearch
set hlsearch
set ignorecase
set smartcase
set showcmd
set mouse=a
set encoding=utf-8
set backspace=indent,eol,start

" ============================================
" CORREÇÕES PARA WINDOWS
" ============================================

set fileencodings=ucs-bom,utf-8,cp1252,latin1
set fileformats=dos,unix
set shellslash
let g:netrw_cygwin=0

" ============================================
" ⭐ SHELL - FORÇA USAR CMD (MAIS ESTÁVEL)
" ============================================

set shell=cmd.exe
set shellcmdflag=/c
set shellpipe=>
set shellredir=>
