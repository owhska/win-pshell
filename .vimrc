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
set listchars=tab:»\ ,trail:·,extends:>,precedes:<,nbsp:+

" ============================================
" PLATAFORMA (Windows / Linux)
" ============================================

let g:is_windows = has('win32') || has('win64')
let g:is_linux   = has('unix') && !has('mac')

" ============================================
" BASE CORE
" ============================================

set number relativenumber
set tabstop=4
set shiftwidth=4
set list
set guicursor=

" Clipboard: unnamedplus só funciona se houver suporte
if has('clipboard')
    if g:is_windows
        set clipboard=unnamed,unnamedplus
    else
        " No Linux, unnamedplus depende de X11/Wayland; testa antes
        if has('unnamedplus')
            set clipboard=unnamedplus
        else
            set clipboard=unnamed
        endif
    endif
endif

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
let g:netrw_browse_split=0
if g:is_windows
    let g:netrw_cygwin=0
endif

colorscheme pablo

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
" FILEtype plugin (precisa vir antes de netrw/Lexplore)
" ============================================

filetype plugin on

" ============================================
" AUTOCOMPLETE OMNI AUTOMÁTICO
" ============================================

set completeopt=menuone,noinsert,noselect

function! DispararOmniAutomatico()
    if pumvisible() || v:char !~ '\w'
        return
    endif
    if &omnifunc !=# ''
        call feedkeys("\<C-x>\<C-o>", 'n')
    else
        call feedkeys("\<C-x>\<C-n>", 'n')
    endif
endfunction

augroup OmniAuto
    autocmd!
    autocmd FileType javascript,python,c,cpp,html,css,vim
                \ autocmd InsertCharPre <buffer> call DispararOmniAutomatico()
augroup END

" ============================================
" REPO CACHE / TABLINE
" ============================================

let s:repo_cache = {}

" Executa git de forma compatível com Windows e Linux
function! s:GitRoot(cwd) abort
    let l:cmd = 'git -C ' . shellescape(a:cwd) . ' rev-parse --show-toplevel'
    if g:is_windows
        " No cmd.exe, redireciona stderr com 2>NUL
        let l:cmd .= ' 2>NUL'
    else
        let l:cmd .= ' 2>/dev/null'
    endif
    try
        return systemlist(l:cmd)
    catch
        return []
    endtry
endfunction

function! s:GetRepoInfo(cwd) abort
    if has_key(s:repo_cache, a:cwd)
        return s:repo_cache[a:cwd]
    endif

    let l:root = s:GitRoot(a:cwd)

    if v:shell_error == 0 && !empty(l:root)
        let l:name = fnamemodify(l:root[0], ':t')
        let l:info = [l:name, l:root[0]]
    else
        let l:info = [fnamemodify(a:cwd, ':t'), a:cwd]
    endif

    let s:repo_cache[a:cwd] = l:info
    return l:info
endfunction

function! s:UpdateRepoCache() abort
    let l:cwd = getcwd()
    if !has_key(s:repo_cache, l:cwd)
        call s:GetRepoInfo(l:cwd)
    endif
endfunction

augroup TablineRepoCache
    autocmd!
    autocmd VimEnter,DirChanged,BufEnter * call s:UpdateRepoCache()
augroup END

function! s:IsDiffviewTab(tabnr) abort
    for bufnr in tabpagebuflist(a:tabnr)
        if getbufvar(bufnr, '&filetype') =~# '^Diffview'
            return 1
        endif
    endfor
    return 0
endfunction

function! NvimTabLine() abort
    let l:s = ''

    for i in range(1, tabpagenr('$'))
        let l:winnr   = tabpagewinnr(i)
        let l:buflist = tabpagebuflist(i)
        let l:bufnr   = l:buflist[l:winnr - 1]
        let l:cwd     = getcwd(-1, i)
        let l:info    = s:GetRepoInfo(l:cwd)
        let l:repo    = l:info[0]
        let l:root    = l:info[1]

        if s:IsDiffviewTab(i)
            let l:label = 'Diff: ' . l:repo
        else
            let l:fname = bufname(l:bufnr)
            if l:fname != ''
                let l:abs = fnamemodify(l:fname, ':p')
                if stridx(l:abs, l:root . '/') == 0
                    let l:rel = strpart(l:abs, strlen(l:root) + 1)
                else
                    let l:rel = fnamemodify(l:abs, ':t')
                endif
                let l:label = l:repo . ' - ' . l:rel
            else
                let l:label = l:repo . ' - [No Name]'
            endif
        endif

        if i == tabpagenr()
            let l:s .= '%#TabLineSel#'
        else
            let l:s .= '%#TabLine#'
        endif

        let l:s .= '%' . i . 'T' . ' ' . l:label . ' '
    endfor

    let l:s .= '%#TabLineFill#'
    return l:s
endfunction

set tabline=%!NvimTabLine()

" ============================================
" ATALHOS
" ============================================

let mapleader = " "

nnoremap <leader>e :let g:netrw_chgwin = -1 \| let g:netrw_browse_split = 0 \| Ex<CR>
nnoremap <leader>b :Lexplore<CR>
nnoremap <leader>f :e<Space>
nnoremap <leader>wq :q<CR>
nnoremap <leader>ww :w<CR>
nnoremap <leader>q :tabclose<CR>
nnoremap <C-a> gg<S-v>G
nnoremap <leader>s :execute "vimgrep /" . input("Search: ") . "/g %" \| copen<CR>

