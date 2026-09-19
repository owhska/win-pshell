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
"set clipboard=unnamed
set guicursor=  " Desativa controle de cursor no terminal
"set clipboard=unnamedplus
set clipboard=unnamed,unnamedplus

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
" AUTOCOMPLETE OMNI AUTOMÁTICO (CORRIGIDO)
" ============================================

set completeopt=menuone,noinsert,noselect

function! DispararOmniAutomatico()
    " Só dispara se o menu não estiver visível e se o caractere digitado for uma letra/número
    if !pumvisible() && v:char =~ '\w'
        " Aguarda o caractere cair na tela antes de injetar o comando <C-x><C-o>
        call feedkeys("\<C-x>\<C-o>", 'n')
    endif
endfunction

" Ativa o gatilho automático apenas para arquivos de programação suportados
autocmd FileType javascript,python,c,cpp,html,css,vim autocmd InsertCharPre <buffer> call DispararOmniAutomatico()

" ============================================
" ATALHOS
" ============================================

let mapleader = " "
"nnoremap <leader>e :e .<CR>
nnoremap <leader>e :Lexplore<CR>
"nnoremap <leader>f :e<Space>
nnoremap <leader>wq :q<CR>
nnoremap <leader>ww :w<CR>
nnoremap <leader>q :tabclose<CR>
nnoremap <C-a> gg<S-v>G
nnoremap <leader>s :execute "vimgrep /" . input("Search: ") . "/g %" \| copen<CR>

set path+=**
set wildignore+=*/node_modules/*,*/.git/*,*/dist/*,*/build/*,*.exe,*.dll

" Espaço + f busca arquivos por nome em todo o projeto com preview em lista embaixo
nnoremap <leader>f :execute "vimgrep! /\\%^/ **/*" . input("Search files: ") . "*" \| copen<CR>

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

" Altere sua linha do <leader>b para esta:
"nnoremap <leader>b :b <C-d>
""nnoremap <leader>b :ls<CR>:b<space> "versao que seleciona pelo numero

nnoremap <C-e> :b <C-d>

" Espaço + g busca uma palavra em todos os arquivos do diretório atual e subpastas
nnoremap <leader>g :execute "vimgrep /" . input("Search ALL: ") . "/g **/*" \| copen<CR>

" Versão alternativa ultra-rápida (usa o motor de busca do sistema)
"nnoremap <leader>g :execute "grep! " . shellescape(input("Buscar no projeto: ")) \| copen<CR>

" Navegar entre buffers com Shift + Seta para Esquerda/Direita
nnoremap <S-Right> :bnext<CR>
nnoremap <S-Left> :bprevious<CR>

set splitright

nnoremap <leader>t :vertical terminal<CR>

" Permite usar Ctrl+W para navegar e sair do terminal facilmente
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

" Shift+H vai para o primeiro caractere da linha / Shift+L vai para o último
nnoremap <S-h> ^
onoremap <S-h> ^
xnoremap <S-h> ^
nnoremap <S-l> g_
onoremap <S-l> g_
xnoremap <S-l> g_

nnoremap <silent> <leader><Tab>   :tabnext<CR>
nnoremap <silent> <leader><S-Tab> :tabprevious<CR>
nnoremap <silent> <C-p> :tabe \| :Ex<CR>

" Espaço + gs: Abre o Git Status em um terminal à direita
nnoremap <leader>gs :vertical terminal git status<CR>

" Espaço + gl: Abre o Git Log em um terminal à direita
nnoremap <leader>gl :vertical terminal git log --oneline<CR>

" Espaço + gd: Abre o Git Diff em tela cheia ocupando 100% da nova aba
nnoremap <leader>gd :tab terminal git diff<CR>

" Se você usa o <leader><Tab> no modo normal, garanta que ele funcione no terminal:
tnoremap <leader><Tab> <C-\><C-n><leader><Tab>

" Se você usa o Shift + Seta para alternar abas/buffers, adicione também:
tnoremap <S-Right> <C-\><C-n>:bnext<CR>
tnoremap <S-Left> <C-\><C-n>:bprevious<CR>

" Se você quiser alternar abas nativas do Vim no terminal (caso use :tabnext):
tnoremap <C-PageDown> <C-\><C-n>:tabnext<CR>
tnoremap <C-PageUp> <C-\><C-n>:tabprevious<CR>

" Espaço + cf copia o caminho/nome do arquivo atual para a área de transferência
nnoremap <leader>cf :let @+ = expand("%")<CR>

" Centraliza a tela na vertical ao rolar com Ctrl+U e Ctrl+D
nnoremap <C-u> <C-u>zz
nnoremap <C-d> <C-d>zz

" Centraliza a tela ao navegar pelas buscas com n e N
nnoremap n nzzzv
nnoremap N Nzzzv

" Mantém a seleção visual ativa ao recuar ou avançar blocos com < e >
vnoremap < <gv
vnoremap > >gv

" Espaço + lw ativa/desativa a quebra de linha visual (Wrap)
nnoremap <leader>lw :set wrap!<CR>

" Move blocos de texto selecionados para cima (K) ou para baixo (J) ajustando a indentação
vnoremap <silent> K :m '<-2<CR>gv=gv
vnoremap <silent> J :m '>+1<CR>gv=gv

" Faz a tecla 'x' deletar sem jogar o caractere para o clipboard (Registrador Blackhole)
nnoremap x "_x

" Espaço + rr prepara a substituição global da palavra sob o cursor no arquivo inteiro
nnoremap <leader>rr :%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>

" Deleta sem apagar o que já estava copiado no clipboard (Registrador Blackhole)
nnoremap <leader>dd "_d
vnoremap <leader>dd "_d

" Cola por cima de uma seleção visual sem perder o texto original que estava copiado
xnoremap p "_dP

" Redimensiona janelas usando Espaço + Setas do teclado
nnoremap <leader><left> :vertical resize +20<CR>
nnoremap <leader><right> :vertical resize -20<CR>
nnoremap <leader><up> :resize +10<CR>
nnoremap <leader><down> :resize -10<CR>

" Copiar e Colar
" Copiar para a área de transferência do Windows usando o atalho universal
vnoremap <C-c> "+y

" Atalhos usando o seu Leader (Espaço) para copiar e colar por fora
vnoremap <leader>y "+y
nnoremap <leader>y "+y
nnoremap <leader>p "+p
nnoremap <leader>P "+P

" AutoComplete
" Ativa a detecção do tipo de arquivo e carrega os arquivos de autocomplete nativos
filetype plugin on

" Ativa o menu flutuante de sugestões (popup) ao completar
set completeopt=menuone,noinsert,noselect

" Se o menu estiver aberto, Tab avança na lista. Se não, insere Tab normal.
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"

" Se o menu estiver aberto, Shift+Tab volta na lista. Se não, remove recuo normal.
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