set path+=**
set wildignore+=*/node_modules/*,*/.git/*,*/dist/*,*/build/*,*.exe,*.dll

nnoremap <leader>gf :call SearchFiles()<CR>

function! SearchFiles()
    let l:pattern = input("Search files: ")
    if empty(l:pattern)
        echo "Search failed"
        return
    endif
    try
        execute "vimgrep! /\\%^/ **/*" . l:pattern . "*"
        copen
    catch /^Vim:Interrupt$/
        echo "Search interrupted"
        cclose
    endtry
endfunction

function! s:ToggleComment() abort
    let l:cs = &commentstring
    let l:prefix = matchstr(l:cs, '^.\{-}\ze\s*%s')

    if empty(l:prefix)
        echohl WarningMsg | echom "Invalid commentstring: " . l:cs | echohl None
        return
    endif

    let l:start_line = line("'<")
    let l:end_line   = line("'>")
    if l:start_line > l:end_line
        let [l:start_line, l:end_line] = [l:end_line, l:start_line]
    endif

    let l:all_commented = 1
    let l:prefix_esc = escape(l:prefix, '\.*$^~[]')
    for i in range(l:start_line, l:end_line)
        let l = getline(i)
        if l !~# '^\s*' . l:prefix_esc
            let l:all_commented = 0
            break
        endif
    endfor

    for i in range(l:start_line, l:end_line)
        let l = getline(i)
        if l:all_commented
            let l:new = substitute(l, '^\s*\zs' . l:prefix_esc . '\s\?', '', '')
        else
            let l:indent = matchstr(l, '^\s*')
            let l:rest   = l[len(l:indent):]
            let l:new    = l:indent . l:prefix . ' ' . l:rest
        endif
        call setline(i, l:new)
    endfor

    execute "normal! \<Esc>"
endfunction

vnoremap <leader>m :<C-u>call <SID>ToggleComment()<CR>

nnoremap <C-e> :b <C-d>

nnoremap <leader>gg :execute "vimgrep /" . input("Search ALL: ") . "/g **/*" \| copen<CR>

" Shift+setas: funciona em terminais que enviam essas sequências
nnoremap <S-Right> :bnext<CR>
nnoremap <S-Left>  :bprevious<CR>

set splitright

nnoremap <leader>t :vertical terminal<CR>

tnoremap <C-w>h <C-\><C-n><C-w>h
tnoremap <C-w>l <C-\><C-n><C-w>l

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

" Shift+H / Shift+L
nnoremap <S-h> ^
onoremap <S-h> ^
xnoremap <S-h> ^
nnoremap <S-l> g_
onoremap <S-l> g_
xnoremap <S-l> g_

nnoremap <silent> <leader><Tab>   :tabnext<CR>
nnoremap <silent> <leader><S-Tab> :tabprevious<CR>

" <C-p>: abre netrw em nova aba e fecha o tree ao escolher arquivo
nnoremap <silent> <C-p> :call <SID>AbrirExplorerNovaAba()<CR>

function! s:AbrirExplorerNovaAba() abort
    tabedit
    let w:ctrlp_explorer = 1
    Explore
endfunction

augroup CtrlPExplorerClose
    autocmd!
    autocmd BufWinEnter * if get(w:, 'ctrlp_explorer', 0) && &filetype !=# 'netrw'
                \ | let w:ctrlp_explorer = 0
                \ | if winnr('$') > 1 | only | endif
                \ | endif
augroup END

nnoremap <leader>gs :vertical terminal git status<CR>
nnoremap <leader>gl :vertical terminal git log --oneline<CR>
nnoremap <leader>gd :tab terminal git diff<CR>

tnoremap <leader><Tab> <C-\><C-n><leader><Tab>
tnoremap <S-Right> <C-\><C-n>:bnext<CR>
tnoremap <S-Left>  <C-\><C-n>:bprevious<CR>
tnoremap <C-PageDown> <C-\><C-n>:tabnext<CR>
tnoremap <C-PageUp>   <C-\><C-n>:tabprevious<CR>

nnoremap <leader>cf :let @+ = expand("%")<CR>

nnoremap <C-u> <C-u>zz
nnoremap <C-d> <C-d>zz

nnoremap n nzzzv
nnoremap N Nzzzv

vnoremap < <gv
vnoremap > >gv

nnoremap <leader>lw :set wrap!<CR>

vnoremap <silent> K :m '<-2<CR>gv=gv
vnoremap <silent> J :m '>+1<CR>gv=gv

nnoremap x "_x

nnoremap <leader>rr :%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>

nnoremap <leader>dd "_d
vnoremap <leader>dd "_d

xnoremap p "_dP

nnoremap <leader><left>  :vertical resize +20<CR>
nnoremap <leader><right> :vertical resize -20<CR>
nnoremap <leader><up>    :resize +10<CR>
nnoremap <leader><down>  :resize -10<CR>

" Copiar e Colar
vnoremap <C-c> "+y
vnoremap <leader>y "+y
nnoremap <leader>y "+y
nnoremap <leader>p "+p
nnoremap <leader>P "+P

" AutoComplete - Tab
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

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
" CORREÇÕES PARA WINDOWS / LINUX
" ============================================

set fileencodings=ucs-bom,utf-8,cp1252,latin1

if g:is_windows
    set fileformats=dos,unix
    set shellslash
    " cmd.exe é o padrão mais estável no Windows puro
    set shell=pwsh.exe
    set shellcmdflag=/c
    set shellpipe=>
    set shellredir=>
else
    set fileformats=unix,dos
    " No Linux, usa o shell do ambiente (bash/zsh)
    set shell=/bin/bash
    set shellcmdflag=-c
    set shellpipe=2>&1\ \|\ tee
    set shellredir=>
endif
