" ============================================================================
"  .vimrc — 42/1337 config (VSCode-style layout)
"  Copy to ~/.vimrc. Plugins auto-install on first launch (needs curl + git).
"  For icons, set your terminal font to a Nerd Font.
"
"  `vim .` / `vi .` / `vim`  ->  file tree on the LEFT, file content on the RIGHT
"  Click (or <CR>) a file in the tree and it opens on the right.
"  For `vi .` to work, vi must be full Vim:  alias vi=vim   (in ~/.zshrc / ~/.bashrc)
"
"  Keys:  <C-b>/<C-n> show/hide sidebar | <C-e> build (make or gcc) | <F6> run | <C-j> terminal panel
"         in the tree:  a new file/dir  r/<F2> rename  d/<Del> delete  y copy
"         <leader>v valgrind | <leader>x auto-fix the Norm | <leader>? all keys
"         <leader>i add #include | <leader>a stage file | <leader>c commit (+push)
"         <F4> copy mode (clean Ctrl+Shift+C) | <leader>y/<leader>p system clipboard
"         <C-k>/<F8> (free) | <leader>s send file/selection | <leader>d git diff
" ============================================================================

set nocompatible
set encoding=utf-8
scriptencoding utf-8
let mapleader = ' '

source $VIMRUNTIME/defaults.vim

" ----------------------------------------------------------------------------
" Plugins (vim-plug, bootstrapped automatically)
" ----------------------------------------------------------------------------
let s:plug = expand('~/.vim/autoload/plug.vim')
if empty(glob(s:plug))
    silent execute '!curl -fsSLo ' . shellescape(s:plug) . ' --create-dirs '
        \ . 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    autocmd VimEnter * ++once PlugInstall --sync | source $MYVIMRC
endif

if filereadable(s:plug)
    call plug#begin('~/.vim/plugged')
    Plug 'preservim/nerdtree'
    Plug 'ryanoasis/vim-devicons'      " must load after nerdtree
    Plug 'joshdick/onedark.vim'
    call plug#end()
endif

filetype plugin indent on
syntax on

" ----------------------------------------------------------------------------
" UI
" ----------------------------------------------------------------------------
set number
set cursorline
set scrolloff=5
set showmatch
set wildmenu
set laststatus=2
set signcolumn=yes
set mouse=a
set hidden
set updatetime=300
set nobackup nowritebackup noswapfile
set splitright splitbelow
set autoread

" Persistent undo (since swap/backup are off, this is your safety net)
let s:undo = expand('~/.vim/undo')
if !isdirectory(s:undo)
    call mkdir(s:undo, 'p', 0700)
endif
let &undodir = s:undo
set undofile

" Share the system clipboard when Vim supports it
if has('clipboard')
    set clipboard=unnamedplus
endif

" Reload files changed outside Vim (git checkout, norminette fixes, ...)
augroup AutoReload
    autocmd!
    autocmd FocusGained,BufEnter * if mode() !=# 'c' | silent! checktime | endif
augroup END

" Fuzzy-ish file finding with no plugin:  <C-p> then type + <Tab>
set path+=**
nnoremap <C-p> :find *

" Keep selection when indenting in visual mode
vnoremap < <gv
vnoremap > >gv

" Show tabs / trailing spaces
set list
set listchars=tab:▸\ ,trail:·,nbsp:␣
set fillchars+=vert:│

" Highlights: re-applied after every :colorscheme so nothing gets wiped
function! s:Highlights() abort
    " transparent background
    hi Normal      guibg=NONE ctermbg=NONE
    hi NonText     guibg=NONE ctermbg=NONE
    hi LineNr      guibg=NONE ctermbg=NONE
    hi SignColumn  guibg=NONE ctermbg=NONE
    hi EndOfBuffer guibg=NONE ctermbg=NONE

    " thin separator between tree and editor
    hi VertSplit   guifg=#3e4452 ctermfg=238 guibg=NONE ctermbg=NONE

    " NERDTree
    hi NERDTreeDir         guifg=#c678dd ctermfg=176
    hi NERDTreeDirSlash    guifg=#c678dd ctermfg=176
    hi NERDTreeFile        guifg=#abb2bf ctermfg=249
    hi NERDTreeOpenedFile  guifg=#98c379 ctermfg=114
    hi NERDTreeExecFile    guifg=#e06c75 ctermfg=204
    hi NERDTreeImageFile   guifg=#61afef ctermfg=75
    hi NERDTreeSymlinkFile guifg=#d19a66 ctermfg=173

    " inline tree decorations
    hi NTNormOk guifg=#98c379 ctermfg=114
    hi NTNormKo guifg=#e06c75 ctermfg=204
    hi NTGit    guifg=#e5c07b ctermfg=180

    " signs
    hi NormSign  guifg=#e06c75 ctermfg=204 guibg=NONE ctermbg=NONE
    hi GitAdd    guifg=#98c379 ctermfg=114 guibg=NONE ctermbg=NONE
    hi GitChange guifg=#e5c07b ctermfg=180 guibg=NONE ctermbg=NONE
    hi GitDelete guifg=#e06c75 ctermfg=204 guibg=NONE ctermbg=NONE

    " // comments are forbidden by the Norm: make them stand out
    hi NormComment guibg=#5a4a00 ctermbg=58 guifg=#ffdd55 ctermfg=221
    hi! link cCommentL NormComment

    " Norm line warnings
    hi NormLong     guibg=#5a1e1e ctermbg=52
    hi NormWarn     guifg=#e5c07b ctermfg=180 guibg=NONE ctermbg=NONE
    hi NormWarnLine guibg=#3a3320 ctermbg=237
    hi NormForbidHl guifg=#ffffff guibg=#9b2d30 ctermfg=15 ctermbg=124 gui=bold cterm=bold

    " status line accents: same background as the status line itself
    let l:sl  = synIDtrans(hlID('StatusLine'))
    let l:rev = synIDattr(l:sl, 'reverse')
    let l:gbg = synIDattr(l:sl, l:rev ? 'fg#' : 'bg#')
    let l:cbg = synIDattr(l:sl, l:rev ? 'fg'  : 'bg')
    let l:gbg = empty(l:gbg) ? 'NONE' : l:gbg
    let l:cbg = (empty(l:cbg) || l:cbg =~# '^#') ? 'NONE' : l:cbg
    for [l:n, l:g, l:c] in [['SLGreen', '#98c379', '114'], ['SLYellow', '#e5c07b', '180'],
        \ ['SLRed', '#e06c75', '204'], ['SLBlue', '#61afef', '75'],
        \ ['SLPurple', '#c678dd', '176'], ['SLDim', '#7f848e', '245']]
        execute 'hi ' . l:n . ' guifg=' . l:g . ' ctermfg=' . l:c
            \ . ' guibg=' . l:gbg . ' ctermbg=' . l:cbg . ' gui=NONE cterm=NONE'
    endfor
endfunction

augroup MyColors
    autocmd!
    autocmd ColorScheme * call s:Highlights()
augroup END

set background=dark
if has('termguicolors')
    set termguicolors
endif
try
    colorscheme onedark
catch
    colorscheme elflord
endtry
call s:Highlights()

" ----------------------------------------------------------------------------
" Indentation — 42 Norm: real tabs, width 4
" ----------------------------------------------------------------------------
set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab
set autoindent
set cindent

" ----------------------------------------------------------------------------
" Search
" ----------------------------------------------------------------------------
set ignorecase smartcase hlsearch incsearch
nnoremap <silent> <Esc><Esc> :nohlsearch<CR>
nnoremap <silent> <leader>h  :nohlsearch<CR>

" ----------------------------------------------------------------------------
" Status line (VSCode-like git info)
"   file.c [+]  [norm:ok]   main ↓1↑2 ●2 ✚1 ?3 │ [modified] │ a1b2c3d msg (3d) │ updated 5m │ created 1M,5d
"   ●staged  ✚changed  ?untracked  !conflicts   ↓behind ↑ahead (vs upstream)
"   updated = last time the file was saved on disk (ticks live: 20s, 5m, 1h,3m, 1d, 1M,5d)
"   commit  = last commit that touched this file;  created = commit that added it
" Narrow windows hide the less important parts automatically.
" ----------------------------------------------------------------------------
function! s:StatusGit(force) abort
    if &buftype !=# '' || expand('%') ==# ''
        return
    endif
    let l:now = localtime()
    if !a:force && l:now - get(b:, 'gitinfo_t', 0) < 3
        return
    endif
    let b:gitinfo_t = l:now
    let b:gitinfo = {}
    let l:file = expand('%:p')
    let l:g = 'git -C ' . shellescape(fnamemodify(l:file, ':h'))
    let l:st = systemlist(l:g . ' status --porcelain=v2 --branch 2>/dev/null')
    if v:shell_error
        return
    endif
    let l:i = {'branch': '', 'ahead': 0, 'behind': 0, 'staged': 0, 'changed': 0,
        \ 'untracked': 0, 'conflict': 0, 'file': '', 'hash': '', 'msg': '',
        \ 'ctime': 0, 'created': 0}
    let l:oid = ''
    for l:l in l:st
        if l:l =~# '^# branch.head '
            let l:i.branch = l:l[14:]
        elseif l:l =~# '^# branch.oid '
            let l:oid = l:l[13:]
        elseif l:l =~# '^# branch.ab '
            let l:m = matchlist(l:l, '+\(\d\+\) -\(\d\+\)')
            if !empty(l:m)
                let l:i.ahead = str2nr(l:m[1])
                let l:i.behind = str2nr(l:m[2])
            endif
        elseif l:l =~# '^[12] '
            if l:l[2] !=# '.' | let l:i.staged += 1 | endif
            if l:l[3] !=# '.' | let l:i.changed += 1 | endif
        elseif l:l =~# '^u '
            let l:i.conflict += 1
        elseif l:l =~# '^? '
            let l:i.untracked += 1
        endif
    endfor
    if l:i.branch ==# '(detached)'
        let l:i.branch = l:oid[:6]
    endif

    " this file: clean / staged / modified / untracked
    let l:q = ' -- ' . shellescape(l:file) . ' 2>/dev/null'
    let l:f = systemlist(l:g . ' status --porcelain' . l:q)
    let l:code = empty(l:f) ? '' : l:f[0][0:1]
    if l:code ==# '??'
        let l:i.file = 'untracked'
    elseif !empty(l:code)
        let l:tags = []
        if l:code[0] !=# ' ' | call add(l:tags, 'staged') | endif
        if l:code[1] !=# ' ' | call add(l:tags, 'modified') | endif
        let l:i.file = join(l:tags, '+')
    endif

    " last commit touching this file + the commit that created it
    let l:lg = systemlist(l:g . ' log -1 --format=%ct%x09%h%x09%s' . l:q)
    if !empty(l:lg)
        let l:p = split(l:lg[0], "\t", 1)
        if len(l:p) >= 3
            let l:i.ctime = str2nr(l:p[0])
            let l:i.hash = l:p[1]
            let l:i.msg = l:p[2]
        endif
        if empty(l:i.file)
            let l:i.file = 'clean'
        endif
        let l:cr = systemlist(l:g . ' log --diff-filter=A --format=%ct' . l:q)
        let l:i.created = empty(l:cr) ? 0 : str2nr(l:cr[-1])
    endif
    let b:gitinfo = l:i
endfunction

" --- 42 Norm function counter: max 25 lines per function, max 5 per file ---
function! s:FuncScan() abort
    if &buftype !=# '' || expand('%:e') !=# 'c' || line('$') > 5000
        unlet! b:fn
        return
    endif
    let l:lines = getline(1, '$')
    let l:fns = []
    let l:start = 0
    for l:n in range(1, len(l:lines))
        let l:t = l:lines[l:n - 1]
        " a function body starts with '{' in column 0 right after the prototype line
        " (struct/enum braces are skipped: their previous line has no ')')
        if l:start == 0 && l:t =~# '^{' && l:n > 1 && l:lines[l:n - 2] =~# ')\s*$'
            let l:start = l:n
        elseif l:start > 0 && l:t =~# '^}'
            call add(l:fns, [l:start, l:n])
            let l:start = 0
        endif
    endfor
    if l:start > 0
        call add(l:fns, [l:start, len(l:lines)])
    endif
    let b:fn = l:fns
endfunction

augroup FuncCount
    autocmd!
    autocmd BufEnter,BufReadPost,BufWritePost,TextChanged,TextChangedI,InsertLeave * call s:FuncScan()
    autocmd CursorMoved,CursorMovedI * if exists('b:fn') | redrawstatus! | endif
augroup END

let s:sl_active = 1

" one coloured piece of the status line (plain text in inactive windows)
function! s:SL(grp, text) abort
    let l:t = substitute(a:text, '%', '%%', 'g')
    if s:sl_active && !empty(a:grp)
        return '%#' . a:grp . '#' . l:t . '%#StatusLine#'
    endif
    return l:t
endfunction

" the coloured info part, for window a:win / buffer a:buf (a:w = room available,
" a:cp = cursor position of that window)
function! s:StatusInfo(win, buf, w, cp) abort
    if bufname(a:buf) ==# ''
        return ''
    endif
    let l:now = localtime()
    let l:w = a:w
    let l:i = getbufvar(a:buf, 'gitinfo', {})
    let l:sep = s:SL('SLDim', ' │ ')
    let l:o = ''

    " norminette: green ok / red errors
    let l:ns = getbufvar(a:buf, 'norm_state', '')
    if !empty(l:ns)
        let l:o .= ' ' . s:SL(l:ns =~# 'ok' ? 'SLGreen' : 'SLRed', l:ns)
    endif

    " function counter:  ƒ 3/5  [18/25] (current function)  ⚠ L42 28>25
    let l:fns = getbufvar(a:buf, 'fn', -1)
    if type(l:fns) == v:t_list
        let l:cnt = len(l:fns)
        let l:o .= ' ' . s:SL(l:cnt > 5 ? 'SLRed' : 'SLGreen',
            \ 'ƒ ' . l:cnt . '/5' . (l:cnt > 5 ? ' ⚠' : ''))
        let l:ln = a:cp[1]
        let l:cur = -1
        let l:bad = []
        for l:f in l:fns
            let l:len = l:f[1] - l:f[0] - 1
            if l:ln >= l:f[0] && l:ln <= l:f[1]
                let l:cur = l:len
            endif
            if l:len > 25 && empty(l:bad)
                let l:bad = [l:f[0], l:len]
            endif
        endfor
        if l:cur >= 0
            let l:o .= ' ' . s:SL(l:cur > 25 ? 'SLRed' : (l:cur > 20 ? 'SLYellow' : 'SLGreen'),
                \ '[' . l:cur . '/25]')
        endif
        if !empty(l:bad)
            let l:o .= ' ' . s:SL('SLRed', '⚠ L' . l:bad[0] . ' ' . l:bad[1] . '>25')
        endif
    endif

    " git: branch, sync, counts, file state, last commit
    if !empty(l:i)
        let l:o .= ' ' . s:SL('SLPurple', nr2char(0xe0a0) . ' ' . l:i.branch)
        if l:i.behind    | let l:o .= ' ' . s:SL('SLBlue',   '↓' . l:i.behind)    | endif
        if l:i.ahead     | let l:o .= ' ' . s:SL('SLBlue',   '↑' . l:i.ahead)     | endif
        if l:i.staged    | let l:o .= ' ' . s:SL('SLGreen',  '●' . l:i.staged)    | endif
        if l:i.changed   | let l:o .= ' ' . s:SL('SLYellow', '✚' . l:i.changed)   | endif
        if l:i.untracked | let l:o .= ' ' . s:SL('SLBlue',   '?' . l:i.untracked) | endif
        if l:i.conflict  | let l:o .= ' ' . s:SL('SLRed',    '!' . l:i.conflict)  | endif
        if !empty(l:i.file)
            let l:fc = l:i.file ==# 'untracked' ? 'SLBlue'
                \ : (l:i.file =~# 'modified' ? 'SLYellow' : 'SLGreen')
            let l:o .= l:sep . s:SL(l:fc, '[' . l:i.file . ']')
        endif
        if l:w >= 110 && !empty(l:i.hash)
            let l:o .= l:sep . s:SL('SLYellow', l:i.hash) . ' '
                \ . s:SL('', strcharpart(l:i.msg, 0, 30)) . ' '
                \ . s:SL('SLDim', '(' . s:Age(max([0, l:now - l:i.ctime])) . ')')
        endif
    endif

    " updated / created
    let l:mt = getftime(fnamemodify(bufname(a:buf), ':p'))
    if l:mt > 0
        let l:o .= l:sep . s:SL('SLDim', 'updated ') . s:Age(max([0, l:now - l:mt]))
    endif
    if !empty(l:i) && l:i.created > 0 && l:w >= 85
        let l:o .= l:sep . s:SL('SLDim', 'created ') . s:Age(max([0, l:now - l:i.created]))
    endif
    return l:o . ' '
endfunction

" --- where is the status line drawn? -----------------------------------------
" Vim gives every window its own status line. To keep ONE status line at the very
" bottom of the screen, the terminal panel (when open) carries the editor's status
" line, and the editor window above it only shows a thin divider.
let s:ed_win = 0

function! s:TrackEditorWin() abort
    if &buftype ==# '' && &filetype !=# 'nerdtree'
        let s:ed_win = win_getid()
    endif
endfunction

function! s:IsEditorBuf(buf) abort
    return getbufvar(a:buf, '&buftype') ==# '' && getbufvar(a:buf, '&filetype') !=# 'nerdtree'
endfunction

" last used normal editor window of this tab (0 if none)
function! s:EditorWin() abort
    if s:ed_win > 0 && win_id2win(s:ed_win) > 0 && s:IsEditorBuf(winbufnr(s:ed_win))
        return s:ed_win
    endif
    for l:w in getwininfo()
        if l:w.tabnr == tabpagenr() && s:IsEditorBuf(l:w.bufnr)
            return l:w.winid
        endif
    endfor
    return 0
endfunction

function! s:TermVisible() abort
    for l:w in getwininfo()
        if l:w.tabnr == tabpagenr() && l:w.terminal
            return 1
        endif
    endfor
    return 0
endfunction

augroup TrackEditorWin
    autocmd!
    autocmd WinEnter,BufEnter,BufWinEnter * call s:TrackEditorWin()
augroup END

" global: the whole 'statusline', through %{%...%}
function! StatusLine() abort
    let l:drawn = get(g:, 'statusline_winid', win_getid())
    let l:dbuf  = winbufnr(l:drawn)
    let l:dtype = getbufvar(l:dbuf, '&buftype')
    let l:cur   = win_getid()
    let l:wd    = getwininfo(l:drawn)[0].width
    let l:target = l:drawn
    let s:sl_active = (l:drawn == l:cur)

    if l:dtype ==# 'terminal'
        " terminal panel at the bottom: it shows the editor's status line
        let l:target = s:EditorWin()
        if l:target == 0
            return ''
        endif
        let s:sl_active = (l:drawn == l:cur) || (l:target == l:cur)
    elseif !s:IsEditorBuf(l:dbuf)
        " tree, quickfix, help...: plain
        return '%<%f %m%r%w%=%l,%c%V %p%%'
    elseif s:TermVisible()
        " editor window sitting above the terminal panel: thin divider only
        return '%#VertSplit#' . repeat('─', l:wd)
    endif

    let l:buf  = winbufnr(l:target)
    let l:name = fnamemodify(bufname(l:buf), ':~:.')
    let l:name = empty(l:name) ? '[No Name]' : l:name
    let l:flags = (getbufvar(l:buf, '&modified') ? ' [+]' : '')
        \ . (getbufvar(l:buf, '&readonly') ? ' [RO]' : '')

    " cursor position of the target window:  line,col[-virtcol]  percent
    let l:cp = getcurpos(l:target)
    let l:txt = get(getbufline(l:buf, l:cp[1]), 0, '')
    let l:vc = strdisplaywidth(strpart(l:txt, 0, max([l:cp[2] - 1, 0]))) + 1
    let l:pos = l:cp[1] . ',' . l:cp[2] . (l:vc != l:cp[2] ? '-' . l:vc : '')
        \ . ' ' . (l:cp[1] * 100 / max([1, line('$', l:target)])) . '%'

    return '%<' . (get(g:, 'copy_mode', 0) ? s:SL('SLRed', ' COPY MODE ') : '') . s:SL('', l:name . l:flags)
        \ . s:StatusInfo(l:target, l:buf, l:wd, l:cp) . '%=' . s:SL('', l:pos . ' ')
endfunction

set statusline=%{%StatusLine()%}

augroup StatusGit
    autocmd!
    autocmd BufEnter,FocusGained * call s:StatusGit(0)
    autocmd BufReadPost,BufWritePost,ShellCmdPost * call s:StatusGit(1)
augroup END

" redraw once a second so 'updated 20s' keeps counting
function! StatusTick(...) abort
    if mode() !=# 'c'
        redrawstatus!
    endif
endfunction
if !exists('s:status_timer')
    let s:status_timer = timer_start(1000, 'StatusTick', {'repeat': -1})
endif

" ----------------------------------------------------------------------------
" Auto-close brackets / quotes
" ----------------------------------------------------------------------------
inoremap ( ()<Left>
inoremap [ []<Left>
inoremap { {}<Left>

function! s:Quote(q) abort
    let l:cur  = getline('.')[col('.') - 1]
    let l:prev = col('.') > 1 ? getline('.')[col('.') - 2] : ''
    if l:cur ==# a:q
        return "\<Right>"              " skip over closing quote
    endif
    if l:prev =~# '\w'
        return a:q                     " apostrophes, e.g. don't
    endif
    return a:q . a:q . "\<Left>"
endfunction
inoremap <expr> " <SID>Quote('"')
inoremap <expr> ' <SID>Quote("'")

" Skip over an existing closing bracket instead of duplicating it
inoremap <expr> ) strpart(getline('.'), col('.') - 1, 1) ==# ')' ? "\<Right>" : ')'
inoremap <expr> ] strpart(getline('.'), col('.') - 1, 1) ==# ']' ? "\<Right>" : ']'
inoremap <expr> } strpart(getline('.'), col('.') - 1, 1) ==# '}' ? "\<Right>" : '}'

" Enter between {} opens an indented block
" Enter: accept the highlighted popup item, otherwise a normal Enter
"        (and between {} it opens an indented block)
inoremap <expr> <CR> pumvisible()
    \ ? (complete_info(['selected']).selected >= 0 ? "\<C-y>" : "\<C-e>\<CR>")
    \ : (strpart(getline('.'), col('.') - 2, 2) ==# '{}' ? "\<CR>\<Esc>O" : "\<CR>")

" ----------------------------------------------------------------------------
" Autocomplete popup (no plugin): words from your open files, as you type
"   <Tab>            accept (takes the first match if none is highlighted)
"   <C-n>/<C-p>, <Down>/<Up>   move in the list      <Enter>  accept highlighted
"   <Esc>            close it.  <Tab> is still a real tab when no popup is open.
"   :AutoCompleteToggle  turns the automatic popup on/off
" ----------------------------------------------------------------------------
set complete=.,w,b                       " this file, other windows, open buffers
set completeopt=menuone,noinsert,noselect
set pumheight=10
set shortmess+=c
let g:autocomplete = 1
let s:ac_skip = 0
let s:ac_typed = 0

function! s:AutoComplete() abort
    " only after a typed character: a paste / undo / formatter must not open the popup
    let l:typed = s:ac_typed
    let s:ac_typed = 0
    if s:ac_skip
        let s:ac_skip = 0
        return
    endif
    if !l:typed || !g:autocomplete || pumvisible() || &buftype !=# ''
        return
    endif
    let l:before = strpart(getline('.'), 0, col('.') - 1)
    if l:before =~# '\%(^\|\W\)[A-Za-z_]\w\{2,}$'
        call feedkeys("\<C-n>", 'n')
    endif
endfunction

augroup AutoComplete
    autocmd!
    autocmd InsertCharPre * let s:ac_typed = 1
    autocmd TextChangedI * call s:AutoComplete()
    " right after accepting an item, don't pop up again for the same word
    autocmd CompleteDone * if !empty(v:completed_item) | let s:ac_skip = 1 | endif
augroup END

command! AutoCompleteToggle let g:autocomplete = !g:autocomplete
    \ | echo 'Autocomplete popup: ' . (g:autocomplete ? 'on' : 'off')

inoremap <expr> <Tab>   pumvisible()
    \ ? (complete_info(['selected']).selected >= 0 ? "\<C-y>" : "\<C-n>\<C-y>") : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" ----------------------------------------------------------------------------
" NERDTree + devicons
" ----------------------------------------------------------------------------
let g:webdevicons_enable = 1
let g:webdevicons_enable_nerdtree = 1
let g:webdevicons_conceal_nerdtree_brackets = 1
let g:WebDevIconsNerdTreeAfterGlyphPadding = '  '

let g:NERDTreeShowHidden = 1             " like VSCode: show dotfiles...
let g:NERDTreeMinimalUI = 1
let g:NERDTreeWinSize = 32
let g:NERDTreeIgnore = ['\~$', '\.o$', '\.out$', '\.swp$', '\.pyc$', '\.class$',
    \ '^\.git$[[dir]]', '^\.DS_Store$']  " ...but hide .git itself
let g:NERDTreeDirArrowExpandable = '▸'
let g:NERDTreeDirArrowCollapsible = '▾'
let g:NERDTreeSortOrder = ['^__\.', '\.git$', '*/', '\.c$', '\.h$', '\.cpp$', '\.hpp$',
    \ '\.py$', '\.js$', '\.ts$', '\.go$', '\.rs$', '\.txt$', '\.md$', '\.json$', '\.ya\?ml$', '']
let g:NERDTreeAutoDeleteBuffer = 1
let g:NERDTreeHijackNetrw = 0            " we handle `vim .` ourselves (see Layout)
let g:NERDTreeMouseMode = 3              " single click opens files AND folders

" Show/hide the file sidebar: <C-b> (like VSCode), <C-n> or <F3>.
" Showing it keeps the cursor in your editor; <leader>e jumps into the tree.
function! s:TreeToggle() abort
    NERDTreeToggle
    if &filetype ==# 'nerdtree'
        wincmd p
    endif
endfunction
nnoremap <silent> <C-b> :call <SID>TreeToggle()<CR>
nnoremap <silent> <C-n> :call <SID>TreeToggle()<CR>
nnoremap <silent> <F3>  :call <SID>TreeToggle()<CR>
nnoremap <silent> <leader>f :NERDTreeFind<CR>
nnoremap <silent> <leader>e :NERDTreeFocus<CR>

" keep the tree a fixed-width sidebar, no clutter inside it
augroup NERDTreeLook
    autocmd!
    autocmd FileType nerdtree setlocal winfixwidth nolist signcolumn=no
    " keys are (re)bound on BufEnter so they win over NERDTree's own mappings
    autocmd BufEnter * if &filetype ==# 'nerdtree' | call s:TreeKeys() | endif
augroup END

" Simple file keys in the tree (they drive NERDTree's menu on `m`):
"   a = new file (end the name with / for a folder)   r / <F2> = rename
"   d / <Del> = delete (asks to confirm)               y = copy
function! s:TreeKeys() abort
    nmap <buffer> <silent> a     ma
    nmap <buffer> <silent> r     mm
    nmap <buffer> <silent> <F2>  mm
    nmap <buffer> <silent> d     md
    nmap <buffer> <silent> <Del> md
    nmap <buffer> <silent> y     mc
    nnoremap <buffer> <silent> <C-j> :call <SID>TermToggle()<CR>
endfunction

" quit Vim if the tree is the last window
augroup NERDTreeAutoClose
    autocmd!
    autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif
augroup END

" ----------------------------------------------------------------------------
" Tree decorations:  [n:ok]/[n:ko] (norminette)  [g:m] etc. (git)  [u:2d,3h] (age)
" Uses *virtual text* (Vim 9+), so the tree buffer is never modified and
" NERDTree keeps working. One async norminette run + two git calls per refresh.
" Press <F5> to refresh manually.
" ----------------------------------------------------------------------------
let s:norm_status = {}
let s:norm_new    = {}
let s:git_age     = {}
let s:git_state   = {}

function! s:TreeBuf() abort
    for l:w in range(1, winnr('$'))
        if getbufvar(winbufnr(l:w), '&filetype') ==# 'nerdtree'
            return winbufnr(l:w)
        endif
    endfor
    return -1
endfunction

function! s:Age(diff) abort
    let l:u = [[2592000, 'M'], [86400, 'd'], [3600, 'h'], [60, 'm'], [1, 's']]
    for l:i in range(len(l:u))
        if a:diff >= l:u[l:i][0]
            let l:out = (a:diff / l:u[l:i][0]) . l:u[l:i][1]
            if l:i + 1 < len(l:u)
                let l:sub = (a:diff % l:u[l:i][0]) / l:u[l:i + 1][0]
                if l:sub > 0
                    let l:out .= ',' . l:sub . l:u[l:i + 1][1]
                endif
            endif
            return l:out
        endif
    endfor
    return '0s'
endfunction

function! s:GatherGit(root) abort
    let s:git_age = {}
    let s:git_state = {}
    let l:top = trim(system('git -C ' . shellescape(a:root) . ' rev-parse --show-toplevel 2>/dev/null'))
    if v:shell_error || empty(l:top)
        return
    endif
    let l:ts = 0
    for l:l in systemlist('git -C ' . shellescape(l:top) . ' log -n 500 --name-only --pretty=format:%ct 2>/dev/null')
        if l:l =~# '^\d\+$'
            let l:ts = str2nr(l:l)
        elseif !empty(l:l) && !has_key(s:git_age, l:top . '/' . l:l)
            let s:git_age[l:top . '/' . l:l] = l:ts
        endif
    endfor
    for l:l in systemlist('git -C ' . shellescape(l:top) . ' status --porcelain 2>/dev/null')
        let l:code = l:l[0:1]
        let l:p = l:l[3:]
        if l:p =~# ' -> '
            let l:p = split(l:p, ' -> ')[-1]
        endif
        let l:c = l:code =~# '?' ? 'u' : l:code =~# 'M' ? 'm' : l:code =~# 'A' ? 'a'
            \ : l:code =~# 'D' ? 'd' : l:code =~# 'R' ? 'r' : l:code =~# 'C' ? 'c' : ''
        if !empty(l:c)
            let s:git_state[l:top . '/' . l:p] = l:c
        endif
    endfor
endfunction

function! s:OnNormLine(ch, msg) abort
    let l:msg = substitute(a:msg, "\e\\[[0-9;]*m", '', 'g')
    let l:m = matchlist(l:msg, '^\(.\{-}\): \(OK!\|Error!\)\s*$')
    if !empty(l:m)
        let s:norm_new[fnamemodify(l:m[1], ':p')] = (l:m[2] ==# 'OK!') ? 'ok' : 'ko'
    endif
endfunction

function! s:OnNormExit(job, status) abort
    let s:norm_status = s:norm_new
    call s:TreePaint()
endfunction

function! s:GatherNorm(root) abort
    if !executable('norminette') || !has('job')
        return
    endif
    if exists('s:norm_job') && job_status(s:norm_job) ==# 'run'
        return
    endif
    let s:norm_new = {}
    let s:norm_job = job_start(['norminette', a:root], {
        \ 'out_mode': 'nl',
        \ 'out_cb': function('s:OnNormLine'),
        \ 'exit_cb': function('s:OnNormExit'),
        \ })
endfunction

function! s:TreeInit() abort
    for [l:name, l:hl] in [['nt_ok', 'NTNormOk'], ['nt_ko', 'NTNormKo'], ['nt_git', 'NTGit']]
        if empty(prop_type_get(l:name))
            call prop_type_add(l:name, {'highlight': l:hl})
        endif
    endfor
endfunction

function! s:TreePaint() abort
    if !has('patch-9.0.0067')
        return
    endif
    let l:buf = s:TreeBuf()
    if l:buf < 0
        return
    endif
    let l:tree = getbufvar(l:buf, 'NERDTree', {})
    if empty(l:tree)
        return
    endif
    call s:TreeInit()
    let l:last = len(getbufline(l:buf, 1, '$'))
    let l:ma = getbufvar(l:buf, '&modifiable')
    call setbufvar(l:buf, '&modifiable', 1)
    call prop_clear(1, l:last, {'bufnr': l:buf})
    let l:now = localtime()
    for l:ln in range(1, l:last)
        try
            let l:path = l:tree.ui.getPath(l:ln)
        catch
            continue
        endtry
        if empty(l:path) || l:path.isDirectory
            continue
        endif
        let l:f = l:path.str()
        let l:n = get(s:norm_status, l:f, '')
        if l:n ==# 'ok'
            call prop_add(l:ln, 0, {'type': 'nt_ok', 'text': ' [n:ok]', 'text_align': 'after', 'bufnr': l:buf})
        elseif l:n ==# 'ko'
            call prop_add(l:ln, 0, {'type': 'nt_ko', 'text': ' [n:ko]', 'text_align': 'after', 'bufnr': l:buf})
        endif
        let l:g = get(s:git_state, l:f, '')
        if !empty(l:g)
            call prop_add(l:ln, 0, {'type': 'nt_git', 'text': ' [g:' . l:g . ']', 'text_align': 'after', 'bufnr': l:buf})
        endif
        if has_key(s:git_age, l:f)
            call prop_add(l:ln, 0, {'type': 'nt_git',
                \ 'text': ' [u:' . s:Age(max([0, l:now - s:git_age[l:f]])) . ']',
                \ 'text_align': 'after', 'bufnr': l:buf})
        endif
    endfor
    call setbufvar(l:buf, '&modifiable', l:ma)
endfunction

function! s:TreeRefresh() abort
    let l:buf = s:TreeBuf()
    if l:buf < 0
        return
    endif
    let l:tree = getbufvar(l:buf, 'NERDTree', {})
    if empty(l:tree)
        return
    endif
    let l:root = l:tree.root.path.str()
    call s:GatherGit(l:root)
    call s:GatherNorm(l:root)
    call s:TreePaint()
endfunction

" timer callback must be global
function! NerdTreeDecorate(...) abort
    call s:TreeRefresh()
endfunction

augroup NerdTreeDecor
    autocmd!
    autocmd FileType nerdtree  call timer_start(300, 'NerdTreeDecorate')
    autocmd BufEnter *         if &filetype ==# 'nerdtree' | call timer_start(100, 'NerdTreeDecorate') | endif
    autocmd BufWritePost *     call timer_start(200, 'NerdTreeDecorate')
    autocmd FocusGained *      call timer_start(200, 'NerdTreeDecorate')
augroup END
nnoremap <silent> <F5> :call NerdTreeDecorate()<CR>

" ----------------------------------------------------------------------------
" 42 header — auto on new *.c / *.h files, or press F1
" ----------------------------------------------------------------------------
let g:user42 = 'imnadir'
let g:mail42 = 'imnadir@student.1337.ma'

let s:hdr_art = [
    \ '        :::      ::::::::',
    \ '      :+:      :+:    :+:',
    \ '    +:+ +:+         +:+  ',
    \ '  +#+  +:+       +#+     ',
    \ '+#+#+#+#+#+   +#+        ',
    \ '     #+#    #+#          ',
    \ '    ###   ########.fr    ',
    \ ]
let s:hdr_created = ''
let s:hdr_updated = ''

function! s:HdrFilename() abort
    let l:name = expand('%:t')
    return empty(l:name) ? '< new >' : l:name
endfunction

function! s:HdrText(left, right) abort
    let l:left = strpart(a:left, 0, 80 - 15 - strlen(a:right) + 1)
    return '/*   ' . l:left
        \ . repeat(' ', 80 - 10 - strlen(l:left) - strlen(a:right))
        \ . a:right . '   */'
endfunction

function! s:HdrLine(n) abort
    if a:n == 1 || a:n == 11
        return '/* ' . repeat('*', 74) . ' */'
    elseif a:n == 2 || a:n == 10
        return s:HdrText('', '')
    elseif a:n >= 3 && a:n <= 9
        let l:art = s:hdr_art[a:n - 3]
        if a:n == 4
            return s:HdrText(s:HdrFilename(), l:art)
        elseif a:n == 6
            return s:HdrText('By: ' . g:user42 . ' <' . g:mail42 . '>', l:art)
        elseif a:n == 8
            return s:HdrText('Created: ' . s:hdr_created . ' by ' . g:user42, l:art)
        elseif a:n == 9
            return s:HdrText('Updated: ' . s:hdr_updated . ' by ' . g:user42, l:art)
        endif
        return s:HdrText('', l:art)
    endif
    return ''
endfunction

function! s:HdrExists() abort
    return getline(1) =~# '^/\* \*'
endfunction

function! s:Header42Update(force) abort
    if !s:HdrExists() || line('$') < 11
        return
    endif
    if !a:force && !&modified
        return
    endif
    let s:hdr_updated = strftime('%Y/%m/%d %H:%M:%S')
    if getline(9) =~# '^/\* *Updated: '
        call setline(9, s:HdrLine(9))
    endif
    if getline(4) =~# '^/\* '
        call setline(4, s:HdrLine(4))
    endif
endfunction

" #ifndef FT_X_H / # define FT_X_H / ... / #endif   (name from the file name)
function! s:HeaderGuard() abort
    if expand('%:e') !=# 'h' || search('^\s*#\s*ifndef\s\+\w\+', 'nw')
        return
    endif
    let l:name = toupper(substitute(expand('%:t:r'), '[^A-Za-z0-9]', '_', 'g')) . '_H'
    let l:at = s:HdrExists() ? 12 : 0
    call append(l:at, ['#ifndef ' . l:name, '# define ' . l:name, ''])
    if getline('$') !~# '^\s*$'
        call append(line('$'), '')
    endif
    call append(line('$'), '#endif')
    call cursor(l:at + 3, 1)
endfunction
command! HeaderGuard call s:HeaderGuard()

function! s:Header42Insert() abort
    if s:HdrExists()
        call s:Header42Update(1)
        return
    endif
    let l:stamp = strftime('%Y/%m/%d %H:%M:%S')
    let s:hdr_created = l:stamp
    let s:hdr_updated = l:stamp
    let l:lines = map(range(1, 11), 's:HdrLine(v:val)')
    call append(0, l:lines + [''])
    " a fresh buffer starts with one empty line: drop the duplicate
    if line('$') > 1 && getline('$') ==# '' && getline(line('$') - 1) ==# ''
        execute line('$') . 'delete _'
    endif
    call cursor(12, 1)
    call s:HeaderGuard()
endfunction

command! Header42 call s:Header42Insert()
nnoremap <silent> <F1> :Header42<CR>
inoremap <silent> <F1> <C-o>:Header42<CR>

augroup Header42
    autocmd!
    autocmd BufNewFile *.c,*.h call s:Header42Insert()
    " files created from the tree (key a) already exist on disk, but are empty
    autocmd BufReadPost *.c,*.h if line('$') == 1 && getline(1) ==# '' | call s:Header42Insert() | endif
    autocmd BufWritePre *.c,*.h call s:Header42Update(0)
augroup END

" ----------------------------------------------------------------------------
" Build (Ctrl-e -> quickfix) and run (F6)
"   Makefile found (current folder or any parent) -> make -C <that folder>
"   no Makefile                                   -> gcc -Wall -Wextra -Werror <file>
" ----------------------------------------------------------------------------
function! s:Compile() abort
    if &buftype !=# '' || &filetype ==# 'nerdtree'
        wincmd p
    endif
    silent! update
    let l:dir = expand('%:p:h')
    let l:mk = findfile('Makefile', l:dir . ';' . $HOME)
    if empty(l:mk)
        let l:mk = findfile('makefile', l:dir . ';' . $HOME)
    endif
    if !empty(l:mk)
        let l:cmd = 'make -C ' . shellescape(fnamemodify(l:mk, ':p:h'))
        let l:ok  = 'Build OK (make)'
    else
        let l:cmd = 'gcc -Wall -Wextra -Werror ' . shellescape(expand('%:p')) . ' -o a.out'
        let l:ok  = 'Build OK -> ./a.out'
    endif
    echo 'Building: ' . l:cmd
    redraw
    let l:out = systemlist(l:cmd . ' 2>&1')
    let l:rc  = v:shell_error
    cgetexpr l:out
    call setqflist([], 'a', {'title': l:cmd})
    " unparsable lines (make/ld messages) stay in the list as plain text,
    " so only *valid* entries (file:line errors/warnings) count as problems
    let l:bad = len(filter(getqflist(), 'v:val.valid'))
    if l:rc == 0 && l:bad == 0
        cclose
        echo l:ok
    else
        copen
        if l:rc == 0
            echo l:ok . ' (with warnings)'
        endif
    endif
endfunction
nnoremap <silent> <C-e> :call <SID>Compile()<CR>
if has('terminal')
    nnoremap <silent> <F6> :botright terminal ++rows=12 ./a.out<CR>
endif

" ----------------------------------------------------------------------------
" 42 Norm auto-formatter (runs on save for .c/.h)
" ----------------------------------------------------------------------------
" Set to 1 to also strip // comments on save (off by default: it deletes text)
let g:norm_strip_line_comments = 0

let s:decl = '^\s*\%(const\s\+\|static\s\+\|unsigned\s\+\|signed\s\+\)*'
    \ . '\%(void\|char\|int\|long\|short\|float\|double\|size_t\|ssize_t\|'
    \ . '\h\w*_t\|t_\w\+\|FILE\|DIR\|struct\s\+\w\+\|union\s\+\w\+\|enum\s\+\w\+\)'
    \ . '[ \t]\+\**\h\w*\s*[;,=\[]'

" No blank line right after '{' or right before '}'
" blank lines inside a function body are forbidden (the one after the declarations
" is added back by s:FixVarSpacing)
function! s:FixFuncBlanks(start) abort
    let l:del = []
    let l:in = 0
    for l:n in range(a:start, line('$'))
        let l:t = getline(l:n)
        if l:t =~# '^{'
            let l:in = 1
        elseif l:t =~# '^}'
            let l:in = 0
        elseif l:in && l:t =~# '^\s*$'
            call add(l:del, l:n)
        endif
    endfor
    for l:n in reverse(l:del)
        call deletebufline('%', l:n)
    endfor
endfunction

function! s:FixBraceSpacing(start) abort
    let l:i = a:start
    while l:i < line('$')
        if getline(l:i) =~# '{\s*$' && getline(l:i + 1) =~# '^\s*$'
            execute (l:i + 1) . 'delete _'
            continue
        endif
        if getline(l:i) =~# '^\s*$' && getline(l:i + 1) =~# '^\s*}'
            execute l:i . 'delete _'
            let l:i -= 1
            continue
        endif
        let l:i += 1
    endwhile
endfunction

" Blank line after the #include block / after each function's closing '}'
function! s:FixBlankAfter(start) abort
    let l:i = a:start
    while l:i < line('$')
        let l:line = getline(l:i)
        let l:next = getline(l:i + 1)
        if l:next !~# '^\s*$'
            if (l:line =~# '^\s*#\s*include' && l:next !~# '^\s*#\s*include')
                \ || l:line =~# '^}'
                call append(l:i, '')
                let l:i += 1
            endif
        endif
        let l:i += 1
    endwhile
endfunction

" Blank line after the local-declaration block inside a function
function! s:FixVarSpacing(start) abort
    let l:i = a:start
    let l:in_func = 0
    while l:i < line('$')
        let l:line = getline(l:i)
        if l:line =~# '^{'
            let l:in_func = 1
        elseif l:line =~# '^}'
            let l:in_func = 0
        endif
        if l:in_func && l:line =~# s:decl && l:line =~# ';\s*$'
            let l:next = getline(l:i + 1)
            if l:next !~# s:decl && l:next !~# '^\s*$' && l:next !~# '^\s*}'
                call append(l:i, '')
                let l:i += 1
            endif
        endif
        let l:i += 1
    endwhile
endfunction

" ----------------------------------------------------------------------------
" Norm auto-fix. Runs on every save of a .c/.h file and with <leader>x.
"   1. c_formatter_42 if installed  (pip3 install --user c-formatter-42)  <- best
"   2. otherwise the built-in fixes below: preprocessor indent (# define),
"      spaces -> tabs, `if (`, `return (`, `, `, tabs between type and name,
"      aligned declarations, plus blank-line rules.
" :NormAutoFixToggle turns the save-time fix on/off.
" ----------------------------------------------------------------------------
let g:norm_autofix = 1
let g:norm_use_c_formatter = 1

command! NormAutoFixToggle let g:norm_autofix = !g:norm_autofix
    \ | echo 'Norm auto-fix on save: ' . (g:norm_autofix ? 'on' : 'off')

function! s:RunCFormatter() abort
    if line('$') < 2
        return 0
    endif
    let l:out = system('c_formatter_42', join(getline(1, '$'), "\n") . "\n")
    if v:shell_error || empty(l:out)
        return 0
    endif
    let l:new = split(l:out, "\n", 1)
    if !empty(l:new) && l:new[-1] ==# ''
        call remove(l:new, -1)
    endif
    if empty(l:new)
        return 0
    endif
    if l:new !=# getline(1, '$')
        call setline(1, l:new)
        if line('$') > len(l:new)
            silent execute (len(l:new) + 1) . ',$delete _'
        endif
    endif
    return 1
endfunction

" 4+ leading spaces -> tabs
function! s:FixLeadingSpaces(start) abort
    for l:n in range(a:start, line('$'))
        let l:m = matchlist(getline(l:n), '^\(\t*\)\( \{4,}\)\([^ ].*\)$')
        if !empty(l:m) && l:m[3] !~# '^\*'
            call setline(l:n, l:m[1] . repeat("\t", len(l:m[2]) / 4)
                \ . repeat(' ', len(l:m[2]) % 4) . l:m[3])
        endif
    endfor
endfunction

" #define inside #ifndef -> "# define", nested -> "#  define", ...
function! s:FixPreproc(start) abort
    let l:depth = 0
    for l:n in range(a:start, line('$'))
        let l:m = matchlist(getline(l:n), '^\s*#\s*\(\h\w*\)\(.*\)$')
        if empty(l:m)
            continue
        endif
        let l:d = l:m[1]
        if l:d =~# '^if\%(n\?def\)\?$'
            let l:ind = l:depth
            let l:depth += 1
        elseif l:d =~# '^\%(else\|elif\)$'
            let l:ind = max([l:depth - 1, 0])
        elseif l:d ==# 'endif'
            let l:depth = max([l:depth - 1, 0])
            let l:ind = l:depth
        else
            let l:ind = l:depth
        endif
        let l:new = '#' . repeat(' ', l:ind) . l:d . l:m[2]
        if l:new !=# getline(l:n)
            call setline(l:n, l:new)
        endif
    endfor
endfunction

" spacing fixes on a piece of code (no strings / comments in it)
function! s:CodeFix(seg) abort
    let l:t = substitute(a:seg, '\<\(if\|while\|return\)\s*(', '\1 (', 'g')
    let l:t = substitute(l:t, '(\s\+\ze\S', '(', 'g')
    let l:t = substitute(l:t, '\S\zs\s\+)', ')', 'g')
    let l:t = substitute(l:t, '\S\zs\s\+\([,;]\)', '\1', 'g')
    let l:t = substitute(l:t, ',\ze[^ \t]', ', ', 'g')
    " spaces around assignment / comparison / logic operators
    let l:t = substitute(l:t, '\S\zs\s*\(<<=\|>>=\|[-+*/%&|^]=\|==\|!=\|<=\|>=\|&&\|||\|=\)\s*', ' \1 ', 'g')
    " a<b  a+b  a*b ... written without any space (a space on one side is ambiguous: *p, a *b)
    let l:t = substitute(l:t, '\([A-Za-z0-9_)\]]\)\([<>]\)\ze[A-Za-z0-9_(]', '\1 \2 ', 'g')
    if l:t !~# '[0-9][eE][-+]'
        let l:t = substitute(l:t, '\([A-Za-z0-9_)\]]\)\([-+*/%]\)\ze[A-Za-z0-9_(]', '\1 \2 ', 'g')
    endif
    let l:t = substitute(l:t, '\<\(break\|continue\|return\)\s*;', '\1 ;', 'g')
    return l:t
endfunction

" apply s:CodeFix to a line but leave "strings", 'c' and comments alone
function! s:CodeSub(line) abort
    let l:pat = '"\%(\\.\|[^"\\]\)*"\|''\%(\\.\|[^''\\]\)*''\|//.*$\|/\*.\{-}\*/'
    let l:out = ''
    let l:rest = a:line
    while 1
        let l:p = matchstrpos(l:rest, l:pat)
        if l:p[1] < 0
            return l:out . s:CodeFix(l:rest)
        endif
        let l:c = s:CodeFix(strpart(l:rest, 0, l:p[1]))
        if l:c =~# ',$' && l:p[0] =~# '^["'']'
            let l:c .= ' '
        endif
        let l:out .= l:c . l:p[0]
        let l:rest = strpart(l:rest, l:p[2])
    endwhile
endfunction

function! s:FixSpacing(start) abort
    let l:inc = 0
    for l:n in range(a:start, line('$'))
        let l:t = getline(l:n)
        if l:inc
            if l:t =~# '\*/'
                let l:inc = 0
            endif
            continue
        endif
        if l:t =~# '^\s*#'
            continue
        endif
        if l:t =~# '/\*' && l:t !~# '\*/'
            let l:inc = 1
            continue
        endif
        let l:new = s:CodeSub(l:t)
        if l:new !=# l:t
            call setline(l:n, l:new)
        endif
    endfor
endfunction

let s:ty = '\%(\%(const\|static\|unsigned\|signed\|volatile\|register\)\s\+\)*'
    \ . '\%(long\s\+long\|void\|char\|int\|long\|short\|float\|double\|size_t\|ssize_t\|bool\|'
    \ . '\h\w*_t\|t_\w\+\|FILE\|DIR\|struct\s\+\w\+\|union\s\+\w\+\|enum\s\+\w\+\)'

" tabs needed to go from column a:from to (at least) column a:to
function! s:TabsTo(from, to) abort
    let l:c = a:from
    let l:n = 0
    while l:c < a:to
        let l:c = (l:c / 4 + 1) * 4
        let l:n += 1
    endwhile
    return repeat("\t", max([l:n, 1]))
endfunction

function! s:AlignDecls(grp) abort
    let l:w = 0
    for l:g in a:grp
        let l:w = max([l:w, 4 + strdisplaywidth(l:g[1])])
    endfor
    let l:target = (l:w / 4 + 1) * 4
    for l:g in a:grp
        let l:new = "\t" . l:g[1] . s:TabsTo(4 + strdisplaywidth(l:g[1]), l:target) . l:g[2]
        if l:new !=# getline(l:g[0])
            call setline(l:g[0], l:new)
        endif
    endfor
endfunction

" local variables / struct fields: type<TAB(s)>name, all names in a block aligned
function! s:FixDeclAlign(start) abort
    let l:grp = []
    let l:end = line('$') + 1
    for l:n in range(a:start, l:end)
        let l:m = l:n < l:end ? matchlist(getline(l:n),
            \ '^\t\(' . s:ty . '\)[ \t]\+\(\**\h\w*\s*[;,=\[].*\)$') : []
        if !empty(l:m)
            call add(l:grp, [l:n, substitute(l:m[1], '\s\+', ' ', 'g'), l:m[2]])
        elseif !empty(l:grp)
            call s:AlignDecls(l:grp)
            let l:grp = []
        endif
    endfor
endfunction

" function definitions / prototypes: type<TAB>name   (prototypes aligned together)
function! s:FixFuncAlign(start) abort
    let l:hdr = expand('%:e') ==# 'h'
    let l:groups = []
    let l:hgrp = []
    let l:prev = []
    for l:n in range(a:start, line('$'))
        let l:m = matchlist(getline(l:n),
            \ '^\(\%(\h\w*[ \t]\+\)*\h\w*\)[ \t]\+\(\**\h\w*\s*(.*\)$')
        if empty(l:m) || l:m[1] =~# '^\%(else\|return\|typedef\|goto\|case\)\>'
            \ || l:m[2] =~# '^\**\%(if\|while\|for\|switch\|sizeof\|return\)\>'
            continue
        endif
        let l:it = [l:n, substitute(l:m[1], '\s\+', ' ', 'g'), l:m[2]]
        if l:m[2] =~# ';\s*$'
            if l:hdr
                call add(l:hgrp, l:it)
            elseif !empty(l:prev) && l:prev[-1][0] == l:n - 1
                call add(l:prev, l:it)
            else
                let l:prev = [l:it]
                call add(l:groups, l:prev)
            endif
        else
            call add(l:groups, [l:it])
        endif
    endfor
    if !empty(l:hgrp)
        call add(l:groups, l:hgrp)
    endif
    for l:g in l:groups
        let l:w = 0
        for l:it in l:g
            let l:w = max([l:w, strdisplaywidth(l:it[1])])
        endfor
        let l:target = (l:w / 4 + 1) * 4
        for l:it in l:g
            let l:new = l:it[1] . s:TabsTo(strdisplaywidth(l:it[1]), l:target) . l:it[2]
            if l:new !=# getline(l:it[0])
                call setline(l:it[0], l:new)
            endif
        endfor
    endfor
endfunction

" ============================================================================
" Norm DEEP fix: norminette is the judge.  On every save (after the layout fix):
"   1. run norminette on the buffer text
"   2. rewrite what is safely rewritable, driven by the error codes + line numbers
"   3. layout fix again, ask norminette again, keep the result only if it is not worse
"   4. repeat (max 5 rounds / 8 s), then report what is left.
" One undo (u) brings back your text.  :NormDeepToggle turns it off.
" Rewrites: for->while, ternary->if/else, decl+assign split, multiple declarations,
"   a = b = c, declarations moved to the top, comments moved out of functions,
"   return (x), f(void), one instruction per line, braces/newlines.
" Not auto-fixable (reported with a hint): function > 25 lines, > 4 params, > 5 vars,
"   > 5 functions, lines > 80, switch/case/goto/do, macro functions, naming prefixes.
" ============================================================================
let g:norm_deep = 1
let g:norm_compile_guard = 1
let s:norm_todo = []

let s:norm_hint = {
    \ 'TOO_MANY_LINES': '  -> split the function (max 25 lines)',
    \ 'TOO_MANY_FUNCS': '  -> move some functions to another .c file',
    \ 'TOO_MANY_ARGS': '  -> max 4 parameters: group them in a struct',
    \ 'TOO_MANY_VARS_FUNC': '  -> max 5 variables: use a helper function or a struct',
    \ 'LINE_TOO_LONG': '  -> shorten names or split the expression',
    \ 'FORBIDDEN_CS': '  -> for/while only: no switch, case, goto, do',
    \ 'MACRO_FUNC_FORBIDDEN': '  -> write a real function instead of a macro',
    \ 'FORBIDDEN_STRUCT': '  -> declare it in a .h file',
    \ 'FORBIDDEN_TYPEDEF': '  -> declare it in a .h file',
    \ 'FORBIDDEN_ENUM': '  -> declare it in a .h file',
    \ 'FORBIDDEN_UNION': '  -> declare it in a .h file',
    \ 'STRUCT_TYPE_NAMING': '  -> rename: s_name',
    \ 'USER_DEFINED_TYPEDEF': '  -> rename: t_name',
    \ 'ENUM_TYPE_NAMING': '  -> rename: e_name',
    \ 'UNION_TYPE_NAMING': '  -> rename: u_name',
    \ 'GLOBAL_VAR_NAMING': '  -> rename: g_name',
    \ 'MACRO_NAME_CAPITAL': '  -> macro names in CAPITALS',
    \ 'FORBIDDEN_CHAR_NAME': '  -> only lowercase, digits and _ in names',
    \ 'PREPROC_CONSTANT': '  -> #define only for constants',
    \ 'INCLUDE_HEADER_ONLY': '  -> never #include a .c file',
    \ }

" replace the whole buffer text with a:lines
function! s:SetLines(lines) abort
    call setline(1, a:lines)
    if line('$') > len(a:lines)
        call deletebufline('%', len(a:lines) + 1, '$')
    endif
endfunction

" append lines after line a:after, keeping the pending to-do line numbers right
function! s:Ins(after, lines) abort
    let l:l = type(a:lines) == v:t_list ? a:lines : [a:lines]
    if empty(l:l)
        return
    endif
    call append(a:after, l:l)
    for l:it in s:norm_todo
        if l:it[0] > a:after
            let l:it[0] += len(l:l)
        endif
    endfor
endfunction

function! s:Del(lnum) abort
    call deletebufline('%', a:lnum)
    for l:it in s:norm_todo
        if l:it[0] > a:lnum
            let l:it[0] -= 1
        endif
    endfor
endfunction

function! s:Mask(t) abort
    return s:MaskLine(a:t, 0)[0]
endfunction

" index of the ) or ] matching the ( or [ at index a:i of the masked string a:m
function! s:MatchParen(m, i) abort
    let l:d = 0
    for l:k in range(a:i, len(a:m) - 1)
        let l:c = a:m[l:k]
        if l:c ==# '(' || l:c ==# '['
            let l:d += 1
        elseif l:c ==# ')' || l:c ==# ']'
            let l:d -= 1
            if l:d == 0
                return l:k
            endif
        endif
    endfor
    return -1
endfunction

" positions of char a:ch at nesting depth 0 in the masked string a:m
function! s:TopPos(m, ch) abort
    let l:d = 0
    let l:r = []
    for l:k in range(len(a:m))
        let l:c = a:m[l:k]
        if l:c =~# '[([{]'
            let l:d += 1
        elseif l:c =~# '[)\]}]'
            let l:d -= 1
        elseif l:c ==# a:ch && l:d == 0
            call add(l:r, l:k)
        endif
    endfor
    return l:r
endfunction

function! s:SplitTop(t, m, ch) abort
    let l:out = []
    let l:s = 0
    for l:p in s:TopPos(a:m, a:ch)
        call add(l:out, strpart(a:t, l:s, l:p - l:s))
        let l:s = l:p + 1
    endfor
    call add(l:out, strpart(a:t, l:s))
    return l:out
endfunction

" [open, close] line numbers of the function body containing a:lnum ([] if none)
function! s:FuncRange(lnum) abort
    let l:o = 0
    for l:n in range(a:lnum, 1, -1)
        if getline(l:n) =~# '^{'
            let l:o = l:n
            break
        elseif l:n < a:lnum && getline(l:n) =~# '^}'
            return []
        endif
    endfor
    if !l:o
        return []
    endif
    for l:n in range(a:lnum, line('$'))
        if getline(l:n) =~# '^}'
            return [l:o, l:n]
        endif
    endfor
    return []
endfunction

" parse a one-line declaration "<indent><type> <declarators>;" ({} if it is not one)
function! s:ParseDecl(t) abort
    let l:m = matchlist(a:t, '^\(\s*\)\(' . s:ty . '\)\s\+\(.*;\)\s*$')
    if empty(l:m)
        return {}
    endif
    let l:mask = s:Mask(l:m[3])
    if l:mask =~# '[{}]'
        return {}
    endif
    let l:body = strpart(l:m[3], 0, len(l:m[3]) - 1)
    let l:bm = strpart(l:mask, 0, len(l:mask) - 1)
    let l:decls = []
    for l:d in s:SplitTop(l:body, l:bm, ',')
        let l:x = matchlist(trim(l:d), '^\(\**\)\s*\(\h\w*\)\s*\(\%(\[[^\]]*\]\)*\)\s*\%(=\s*\(.*\)\)\?$')
        if empty(l:x)
            return {}
        endif
        call add(l:decls, {'stars': l:x[1], 'name': l:x[2], 'arr': l:x[3], 'init': l:x[4]})
    endfor
    return {'indent': l:m[1], 'type': substitute(l:m[2], '\s\+', ' ', 'g'), 'decls': l:decls}
endfunction

" last line of the declaration block at the top of the function [open, close]
function! s:DeclEnd(open, close) abort
    let l:e = a:open
    for l:n in range(a:open + 1, a:close - 1)
        if empty(s:ParseDecl(getline(l:n)))
            break
        endif
        let l:e = l:n
    endfor
    return l:e
endfunction

" 0: not declared in the top block, 1: same declaration, -1: same name, other type
function! s:DeclConflict(open, e, type, x) abort
    for l:n in range(a:open + 1, a:e)
        let l:d = s:ParseDecl(getline(l:n))
        for l:y in get(l:d, 'decls', [])
            if l:y.name ==# a:x.name
                return (l:d.type ==# a:type && l:y.stars ==# a:x.stars && l:y.arr ==# a:x.arr) ? 1 : -1
            endif
        endfor
    endfor
    return 0
endfunction

function! s:DeclText(d, x) abort
    return "\t" . a:d.type . "\t" . a:x.stars . a:x.name . a:x.arr . ';'
endfunction

" int c = 5;  ->  int c; (in the top block)  +  c = 5; (after the block / in place)
function! s:FixDeclAssign(lnum) abort
    let l:t = getline(a:lnum)
    let l:d = s:ParseDecl(l:t)
    if empty(l:d) || len(l:d.decls) != 1 || empty(l:d.decls[0].init)
        return 0
    endif
    let l:x = l:d.decls[0]
    if l:t =~# '^\s*\%(static\|const\|register\)\>' || !empty(l:x.arr) || l:x.init =~# '^{'
        return 0
    endif
    let l:fr = s:FuncRange(a:lnum)
    if empty(l:fr)
        return 0
    endif
    let l:e = s:DeclEnd(l:fr[0], l:fr[1])
    let l:asg = l:d.indent . l:x.name . ' = ' . l:x.init . ';'
    if a:lnum <= l:e
        call setline(a:lnum, s:DeclText(l:d, l:x))
        call s:Ins(l:e, [l:asg])
        return 1
    endif
    let l:c = s:DeclConflict(l:fr[0], l:e, l:d.type, l:x)
    if l:c < 0
        return 0
    endif
    call setline(a:lnum, l:asg)
    if l:c == 0
        call s:Ins(l:e, [s:DeclText(l:d, l:x)])
    endif
    return 1
endfunction

" a declaration in the middle of a function -> moved to the top block
function! s:FixDeclLate(lnum) abort
    let l:d = s:ParseDecl(getline(a:lnum))
    if empty(l:d)
        return 0
    endif
    for l:x in l:d.decls
        if !empty(l:x.init)
            return 0
        endif
    endfor
    let l:fr = s:FuncRange(a:lnum)
    if empty(l:fr)
        return 0
    endif
    let l:e = s:DeclEnd(l:fr[0], l:fr[1])
    if a:lnum <= l:e
        return 0
    endif
    let l:new = []
    for l:x in l:d.decls
        let l:c = s:DeclConflict(l:fr[0], l:e, l:d.type, l:x)
        if l:c < 0
            return 0
        elseif l:c == 0
            call add(l:new, s:DeclText(l:d, l:x))
        endif
    endfor
    call s:Del(a:lnum)
    call s:Ins(l:e, l:new)
    return 1
endfunction

" int a, b;  ->  one declaration per line
function! s:FixMultDecl(lnum) abort
    let l:d = s:ParseDecl(getline(a:lnum))
    if empty(l:d) || len(l:d.decls) < 2
        return 0
    endif
    let l:lines = []
    for l:x in l:d.decls
        call add(l:lines, l:d.indent . l:d.type . "\t" . l:x.stars . l:x.name . l:x.arr
            \ . (empty(l:x.init) ? '' : ' = ' . l:x.init) . ';')
    endfor
    call setline(a:lnum, l:lines[0])
    call s:Ins(a:lnum, l:lines[1:])
    return 1
endfunction

" positions of a plain assignment '=' (not ==, <=, +=, ...) at depth 0
function! s:AssignPos(m) abort
    let l:r = []
    let l:d = 0
    for l:k in range(len(a:m))
        let l:c = a:m[l:k]
        if l:c =~# '[([{]'
            let l:d += 1
        elseif l:c =~# '[)\]}]'
            let l:d -= 1
        elseif l:c ==# '=' && l:d == 0
            let l:p = l:k > 0 ? a:m[l:k - 1] : ''
            let l:n = l:k + 1 < len(a:m) ? a:m[l:k + 1] : ''
            if l:p !~# '[=!<>+\-*/%&|^]' && l:n !=# '='
                call add(l:r, l:k)
            endif
        endif
    endfor
    return l:r
endfunction

" a = b = 0;  ->  b = 0;  a = b;
function! s:FixMultAssign(lnum) abort
    let l:t = getline(a:lnum)
    let l:m = s:Mask(l:t)
    let l:mm = matchlist(l:m, '^\(\s*\)\(.\{-}\)\s*;\s*$')
    if empty(l:mm) || !empty(s:ParseDecl(l:t)) || l:mm[2] =~# '^\%(return\|if\|while\|else\|for\)\>'
        return 0
    endif
    let l:ind = l:mm[1]
    let l:st = strpart(l:t, len(l:ind), len(l:mm[2]))
    let l:pos = s:AssignPos(l:mm[2])
    if len(l:pos) < 2
        return 0
    endif
    let l:parts = []
    let l:s = 0
    for l:p in l:pos
        call add(l:parts, trim(strpart(l:st, l:s, l:p - l:s)))
        let l:s = l:p + 1
    endfor
    call add(l:parts, trim(strpart(l:st, l:s)))
    let l:n = len(l:parts)
    for l:k in range(l:n - 1)
        if empty(l:parts[l:k]) || l:parts[l:k] =~# '(\|++\|--'
            return 0
        endif
    endfor
    let l:out = [l:ind . l:parts[l:n - 2] . ' = ' . l:parts[l:n - 1] . ';']
    for l:k in range(l:n - 3, 0, -1)
        call add(l:out, l:ind . l:parts[l:k] . ' = ' . l:parts[l:k + 1] . ';')
    endfor
    call setline(a:lnum, l:out[0])
    call s:Ins(a:lnum, l:out[1:])
    return 1
endfunction

" return x;  ->  return (x);
function! s:FixReturn(lnum) abort
    let l:t = getline(a:lnum)
    let l:m = matchlist(l:t, '^\(\s*\)return\s\+\(.\{-}\)\s*;\s*$')
    if empty(l:m) || empty(l:m[2])
        return 0
    endif
    let l:mk = s:Mask(l:m[2])
    if l:m[2][0] ==# '(' && s:MatchParen(l:mk, 0) == len(l:m[2]) - 1
        return 0
    endif
    call setline(a:lnum, l:m[1] . 'return (' . l:m[2] . ');')
    return 1
endfunction

" int f()  ->  int f(void)
function! s:FixNoArgs(lnum) abort
    let l:t = getline(a:lnum)
    let l:n = substitute(l:t, '^\(\%(\h\w*[ \t]\+\)*\**\h\w*\)\s*(\s*)', '\1(void)', '')
    if l:n ==# l:t
        return 0
    endif
    call setline(a:lnum, l:n)
    return 1
endfunction

" [code, comment, multiline] for the first comment on a line (strings are skipped)
function! s:CommentSplit(t) abort
    let l:i = 0
    let l:n = len(a:t)
    while l:i < l:n
        let l:c = a:t[l:i]
        let l:d = l:i + 1 < l:n ? a:t[l:i + 1] : ''
        if l:c ==# '"' || l:c ==# "'"
            let l:q = l:c
            let l:i += 1
            while l:i < l:n && a:t[l:i] !=# l:q
                if a:t[l:i] ==# '\'
                    let l:i += 1
                endif
                let l:i += 1
            endwhile
        elseif l:c ==# '/' && l:d ==# '/'
            return [strpart(a:t, 0, l:i), strpart(a:t, l:i), 0]
        elseif l:c ==# '/' && l:d ==# '*'
            let l:e = stridx(a:t, '*/', l:i + 2)
            if l:e >= 0
                return [strpart(a:t, 0, l:i) . strpart(a:t, l:e + 2), strpart(a:t, l:i, l:e + 2 - l:i), 0]
            endif
            return [strpart(a:t, 0, l:i), strpart(a:t, l:i), 1]
        endif
        let l:i += 1
    endwhile
    return [a:t, '', 0]
endfunction

" comments are not allowed inside a function: move them above the function
function! s:FixComment(lnum) abort
    let l:fr = s:FuncRange(a:lnum)
    if empty(l:fr) || l:fr[0] < 2
        return 0
    endif
    let l:cs = s:CommentSplit(getline(a:lnum))
    if empty(l:cs[1])
        return 0
    endif
    let l:code = substitute(l:cs[0], '\s\+$', '', '')
    let l:last = a:lnum
    if l:cs[2]
        let l:cm = [l:cs[1]]
        while l:last < l:fr[1]
            let l:last += 1
            call add(l:cm, substitute(getline(l:last), '^\s*', ' ', ''))
            if getline(l:last) =~# '\*/'
                break
            endif
        endwhile
        if getline(l:last) !~# '\*/\s*$'
            return 0
        endif
    elseif l:cs[1] =~# '^//'
        let l:cm = ['/* ' . trim(strpart(l:cs[1], 2)) . ' */']
    else
        let l:cm = [l:cs[1]]
    endif
    let l:k = l:last
    while l:k > a:lnum
        call s:Del(l:k)
        let l:k -= 1
    endwhile
    if empty(trim(l:code))
        call s:Del(a:lnum)
    else
        call setline(a:lnum, l:code)
    endif
    call s:Ins(l:fr[0] - 2, l:cm)
    return 1
endfunction

" a line inside open parentheses (call/condition continued from the line above)
" is indented one tab deeper than the line where the statement started
function! s:FixContIndent(lnum) abort
    let l:fr = s:FuncRange(a:lnum)
    if empty(l:fr) || a:lnum <= l:fr[0]
        return 0
    endif
    let l:pd = 0
    let l:start = 0
    for l:n in range(l:fr[0] + 1, a:lnum - 1)
        let l:m = s:Mask(getline(l:n))
        if l:pd == 0 && l:m =~# '\S'
            let l:start = l:n
        endif
        for l:c in split(l:m, '\zs')
            if l:c ==# '('
                let l:pd += 1
            elseif l:c ==# ')'
                let l:pd = max([l:pd - 1, 0])
            endif
        endfor
    endfor
    if l:pd == 0 || !l:start
        return 0
    endif
    let l:t = getline(a:lnum)
    let l:new = matchstr(getline(l:start), '^\t*') . "\t" . substitute(l:t, '^\s*', '', '')
    if l:new ==# l:t
        return 0
    endif
    call setline(a:lnum, l:new)
    return 1
endfunction

" line of the } matching the { that opens on line a:n
function! s:BraceEnd(n) abort
    let l:d = 0
    for l:k in range(a:n, line('$'))
        let l:m = s:Mask(getline(l:k))
        let l:d += len(substitute(l:m, '[^{]', '', 'g')) - len(substitute(l:m, '[^}]', '', 'g'))
        if l:d <= 0
            return l:k
        endif
    endfor
    return -1
endfunction

" extend the end line a:e of an if-statement over a following else / else if chain
function! s:ElseEnd(e) abort
    let l:nx = a:e + 1
    if l:nx > line('$')
        return a:e
    endif
    let l:s = trim(s:Mask(getline(l:nx)))
    if l:s =~# '^else\s*$'
        return s:StmtEnd(l:nx + 1)
    elseif l:s =~# '^else\s\+if\s*('
        return s:StmtEnd(l:nx)
    elseif l:s =~# '^else\>'
        return l:nx
    endif
    return a:e
endfunction

" last line of the statement that starts on line a:n (-1 if unsure)
function! s:StmtEnd(n) abort
    if a:n > line('$')
        return -1
    endif
    let l:m = s:Mask(getline(a:n))
    let l:s = trim(l:m)
    if l:s ==# '{'
        return s:BraceEnd(a:n)
    endif
    if l:s =~# '^\%(if\|while\|for\|else\s\+if\)\s*('
        let l:cl = s:MatchParen(l:m, match(l:m, '('))
        if l:cl < 0
            return -1
        endif
        let l:e = empty(trim(strpart(l:m, l:cl + 1))) ? s:StmtEnd(a:n + 1) : a:n
        if l:e < 0
            return -1
        endif
        return l:s =~# '^\%(if\|else\s\+if\)' ? s:ElseEnd(l:e) : l:e
    endif
    if l:s =~# '^else\s*$'
        return s:StmtEnd(a:n + 1)
    endif
    let l:d = 0
    for l:k in range(a:n, line('$'))
        for l:c in split(s:Mask(getline(l:k)), '\zs')
            if l:c =~# '[([{]'
                let l:d += 1
            elseif l:c =~# '[)\]}]'
                let l:d -= 1
            elseif l:c ==# ';' && l:d <= 0
                return l:k
            endif
        endfor
    endfor
    return -1
endfunction

" for (init; cond; inc) body   ->   init; while (cond) { body inc; }
function! s:FixFor(lnum) abort
    let l:t = getline(a:lnum)
    let l:m = s:Mask(l:t)
    let l:mm = matchlist(l:m, '^\(\s*\)for\s*(')
    if empty(l:mm)
        return 0
    endif
    let l:ind = l:mm[1]
    let l:op = match(l:m, '(')
    let l:cl = s:MatchParen(l:m, l:op)
    if l:cl < 0 || !empty(trim(strpart(l:m, l:cl + 1)))
        return 0
    endif
    let l:hdr = strpart(l:t, l:op + 1, l:cl - l:op - 1)
    let l:parts = s:SplitTop(l:hdr, strpart(l:m, l:op + 1, l:cl - l:op - 1), ';')
    if len(l:parts) != 3
        return 0
    endif
    let l:init = trim(l:parts[0])
    let l:cond = trim(l:parts[1])
    let l:inc  = trim(l:parts[2])
    let l:end = s:StmtEnd(a:lnum + 1)
    if l:end < 0
        return 0
    endif
    for l:k in range(a:lnum + 1, l:end)
        if s:Mask(getline(l:k)) =~# '\<continue\>'
            return 0
        endif
    endfor
    let l:braced = trim(s:Mask(getline(a:lnum + 1))) ==# '{'
    let l:inits = []
    if !empty(l:init)
        let l:pd = s:ParseDecl(l:ind . l:init . ';')
        if !empty(l:pd)
            for l:x in l:pd.decls
                call add(l:inits, l:ind . l:pd.type . "\t" . l:x.stars . l:x.name . l:x.arr
                    \ . (empty(l:x.init) ? '' : ' = ' . l:x.init) . ';')
            endfor
        else
            for l:p in s:SplitTop(l:init, s:Mask(l:init), ',')
                call add(l:inits, l:ind . trim(l:p) . ';')
            endfor
        endif
    endif
    let l:incs = []
    if !empty(l:inc)
        for l:p in s:SplitTop(l:inc, s:Mask(l:inc), ',')
            call add(l:incs, l:ind . "\t" . trim(l:p) . ';')
        endfor
    endif
    if l:braced
        call s:Ins(l:end - 1, l:incs)
    else
        call s:Ins(l:end, l:incs + [l:ind . '}'])
        call s:Ins(a:lnum, [l:ind . '{'])
    endif
    call setline(a:lnum, l:ind . 'while (' . (empty(l:cond) ? '1' : l:cond) . ')')
    call s:Ins(a:lnum - 1, l:inits)
    return 1
endfunction

" [cond, a, b] of  cond ? a : b  (exactly one ternary, no nesting) or []
function! s:TernaryParts(ex, exm) abort
    if len(substitute(a:exm, '[^?]', '', 'g')) != 1
        return []
    endif
    let l:q = s:TopPos(a:exm, '?')
    let l:c = s:TopPos(a:exm, ':')
    if len(l:q) != 1 || len(l:c) != 1 || l:c[0] < l:q[0]
        return []
    endif
    let l:cond = trim(strpart(a:ex, 0, l:q[0]))
    let l:a = trim(strpart(a:ex, l:q[0] + 1, l:c[0] - l:q[0] - 1))
    let l:b = trim(strpart(a:ex, l:c[0] + 1))
    if empty(l:cond) || empty(l:a) || empty(l:b)
        return []
    endif
    return [l:cond, l:a, l:b]
endfunction

" first assignment operator at depth 0 (= += -= *= /= %= &= |= ^= <<= >>=): [start, length] or []
function! s:AssignOp(sm) abort
    let l:d = 0
    for l:k in range(len(a:sm))
        let l:c = a:sm[l:k]
        if l:c =~# '[([{]'
            let l:d += 1
        elseif l:c =~# '[)\]}]'
            let l:d -= 1
        elseif l:c ==# '=' && l:d == 0
            let l:n = l:k + 1 < len(a:sm) ? a:sm[l:k + 1] : ''
            let l:p = l:k > 0 ? a:sm[l:k - 1] : ''
            if l:n ==# '=' || l:p =~# '[=!]'
                continue
            endif
            if l:k >= 2 && strpart(a:sm, l:k - 2, 2) =~# '^\%(<<\|>>\)$'
                return [l:k - 2, 3]
            elseif l:p =~# '[-+*/%&|^]'
                return [l:k - 1, 2]
            elseif l:p =~# '[<>]'
                continue
            endif
            return [l:k, 1]
        endif
    endfor
    return []
endfunction

" x = c ? a : b;  /  return (c ? a : b);   ->   if / else
function! s:FixTernary(lnum) abort
    let l:t = getline(a:lnum)
    let l:m = s:Mask(l:t)
    let l:mm = matchlist(l:m, '^\(\s*\)\(.\{-}\)\s*;\s*$')
    if empty(l:mm) || l:m !~# '?' || !empty(s:ParseDecl(l:t))
        return 0
    endif
    let l:ind = l:mm[1]
    let l:sm = l:mm[2]
    let l:st = strpart(l:t, len(l:ind), len(l:sm))
    " a brace-less if/else/while body: wrapping it in an if would change the meaning
    let l:pv = a:lnum - 1
    while l:pv > 1 && getline(l:pv) =~# '^\s*$'
        let l:pv -= 1
    endwhile
    let l:ps = trim(s:Mask(getline(l:pv)))
    if l:ps =~# '^\%(if\|while\|for\|else\)\>' && l:ps !~# '{\s*$' && (l:ps =~# ')\s*$' || l:ps =~# '^else\s*$')
        return 0
    endif
    let l:off = match(l:sm, '^return\s*\zs.*')
    if l:off >= 0
        let l:ex = strpart(l:st, l:off)
        let l:exm = strpart(l:sm, l:off)
        if len(l:ex) > 1 && l:ex[0] ==# '(' && s:MatchParen(l:exm, 0) == len(l:ex) - 1
            let l:ex = strpart(l:ex, 1, len(l:ex) - 2)
            let l:exm = strpart(l:exm, 1, len(l:exm) - 2)
        endif
        let l:p = s:TernaryParts(l:ex, l:exm)
        if empty(l:p)
            return 0
        endif
        call setline(a:lnum, l:ind . 'if (' . l:p[0] . ')')
        call s:Ins(a:lnum, [l:ind . "\treturn (" . l:p[1] . ');', l:ind . 'return (' . l:p[2] . ');'])
        return 1
    endif
    let l:ap = s:AssignOp(l:sm)
    if empty(l:ap)
        return 0
    endif
    let l:lhs = trim(strpart(l:st, 0, l:ap[0]))
    let l:op = strpart(l:st, l:ap[0], l:ap[1])
    if empty(l:lhs) || l:lhs =~# '[(?]'
        return 0
    endif
    let l:ex = trim(strpart(l:st, l:ap[0] + l:ap[1]))
    let l:exm = trim(strpart(l:sm, l:ap[0] + l:ap[1]))
    if len(l:ex) > 1 && l:ex[0] ==# '(' && s:MatchParen(l:exm, 0) == len(l:ex) - 1
        let l:ex = strpart(l:ex, 1, len(l:ex) - 2)
        let l:exm = strpart(l:exm, 1, len(l:exm) - 2)
    endif
    let l:p = s:TernaryParts(l:ex, l:exm)
    if empty(l:p)
        return 0
    endif
    call setline(a:lnum, l:ind . 'if (' . l:p[0] . ')')
    call s:Ins(a:lnum, [l:ind . "\t" . l:lhs . ' ' . l:op . ' ' . l:p[1] . ';', l:ind . 'else',
        \ l:ind . "\t" . l:lhs . ' ' . l:op . ' ' . l:p[2] . ';'])
    return 1
endfunction

" add a piece to a split line; a control header followed by a statement becomes two pieces
function! s:PushPiece(pcs, seg, depth) abort
    let l:s = trim(a:seg)
    if empty(l:s)
        return
    endif
    let l:ms = s:Mask(l:s)
    if l:ms =~# '^\%(else\s\+\)\?\%(if\|while\|for\)\s*('
        let l:cl = s:MatchParen(l:ms, match(l:ms, '('))
        if l:cl >= 0 && !empty(trim(strpart(l:ms, l:cl + 1)))
            call add(a:pcs, [a:depth, trim(strpart(l:s, 0, l:cl + 1))])
            call add(a:pcs, [a:depth + 1, trim(strpart(l:s, l:cl + 1))])
            return
        endif
    elseif l:ms =~# '^else\s\+\S' && l:ms !~# '^else\s\+if\>'
        call add(a:pcs, [a:depth, 'else'])
        call add(a:pcs, [a:depth + 1, trim(strpart(l:s, 4))])
        return
    endif
    call add(a:pcs, [a:depth, l:s])
endfunction

" several instructions / braces / a control body on one line  ->  one per line
function! s:FixSplit(lnum) abort
    let l:t = getline(a:lnum)
    let l:m = s:Mask(l:t)
    if l:t =~# '^\s*#' || l:m =~# '\<\%(case\|switch\|goto\|do\|default\)\>'
        return 0
    endif
    if l:m =~# '=\s*{' || (l:m =~# '}\s*[;A-Za-z_]' && l:m !~# '}\s*else\>')
        return 0
    endif
    let l:ind = len(matchstr(l:t, '^\t*'))
    let l:pcs = []
    let l:depth = 0
    let l:pd = 0
    let l:seg = ''
    for l:k in range(len(l:t))
        let l:mc = l:m[l:k]
        let l:oc = l:t[l:k]
        if l:mc ==# '(' || l:mc ==# '['
            let l:pd += 1
            let l:seg .= l:oc
        elseif l:mc ==# ')' || l:mc ==# ']'
            let l:pd -= 1
            let l:seg .= l:oc
        elseif l:mc ==# '{' && l:pd == 0
            call s:PushPiece(l:pcs, l:seg, l:depth)
            let l:seg = ''
            call add(l:pcs, [l:depth, '{'])
            let l:depth += 1
        elseif l:mc ==# '}' && l:pd == 0
            call s:PushPiece(l:pcs, l:seg, l:depth)
            let l:seg = ''
            let l:depth = max([l:depth - 1, 0])
            call add(l:pcs, [l:depth, '}'])
        elseif l:mc ==# ';' && l:pd == 0
            call s:PushPiece(l:pcs, l:seg . ';', l:depth)
            let l:seg = ''
        else
            let l:seg .= l:oc
        endif
    endfor
    call s:PushPiece(l:pcs, l:seg, l:depth)
    if len(l:pcs) < 2
        return 0
    endif
    let l:lines = []
    for l:p in l:pcs
        call add(l:lines, repeat("\t", l:ind + l:p[0]) . l:p[1])
    endfor
    call setline(a:lnum, l:lines[0])
    call s:Ins(a:lnum, l:lines[1:])
    return 1
endfunction

" run norminette on the buffer text -> list of {code, lnum, col, msg};
" -1 when it cannot judge (parse error).  The result is cached per buffer text.
function! s:NormErrors() abort
    let l:lines = getline(1, '$')
    let l:sum = sha256(join(l:lines, "\n"))
    if get(b:, 'norm_cache_sum', '') ==# l:sum
        return b:norm_cache_errs
    endif
    let l:dir = fnamemodify(tempname(), ':h') . '/vimnorm'
    call mkdir(l:dir, 'p')
    let l:f = l:dir . '/' . expand('%:t')
    call writefile(l:lines, l:f)
    let l:out = systemlist('timeout 10 norminette ' . shellescape(l:f) . ' 2>&1')
    call delete(l:f)
    let l:errs = []
    for l:ln in l:out
        let l:ln = substitute(l:ln, "\e\\[[0-9;]*m", '', 'g')
        let l:m = matchlist(l:ln, '^Error:\s*\(\w\+\)\s*(line:\s*\(\d\+\),\s*col:\s*\(\d\+\)):\s*\(.*\)$')
        if !empty(l:m)
            if l:m[1] ==# 'PARSING_ERROR'
                return -1
            endif
            call add(l:errs, {'code': l:m[1], 'lnum': str2nr(l:m[2]), 'col': str2nr(l:m[3]), 'msg': l:m[4]})
        elseif l:ln =~# 'PARSING_ERROR'
            return -1
        endif
    endfor
    let b:norm_cache_sum = l:sum
    let b:norm_cache_errs = l:errs
    return l:errs
endfunction

" apply the rewrites for the flagged lines; 1 if the text changed
function! s:ApplyFixers(errs) abort
    let l:order = ['WRONG_SCOPE_COMMENT', 'FORBIDDEN_CS', 'TERNARY_FBIDDEN', 'MULT_DECL_LINE',
        \ 'MULT_ASSIGN_LINE', 'DECL_ASSIGN_LINE', 'VAR_DECL_START_FUNC', 'TOO_MANY_INSTR',
        \ 'MULT_IN_SINGLE_INSTR', 'BRACE_SHOULD_EOL', 'EXP_NEWLINE', 'BRACE_NEWLINE',
        \ 'RETURN_PARENTHESIS', 'NO_ARGS_VOID', 'TOO_MANY_TAB', 'TOO_FEW_TAB']
    let l:fn = {
        \ 'WRONG_SCOPE_COMMENT': function('s:FixComment'),
        \ 'FORBIDDEN_CS': function('s:FixFor'),
        \ 'TERNARY_FBIDDEN': function('s:FixTernary'),
        \ 'MULT_DECL_LINE': function('s:FixMultDecl'),
        \ 'MULT_ASSIGN_LINE': function('s:FixMultAssign'),
        \ 'DECL_ASSIGN_LINE': function('s:FixDeclAssign'),
        \ 'VAR_DECL_START_FUNC': function('s:FixDeclLate'),
        \ 'TOO_MANY_INSTR': function('s:FixSplit'),
        \ 'MULT_IN_SINGLE_INSTR': function('s:FixSplit'),
        \ 'BRACE_SHOULD_EOL': function('s:FixSplit'),
        \ 'EXP_NEWLINE': function('s:FixSplit'),
        \ 'BRACE_NEWLINE': function('s:FixSplit'),
        \ 'RETURN_PARENTHESIS': function('s:FixReturn'),
        \ 'NO_ARGS_VOID': function('s:FixNoArgs'),
        \ 'TOO_MANY_TAB': function('s:FixContIndent'),
        \ 'TOO_FEW_TAB': function('s:FixContIndent'),
        \ }
    let l:byline = {}
    for l:e in a:errs
        if has_key(l:fn, l:e.code)
            if !has_key(l:byline, l:e.lnum)
                let l:byline[l:e.lnum] = []
            endif
            call add(l:byline[l:e.lnum], l:e.code)
        endif
    endfor
    let s:norm_todo = []
    for l:k in keys(l:byline)
        call add(s:norm_todo, [str2nr(l:k), l:byline[l:k]])
    endfor
    let l:changed = 0
    while !empty(s:norm_todo)
        call sort(s:norm_todo, {x, y -> x[0] - y[0]})
        let l:it = remove(s:norm_todo, 0)
        for l:code in l:order
            if index(l:it[1], l:code) < 0
                continue
            endif
            let l:Fn = l:fn[l:code]
            if l:Fn(l:it[0])
                let l:changed = 1
                break
            endif
        endfor
    endwhile
    if s:NormalizeDecls()
        let l:changed = 1
    endif
    return l:changed
endfunction

function! s:NormDeep() abort
    let l:t0 = reltime()
    let l:errs = s:NormErrors()
    if type(l:errs) != v:t_list || empty(l:errs)
        return
    endif
    let l:n0 = len(l:errs)
    let l:best = getline(1, '$')
    let l:bestn = l:n0
    for l:r in range(5)
        if reltimefloat(reltime(l:t0)) > 8
            break
        endif
        if !s:ApplyFixers(l:errs)
            break
        endif
        call s:NormLayout()
        let l:new = s:NormErrors()
        if type(l:new) != v:t_list || len(l:new) > l:bestn
            call s:SetLines(l:best)
            break
        endif
        let l:same = getline(1, '$') ==# l:best
        let l:best = getline(1, '$')
        let l:bestn = len(l:new)
        let l:errs = l:new
        if empty(l:errs) || l:same
            break
        endif
    endfor
    if l:bestn < l:n0
        echo 'Norm auto-fix: ' . (l:n0 - l:bestn) . ' fixed, ' . l:bestn . ' left'
    elseif l:bestn > 0
        echo 'Norm: ' . l:bestn . ' error(s) left  (Space n lists them)'
    endif
endfunction

command! NormDeepToggle let g:norm_deep = !g:norm_deep
    \ | echo 'Norm deep fix on save: ' . (g:norm_deep ? 'on' : 'off')

" 1 = the buffer text compiles (gcc -fsyntax-only), 0 = it does not, -1 = cannot tell
function! s:CompileOk(lines) abort
    if expand('%:e') !=# 'c' || !executable('gcc')
        return -1
    endif
    let l:dir = fnamemodify(tempname(), ':h') . '/vimnorm'
    call mkdir(l:dir, 'p')
    let l:f = l:dir . '/chk_' . expand('%:t')
    call writefile(a:lines, l:f)
    let l:src = expand('%:p:h')
    call system('timeout 10 gcc -fsyntax-only -w -I' . shellescape(l:src) . ' -I' . shellescape(l:src . '/..')
        \ . ' -I' . shellescape(l:src . '/include') . ' -I' . shellescape(l:src . '/includes') . ' '
        \ . shellescape(l:f) . ' 2>&1')
    let l:rc = v:shell_error
    call delete(l:f)
    return l:rc == 0 ? 1 : 0
endfunction

" Normalise declarations inside functions BEFORE any formatter sees them
" (c_formatter_42 mangles "int a = 1, b = 2;" and duplicates re-declared names):
" one declaration per line, no initialiser, all at the top of the function.
function! s:NormalizeDecls() abort
    if line('$') > 3000
        return 0
    endif
    let s:norm_todo = []
    let l:changed = 0
    let l:guard = 0
    while l:guard < 300
        let l:guard += 1
        let l:hit = 0
        for l:n in range(line('$'), 1, -1)
            let l:t = getline(l:n)
            if l:t !~# '^\s\+\S' || l:t !~# ';\s*$'
                continue
            endif
            let l:d = s:ParseDecl(l:t)
            if empty(l:d) || empty(s:FuncRange(l:n))
                continue
            endif
            if len(l:d.decls) > 1
                let l:hit = s:FixMultDecl(l:n)
            elseif !empty(l:d.decls[0].init)
                let l:hit = s:FixDeclAssign(l:n)
            else
                let l:hit = s:FixDeclLate(l:n)
            endif
            if l:hit
                break
            endif
        endfor
        if !l:hit
            break
        endif
        let l:changed = 1
    endwhile
    return l:changed
endfunction

" the save-time fix: layout (c_formatter_42 / built-in), then the deep fix.
" If the text compiled before and does not after, everything is reverted.
function! Fix42Norm() abort
    let l:view = winsaveview()
    let l:orig = getline(1, '$')
    let l:deep = g:norm_deep && executable('norminette') && expand('%:e') =~# '^[ch]$'
    let l:c0 = l:deep ? s:CompileOk(l:orig) : -1
    if l:deep
        call s:NormalizeDecls()
    endif
    call s:NormLayout()
    if l:deep
        call s:NormDeep()
    endif
    if l:c0 == 1 && g:norm_compile_guard && s:CompileOk(getline(1, '$')) == 0
        call s:SetLines(l:orig)
        echo 'Norm auto-fix reverted: it would have broken the compilation (fix by hand, Space n)'
    endif
    call winrestview(l:view)
endfunction

"  <leader>x : fix everything we can now, save, and re-check with norminette
function! s:NormFixNow() abort
    if expand('%:e') !~# '^[ch]$'
        echo 'Norm fix: only for .c / .h files'
        return
    endif
    call Fix42Norm()
    let g:norm_just_fixed = 1
    silent write
    let g:norm_just_fixed = 0
    call s:NormCheck(0)
    echo 'Norm auto-fix done  ' . get(b:, 'norm_state', '')
        \ . (executable('c_formatter_42') ? '' : '   (tip: pip3 install --user c-formatter-42 fixes more)')
    if get(b:, 'norm_state', '') =~# 'err'
        copen
        wincmd p
    endif
endfunction
nnoremap <silent> <leader>x :call <SID>NormFixNow()<CR>

function! s:NormLayout() abort
    let l:view = winsaveview()
    let l:start = 1
    if getline(1) =~# '^/\* \*'
        let l:start = 12
        if line('$') >= 11 && getline(12) !~# '^\s*$'
            call append(11, '')
        endif
    endif

    " 1) the real formatter when available, 2) built-in fixes otherwise
    let l:done = 0
    if g:norm_use_c_formatter && executable('c_formatter_42')
        let l:done = s:RunCFormatter()
    endif
    if !l:done
        call s:FixLeadingSpaces(l:start)
        call s:FixPreproc(l:start)
        call s:FixSpacing(l:start)
    endif

    execute 'keeppatterns silent! ' . l:start . ',$s/\<void(\s*\(\h\w*\)\s*);/(void)\1;/ge'
    if g:norm_strip_line_comments
        execute 'keeppatterns silent! ' . l:start . ',$g/^\s*\/\//d _'
        execute 'keeppatterns silent! ' . l:start . ',$g/^[^"'']*\/\//s/\s*\/\/.*$//e'
    endif
    execute 'keeppatterns silent! ' . l:start . ',$s/[ \t]\+$//e'

    call s:FixBlankAfter(l:start)
    call s:FixBraceSpacing(l:start)
    call s:FixFuncBlanks(l:start)
    call s:FixVarSpacing(l:start)
    call s:FixFuncAlign(l:start)
    call s:FixDeclAlign(l:start)

    " collapse consecutive blank lines (bottom-up) and drop trailing ones
    let l:i = line('$')
    while l:i > l:start
        if getline(l:i) =~# '^\s*$' && getline(l:i - 1) =~# '^\s*$'
            execute l:i . 'delete _'
        endif
        let l:i -= 1
    endwhile
    while line('$') > l:start && getline('$') =~# '^\s*$'
        silent $delete _
    endwhile

    call winrestview(l:view)
endfunction

augroup Norm42Format
    autocmd!
    autocmd BufWritePre *.c,*.h if g:norm_autofix && !get(g:, 'autosaving', 0) && !get(g:, 'norm_just_fixed', 0) | call Fix42Norm() | endif
augroup END

" ----------------------------------------------------------------------------
" Signs: norminette errors + git diff markers
" ----------------------------------------------------------------------------
call sign_define([
    \ {'name': 'NormError', 'text': '>>', 'texthl': 'NormSign'},
    \ {'name': 'GitAdd',    'text': '│',  'texthl': 'GitAdd'},
    \ {'name': 'GitChange', 'text': '│',  'texthl': 'GitChange'},
    \ {'name': 'GitDelete', 'text': '_',  'texthl': 'GitDelete'},
    \ ])

function! s:GitSignsRefresh() abort
    let l:buf = bufnr('%')
    call sign_unplace('GitSigns', {'buffer': l:buf})
    if &buftype !=# '' || expand('%') ==# '' || get(b:, 'gitsigns_off', 0)
        return
    endif
    let l:file = expand('%:p')
    let l:diff = systemlist('git -C ' . shellescape(fnamemodify(l:file, ':h'))
        \ . ' diff HEAD -U0 --no-color -- ' . shellescape(l:file) . ' 2>/dev/null')
    if v:shell_error
        return
    endif
    for l:line in l:diff
        let l:m = matchlist(l:line, '^@@ -\d\+\%(,\(\d\+\)\)\? +\(\d\+\)\%(,\(\d\+\)\)\? @@')
        if empty(l:m)
            continue
        endif
        let l:old   = l:m[1] ==# '' ? 1 : str2nr(l:m[1])
        let l:start = str2nr(l:m[2])
        let l:new   = l:m[3] ==# '' ? 1 : str2nr(l:m[3])
        if l:new == 0
            call sign_place(0, 'GitSigns', 'GitDelete', l:buf, {'lnum': max([l:start, 1])})
        else
            let l:name = l:old == 0 ? 'GitAdd' : 'GitChange'
            for l:n in range(l:start, l:start + l:new - 1)
                call sign_place(0, 'GitSigns', l:name, l:buf, {'lnum': l:n})
            endfor
        endif
    endfor
endfunction

function! s:GitSignsToggle() abort
    let b:gitsigns_off = !get(b:, 'gitsigns_off', 0)
    call s:GitSignsRefresh()
    echo 'Git signs: ' . (b:gitsigns_off ? 'off' : 'on')
endfunction

function! s:NormCheck(open) abort
    if expand('%:e') !~# '^[ch]$'
        return
    endif
    if !executable('norminette')
        let b:norm_state = ''
        if a:open | echo 'Norminette: not found' | endif
        return
    endif
    let l:buf  = bufnr('%')
    let l:file = expand('%:p')
    let l:errs = s:NormErrors()
    call sign_unplace('NormSigns', {'buffer': l:buf})
    if type(l:errs) != v:t_list
        let b:norm_state = '[norm:parse error]'
        redrawstatus!
        return
    endif
    let l:qf = []
    for l:e in l:errs
        call add(l:qf, {'filename': l:file, 'lnum': l:e.lnum, 'col': l:e.col,
            \ 'text': l:e.code . ': ' . l:e.msg . get(s:norm_hint, l:e.code, ''), 'type': 'E'})
        call sign_place(0, 'NormSigns', 'NormError', l:buf, {'lnum': l:e.lnum, 'priority': 20})
    endfor
    call setqflist([], 'r', {'title': 'norminette', 'items': l:qf})
    let b:norm_state = empty(l:qf) ? '[norm:ok]' : '[norm:' . len(l:qf) . ' err]'
    if a:open && !empty(l:qf)
        copen
        wincmd p
    elseif empty(l:qf)
        silent! cclose
    endif
    redrawstatus!
endfunction

nnoremap <silent> <leader>n :call <SID>NormCheck(1)<CR>
nnoremap <silent> <leader>g :call <SID>GitSignsToggle()<CR>
command! NormCheck call s:NormCheck(1)
command! GitSigns  call s:GitSignsToggle()

augroup Signs
    autocmd!
    autocmd BufReadPost,BufWritePost * call s:GitSignsRefresh()
    autocmd BufReadPost,BufWritePost *.c,*.h call s:NormCheck(0)
augroup END

" ----------------------------------------------------------------------------
" Norm line warnings (live, no norminette needed), in .c / .h files:
"   80  in the sign column + red tail  -> line is wider than 80 columns (tab = 4)
"   >4  in the sign column + shaded    -> function has more than 4 parameters
" ----------------------------------------------------------------------------
call sign_define([
    \ {'name': 'NormLong',   'text': '80', 'texthl': 'NormWarn'},
    \ {'name': 'NormParams', 'text': '>4', 'texthl': 'NormWarn', 'linehl': 'NormWarnLine'},
    \ {'name': 'NormForbid', 'text': '!!', 'texthl': 'NormSign'},
    \ ])

" number of parameters of a prototype / definition line (0 if it is not one)
function! s:ParamCount(line) abort
    let l:m = matchlist(a:line, '^\h[^(]*\t\+\**\h\w*(\(.*\))\s*;\?\s*$')
    if empty(l:m)
        return 0
    endif
    let l:in = trim(l:m[1])
    if l:in ==# '' || l:in ==# 'void'
        return 0
    endif
    let l:d = 0
    let l:c = 1
    for l:ch in split(l:in, '\zs')
        if l:ch ==# '('
            let l:d += 1
        elseif l:ch ==# ')'
            let l:d -= 1
        elseif l:ch ==# ',' && l:d == 0
            let l:c += 1
        endif
    endfor
    return l:c
endfunction

" copy of a line where "strings", 'c' and comments are blanked out (same byte length).
" a:inc = 1 when the line starts inside a /* block comment */. Returns [masked, inc].
function! s:MaskLine(t, inc) abort
    let l:o = ''
    let l:i = 0
    let l:n = len(a:t)
    let l:inc = a:inc
    while l:i < l:n
        let l:c = a:t[l:i]
        let l:d = l:i + 1 < l:n ? a:t[l:i + 1] : ''
        if l:inc
            if l:c ==# '*' && l:d ==# '/'
                let l:inc = 0
                let l:o .= '  '
                let l:i += 2
            else
                let l:o .= ' '
                let l:i += 1
            endif
        elseif l:c ==# '/' && l:d ==# '*'
            let l:inc = 1
            let l:o .= '  '
            let l:i += 2
        elseif l:c ==# '/' && l:d ==# '/'
            let l:o .= repeat(' ', l:n - l:i)
            break
        elseif l:c ==# '"' || l:c ==# "'"
            let l:q = l:c
            let l:o .= ' '
            let l:i += 1
            while l:i < l:n && a:t[l:i] !=# l:q
                if a:t[l:i] ==# '\' && l:i + 1 < l:n
                    let l:o .= ' '
                    let l:i += 1
                endif
                let l:o .= ' '
                let l:i += 1
            endwhile
            if l:i < l:n
                let l:o .= ' '
                let l:i += 1
            endif
        else
            let l:o .= l:c
            let l:i += 1
        endif
    endwhile
    return [l:o, l:inc]
endfunction

" constructs the Norm forbids:  for  do  switch  case  goto  and the ternary ?
let s:forbid_pat = '\<\%(for\|do\|switch\|case\|goto\)\>\|?'

function! s:NormLint() abort
    if &buftype !=# '' || expand('%:e') !~# '^[ch]$' || line('$') > 5000
        return
    endif
    let l:buf = bufnr('%')
    call sign_unplace('NormLint', {'buffer': l:buf})
    for l:id in get(w:, 'norm_forbid', [])
        silent! call matchdelete(l:id)
    endfor
    let w:norm_forbid = []
    let l:pos = []
    let l:inc = 0
    let l:n = 0
    for l:line in getline(1, '$')
        let l:n += 1
        if strdisplaywidth(l:line) > 80
            call sign_place(0, 'NormLint', 'NormLong', l:buf, {'lnum': l:n, 'priority': 15})
        endif
        if s:ParamCount(l:line) > 4
            call sign_place(0, 'NormLint', 'NormParams', l:buf, {'lnum': l:n, 'priority': 16})
        endif
        if l:line !~# '^\s*#' && l:line =~# s:forbid_pat
            let [l:m, l:inc] = s:MaskLine(l:line, l:inc)
            let l:s = 0
            let l:hit = 0
            while len(l:pos) < 200
                let l:p = matchstrpos(l:m, s:forbid_pat, l:s)
                if l:p[1] < 0
                    break
                endif
                call add(l:pos, [l:n, l:p[1] + 1, l:p[2] - l:p[1]])
                let l:hit = 1
                let l:s = l:p[2]
            endwhile
            if l:hit
                call sign_place(0, 'NormLint', 'NormForbid', l:buf, {'lnum': l:n, 'priority': 17})
            endif
        else
            " keep track of /* ... */ blocks without scanning the line
            let l:ri = strridx(l:line, '/*')
            let l:rc = strridx(l:line, '*/')
            if l:inc
                if l:rc >= 0
                    let l:inc = l:ri > l:rc
                endif
            elseif l:ri > l:rc
                let l:inc = 1
            endif
        endif
    endfor
    let l:i = 0
    while l:i < len(l:pos)
        call add(w:norm_forbid, matchaddpos('NormForbidHl', l:pos[l:i : l:i + 7], 20))
        let l:i += 8
    endwhile
endfunction

" red highlight on everything past column 80 (per window)
function! s:NormMatch() abort
    if exists('w:norm_long')
        silent! call matchdelete(w:norm_long)
        unlet w:norm_long
    endif
    if &buftype ==# '' && expand('%:e') =~# '^[ch]$'
        let w:norm_long = matchadd('NormLong', '\%>80v.\+', 10)
    else
        for l:id in get(w:, 'norm_forbid', [])
            silent! call matchdelete(l:id)
        endfor
        let w:norm_forbid = []
    endif
endfunction

augroup NormLint
    autocmd!
    autocmd BufEnter,BufReadPost,BufWritePost,TextChanged,InsertLeave *.c,*.h call s:NormLint()
    autocmd BufEnter,BufWinEnter,WinEnter,FileType * call s:NormMatch()
augroup END

" ----------------------------------------------------------------------------
" Stats logging (consumed by ~/.local/bin/dev-stats and my-stats)
" ----------------------------------------------------------------------------
let g:stats_log = expand('~/.local/state/dev-stats/events.log')
let g:stats_start_epoch = 0
let g:stats_start_ts = ''
let g:stats_insert_seconds = 0
let g:stats_mode_since = 0

function! s:StatsLog(kind, data) abort
    try
        call mkdir(fnamemodify(g:stats_log, ':h'), 'p')
        call writefile([json_encode({'t': strftime('%Y-%m-%dT%H:%M:%S%z'),
            \ 'kind': a:kind, 'data': a:data})], g:stats_log, 'a')
    catch
    endtry
endfunction

function! s:StatsFile(kind) abort
    let l:p = expand('<afile>:p')
    call s:StatsLog(a:kind, {'path': l:p, 'name': fnamemodify(l:p, ':t'), 'size': getfsize(l:p)})
endfunction

function! s:StatsModeEnter() abort
    let g:stats_mode_since = localtime()
endfunction

function! s:StatsModeLeave() abort
    if g:stats_mode_since > 0
        let g:stats_insert_seconds += localtime() - g:stats_mode_since
        let g:stats_mode_since = 0
    endif
endfunction

function! s:StatsSessionStart() abort
    let g:stats_start_epoch = localtime()
    let g:stats_start_ts = strftime('%Y-%m-%dT%H:%M:%S%z', g:stats_start_epoch)
    let g:stats_insert_seconds = 0
    let g:stats_mode_since = 0
    call s:StatsLog('vim_open', {'cwd': getcwd(), 'cwd_is_home': getcwd() ==# $HOME,
        \ 'vim_version': v:version, 'term': &term, 'start_ts': g:stats_start_ts})
endfunction

function! s:StatsSessionEnd() abort
    call s:StatsModeLeave()
    let l:total = 0
    if g:stats_start_epoch > 0
        let l:total = max([0, localtime() - g:stats_start_epoch])
    endif
    let l:insert = g:stats_insert_seconds
    if g:stats_mode_since > 0
        let l:insert += localtime() - g:stats_mode_since
    endif
    let l:normal = max([0, l:total - l:insert])
    call s:StatsLog('vim_close', {'cwd': getcwd(), 'cwd_is_home': getcwd() ==# $HOME,
        \ 'start_ts': g:stats_start_ts, 'insert_seconds': l:insert,
        \ 'normal_seconds': l:normal})
endfunction

augroup DevStats
    autocmd!
    autocmd VimEnter     * call s:StatsSessionStart()
    autocmd InsertEnter  * call s:StatsModeEnter()
    autocmd InsertLeave  * call s:StatsModeLeave()
    autocmd BufReadPost  * call s:StatsFile('file_open')
    autocmd BufWritePost * call s:StatsFile('file_save')
    autocmd BufNewFile   * call s:StatsFile('file_create')
    autocmd VimLeave     * call s:StatsSessionEnd()
    autocmd VimLeave     * if executable(expand('~/.local/bin/dev-stats'))
        \ | call system(expand('~/.local/bin/dev-stats') . ' collect >/dev/null 2>&1 &')
        \ | endif
augroup END

" ----------------------------------------------------------------------------
" Bottom terminal panel: <C-j> toggles it (under the editor, like VSCode).
" The shell keeps running while hidden. <Esc><Esc> leaves typing mode so you
" can scroll/copy (press i to type again). `exit` closes it for good.
" ----------------------------------------------------------------------------
let s:term_buf = -1

function! s:TermToggle() abort
    if !has('terminal')
        echo 'This Vim has no :terminal support'
        return
    endif
    " visible -> hide it
    let l:win = (s:term_buf > 0 && bufexists(s:term_buf)) ? bufwinnr(s:term_buf) : -1
    if l:win > 0
        execute l:win . 'wincmd w'
        hide
        return
    endif
    " called from the tree / quickfix: go back to the editor first
    if &filetype ==# 'nerdtree' || &buftype !=# ''
        wincmd p
    endif
    if s:term_buf > 0 && bufexists(s:term_buf) && term_getstatus(s:term_buf) =~# 'running'
        belowright 12split
        execute 'buffer ' . s:term_buf
        setlocal winfixheight nonumber norelativenumber signcolumn=no nolist nocursorline
        call feedkeys('i', 'n')
    else
        if s:term_buf > 0 && bufexists(s:term_buf)
            silent! execute 'bwipeout! ' . s:term_buf
        endif
        belowright terminal ++close ++rows=12
        let s:term_buf = bufnr('%')
    endif
endfunction

" :q on the last editor window would fail with "E947: Job still running"
function! s:TermQuitPre() abort
    if &buftype ==# 'terminal' || &modified || s:term_buf < 1 || !bufexists(s:term_buf)
        return
    endif
    let l:n = 0
    for l:w in range(1, winnr('$'))
        if getbufvar(winbufnr(l:w), '&buftype') ==# ''
            \ && getbufvar(winbufnr(l:w), '&filetype') !=# 'nerdtree'
            let l:n += 1
        endif
    endfor
    if l:n <= 1
        silent! execute 'bwipeout! ' . s:term_buf
    endif
endfunction

" send one command line to the terminal panel (opening the panel first if needed)
function! s:TermRun(cmd) abort
    if !has('terminal')
        echo 'This Vim has no :terminal support'
        return
    endif
    if !(s:term_buf > 0 && bufexists(s:term_buf) && bufwinnr(s:term_buf) > 0)
        call s:TermToggle()
    endif
    if s:term_buf < 1 || !bufexists(s:term_buf) || term_getstatus(s:term_buf) !~# 'running'
        return
    endif
    call term_sendkeys(s:term_buf, 'clear; ' . a:cmd . "\<CR>")
endfunction

" valgrind in the terminal panel:  <leader>v   or   :Valgrind [args for your program]
function! s:Valgrind(args) abort
    if !has('terminal')
        echo 'This Vim has no :terminal support'
        return
    endif
    if !executable('valgrind')
        echo 'valgrind is not installed'
        return
    endif
    if !executable(getcwd() . '/a.out')
        echo 'a.out not found in ' . getcwd() . '  (build first with <C-e>)'
        return
    endif
    call s:TermRun('cd ' . shellescape(getcwd()) . ' && valgrind --leak-check=full ./a.out'
        \ . (empty(a:args) ? '' : ' ' . a:args))
endfunction
command! -nargs=* Valgrind call s:Valgrind(<q-args>)
nnoremap <silent> <leader>v :call <SID>Valgrind('')<CR>

nnoremap <silent> <C-j> :call <SID>TermToggle()<CR>
if has('terminal')
    tnoremap <silent> <C-j> <C-\><C-n>:call <SID>TermToggle()<CR>
    tnoremap <Esc><Esc> <C-\><C-n>
endif

augroup TermPanel
    autocmd!
    if exists('##TerminalWinOpen')
        autocmd TerminalWinOpen * setlocal nobuflisted nonumber norelativenumber signcolumn=no nolist nocursorline winfixheight
    endif
    autocmd QuitPre * call s:TermQuitPre()
augroup END


" ----------------------------------------------------------------------------
" Key cheat sheet:  <leader>?  (Space ?)   j/k scroll, q / Esc closes
" Keep this list in sync when you add keys.
" ----------------------------------------------------------------------------
function! s:KeysRows() abort
    return [
        \ 'FILES & LAYOUT',
        \ ['Ctrl-b / Ctrl-n / F3', 'show / hide the file sidebar'],
        \ ['Space e', 'jump into the sidebar'],
        \ ['Space f', 'find the current file in the sidebar'],
        \ ['Ctrl-h / Ctrl-l', 'move left / right (sidebar <-> editor)'],
        \ ['Tab / Shift-Tab', 'next / previous open file'],
        \ ['Space 1..9', 'go to open file number N'],
        \ ['Space b', 'list open files and pick one'],
        \ ['Space w', 'close the current file'],
        \ ['Ctrl-p', 'find a file by name (type, then Tab)'],
        \ 'IN THE SIDEBAR',
        \ ['click / Enter', 'open file or folder'],
        \ ['a', 'new file (end the name with / for a folder)'],
        \ ['r / F2', 'rename'],
        \ ['d / Del', 'delete (asks first)'],
        \ ['y', 'copy'],
        \ ['I', 'show / hide hidden files'],
        \ ['R / F5', 'refresh'],
        \ ['m', 'full NERDTree menu'],
        \ 'BUILD & RUN',
        \ ['Ctrl-e', 'build: make if there is a Makefile, else gcc'],
        \ ['F6', 'run ./a.out'],
        \ ['Space v', 'valgrind --leak-check=full ./a.out (terminal panel)'],
        \ ['Ctrl-j', 'show / hide the terminal panel'],
        \ ['Esc Esc  (in terminal)', 'stop typing to scroll/copy; i = type again'],
        \ '42 NORM',
        \ ['F1', 'insert / update the 42 header'],
        \ [':HeaderGuard', 'add the #ifndef guard to a .h'],
        \ ['Space n', 'run norminette (errors in the list below)'],
        \ ['Space x', 'deep Norm fix now (rewrites for/ternary/decls...), save, re-check'],
        \ [':NormDeepToggle', 'deep fix on save on / off  (u undoes a save-fix)'],
        \ ['Space i', '#include for the function/macro under the cursor'],
        \ ['Space I', 'add every missing #include this file needs'],
        \ ['sign !!', 'forbidden: for do switch case goto ? :'],
        \ ['(on save)', 'Norm is auto-fixed for .c / .h'],
        \ [':NormAutoFixToggle', 'turn the auto-fix on save on / off'],
        \ ['sign 80 / >4', 'line wider than 80 / more than 4 parameters'],
        \ ['status line', 'ƒ n/5 functions, [x/25] current function length'],
        \ 'GIT',
        \ ['Space g', 'show / hide the git change marks'],
        \ ['Space a', 'stage / unstage the current file'],
        \ ['Space c', 'commit what is staged (asks the message), then push?'],
        \ 'EDITING',
        \ ['Tab / Enter', 'accept the autocomplete popup'],
        \ ['Ctrl-n / Ctrl-p', 'move in the popup  (Esc closes it)'],
        \ [':AutoCompleteToggle', 'popup on / off'],
        \ [':AutoSaveToggle', 'auto-save (idle 3s, leaving the file, losing focus)'],
        \ ['F4', 'copy mode: clean mouse selection + Ctrl+Shift+C (F4 again leaves)'],
        \ ['mouse select / y', 'also copied to the system clipboard'],
        \ ['Space y / Space p', 'copy line or selection / paste from the system clipboard'],
        \ [':ClipboardInfo', 'which clipboard method Vim uses here'],
        \ ['Esc Esc / Space h', 'clear search highlight'],
        \ ['< / >  (visual)', 'indent and keep the selection'],
        \ 'HELP',
        \ ['Space ?', 'this window'],
        \ ]
endfunction

function! s:KeysFilter(winid, key) abort
    if a:key ==# "\<Esc>" || a:key ==# 'q' || a:key ==# '?' || a:key ==# "\<CR>" || a:key ==# ' '
        call popup_close(a:winid)
    elseif a:key ==# 'j' || a:key ==# "\<Down>"
        call s:KeysScroll(a:winid, 1)
    elseif a:key ==# 'k' || a:key ==# "\<Up>"
        call s:KeysScroll(a:winid, -1)
    elseif a:key ==# "\<C-d>" || a:key ==# "\<PageDown>"
        call s:KeysScroll(a:winid, 10)
    elseif a:key ==# "\<C-u>" || a:key ==# "\<PageUp>"
        call s:KeysScroll(a:winid, -10)
    elseif a:key ==# 'g'
        call s:KeysScroll(a:winid, -1000)
    elseif a:key ==# 'G'
        call s:KeysScroll(a:winid, 1000)
    endif
    return 1
endfunction

function! s:KeysScroll(winid, delta) abort
    let l:p = popup_getpos(a:winid)
    let l:last = max([line('$', a:winid) - l:p.core_height + 1, 1])
    call popup_setoptions(a:winid, {'firstline': max([1, min([l:p.firstline + a:delta, l:last])])})
endfunction

function! s:KeysHelp() abort
    if !exists('*popup_create')
        echo 'This Vim has no popup support'
        return
    endif
    let l:lines = []
    for l:r in s:KeysRows()
        if type(l:r) == v:t_string
            call add(l:lines, '')
            call add(l:lines, ' ' . l:r)
        else
            call add(l:lines, printf('   %-24s %s', l:r[0], l:r[1]))
        endif
    endfor
    call add(l:lines, '')
    call popup_create(l:lines[1:], {
        \ 'title': ' Keys   (Space = leader)   j/k scroll   q close ',
        \ 'border': [1, 1, 1, 1], 'padding': [0, 1, 0, 1],
        \ 'minwidth': 60, 'maxheight': &lines - 6, 'zindex': 300,
        \ 'wrap': 0, 'mapping': 0, 'filter': function('s:KeysFilter'),
        \ })
endfunction
nnoremap <silent> <leader>? :call <SID>KeysHelp()<CR>

" ----------------------------------------------------------------------------
" Auto #include:  <leader>i  header for the function / macro / type under the cursor
"                 <leader>I  add every header this file is missing
" ----------------------------------------------------------------------------
let s:inc_hdr = {
    \ 'unistd.h': 'write read close fork pipe dup dup2 execve execv execvp access unlink chdir getcwd sleep usleep isatty getpid getppid lseek rmdir sysconf ttyname ssize_t',
    \ 'stdlib.h': 'malloc free calloc realloc exit atoi atol atof strtol strtoul strtod abs labs rand srand getenv system qsort bsearch mkstemp EXIT_SUCCESS EXIT_FAILURE',
    \ 'stdio.h': 'printf fprintf sprintf snprintf dprintf vprintf vfprintf vsprintf vsnprintf puts putchar perror scanf sscanf fopen fclose fgets fputs fputc getchar getline fread fwrite fflush remove rename stdin stdout stderr FILE EOF BUFSIZ',
    \ 'string.h': 'strlen strcpy strncpy strcat strncat strcmp strncmp strchr strrchr strstr memcpy memmove memset memcmp memchr strdup strndup strerror strtok strcspn strspn strpbrk strcoll',
    \ 'strings.h': 'bzero bcopy index rindex strcasecmp strncasecmp',
    \ 'fcntl.h': 'open creat fcntl O_RDONLY O_WRONLY O_RDWR O_CREAT O_TRUNC O_APPEND O_EXCL O_NONBLOCK',
    \ 'sys/wait.h': 'wait waitpid wait3 wait4 WIFEXITED WEXITSTATUS WIFSIGNALED WTERMSIG',
    \ 'signal.h': 'signal sigaction kill sigemptyset sigaddset sigfillset sigprocmask raise SIGINT SIGTERM SIGQUIT SIGUSR1 SIGUSR2 SIGKILL sig_atomic_t',
    \ 'stddef.h': 'size_t ptrdiff_t NULL offsetof',
    \ 'stdint.h': 'int8_t int16_t int32_t int64_t uint8_t uint16_t uint32_t uint64_t intptr_t uintptr_t SIZE_MAX',
    \ 'limits.h': 'INT_MAX INT_MIN LONG_MAX LONG_MIN UINT_MAX ULONG_MAX CHAR_BIT SHRT_MAX PATH_MAX',
    \ 'ctype.h': 'isalpha isdigit isalnum isspace isupper islower isprint ispunct isascii toupper tolower',
    \ 'math.h': 'sqrt pow sin cos tan fabs floor ceil round fmod log exp atan atan2 M_PI',
    \ 'stdbool.h': 'bool true false',
    \ 'errno.h': 'errno EINTR ENOENT EACCES EAGAIN',
    \ 'sys/stat.h': 'stat fstat lstat mkdir chmod S_ISDIR S_ISREG',
    \ 'sys/types.h': 'pid_t off_t mode_t',
    \ 'dirent.h': 'opendir readdir closedir DIR',
    \ 'time.h': 'time clock nanosleep difftime localtime strftime clock_t time_t',
    \ 'sys/time.h': 'gettimeofday timeval',
    \ 'pthread.h': 'pthread_create pthread_join pthread_detach pthread_mutex_init pthread_mutex_lock pthread_mutex_unlock pthread_mutex_destroy pthread_t pthread_mutex_t',
    \ 'stdarg.h': 'va_list va_start va_arg va_end va_copy',
    \ 'sys/mman.h': 'mmap munmap',
    \ 'termios.h': 'tcgetattr tcsetattr',
    \ 'readline/readline.h': 'readline rl_on_new_line rl_replace_line rl_redisplay rl_clear_history',
    \ 'readline/history.h': 'add_history',
    \ }
" a header that is already provided by another one the file includes
let s:inc_alt = {
    \ 'stddef.h': ['stdlib.h', 'stdio.h', 'string.h', 'unistd.h'],
    \ 'sys/types.h': ['unistd.h', 'sys/wait.h', 'sys/stat.h', 'fcntl.h'],
    \ }
let s:inc_ident = ['bool', 'true', 'false', 'errno', 'stdin', 'stdout', 'stderr', 'va_list', 'timeval']
let s:inc_map = {}
for [s:ih, s:iw] in items(s:inc_hdr)
    for s:in in split(s:iw)
        let s:inc_map[s:in] = s:ih
    endfor
endfor

function! s:HasInclude(h) abort
    return search('^\s*#\s*include\s*<' . escape(a:h, '/.') . '>', 'nw') > 0
endfunction

" insert  #include <a:h>  in the right place; returns 1 if added, 0 if already there
function! s:AddInclude(h) abort
    if s:HasInclude(a:h)
        return 0
    endif
    let l:last_sys = 0
    let l:first_loc = 0
    for l:n in range(1, min([line('$'), 300]))
        let l:t = getline(l:n)
        if l:t =~# '^\s*#\s*include\s*<'
            let l:last_sys = l:n
        elseif l:t =~# '^\s*#\s*include\s*"' && !l:first_loc
            let l:first_loc = l:n
        endif
    endfor
    let l:ref = 0
    if l:last_sys
        let l:at = l:last_sys
        let l:ref = l:last_sys
    elseif l:first_loc
        let l:at = l:first_loc - 1
        let l:ref = l:first_loc
    else
        let l:at = s:HdrExists() ? 12 : 0
        let l:g = expand('%:e') ==# 'h' ? search('^\s*#\s*ifndef\s\+\w\+', 'nw') : 0
        if l:g
            let l:at = l:g + 1          " inside the header guard, after its # define
            let l:ref = l:g + 1
        endif
    endif
    let l:at = min([l:at, line('$')])
    let l:style = l:ref ? substitute(matchstr(getline(l:ref), '^\s*#\s*'), '^\s*', '', '') : '#'
    let l:view = winsaveview()
    call append(l:at, l:style . 'include <' . a:h . '>')
    let l:added = 1
    let l:nx = l:at + 2
    if l:nx <= line('$') && getline(l:nx) !~# '^\s*$' && getline(l:nx) !~# '^\s*#\s*include'
        call append(l:at + 1, '')
        let l:added = 2
    endif
    if l:view.lnum > l:at
        let l:view.lnum += l:added
        let l:view.topline += l:added
    endif
    call winrestview(l:view)
    return 1
endfunction

function! s:IncludeWord() abort
    if expand('%:e') !~# '^[ch]$'
        echo '#include helper: only for .c / .h files'
        return
    endif
    let l:w = expand('<cword>')
    let l:h = get(s:inc_map, l:w, '')
    if empty(l:h)
        echo "No known header for '" . l:w . "'"
    elseif s:AddInclude(l:h)
        echo 'Added #include <' . l:h . '>  (for ' . l:w . ')'
    else
        echo '<' . l:h . '> is already included'
    endif
endfunction

function! s:IncludeAll() abort
    if expand('%:e') !~# '^[ch]$'
        echo '#include helper: only for .c / .h files'
        return
    endif
    let l:need = {}
    let l:st = 0
    for l:t in getline(1, '$')
        if l:t =~# '^\s*#'
            continue
        endif
        let [l:m, l:st] = s:MaskLine(l:t, l:st)
        let l:p = 0
        while 1
            let l:r = matchstrpos(l:m, '\<\h\w*\>', l:p)
            if l:r[1] < 0
                break
            endif
            let l:p = l:r[2]
            let l:h = get(s:inc_map, l:r[0], '')
            if !empty(l:h) && (l:r[0] =~# '^[A-Z][A-Z0-9_]*$' || l:r[0] =~# '_t$'
                \ || index(s:inc_ident, l:r[0]) >= 0 || strpart(l:m, l:r[2]) =~# '^\s*(')
                let l:need[l:h] = 1
            endif
        endwhile
    endfor
    " drop headers already provided by another one
    for [l:h, l:alts] in items(s:inc_alt)
        for l:a in l:alts
            if has_key(l:need, l:h) && (has_key(l:need, l:a) || s:HasInclude(l:a))
                call remove(l:need, l:h)
            endif
        endfor
    endfor
    let l:added = []
    for l:h in sort(keys(l:need))
        if s:AddInclude(l:h)
            call add(l:added, l:h)
        endif
    endfor
    echo empty(l:added) ? 'No missing #include found' : 'Added: ' . join(map(l:added, '"<" . v:val . ">"'), ' ')
endfunction

nnoremap <silent> <leader>i :call <SID>IncludeWord()<CR>
nnoremap <silent> <leader>I :call <SID>IncludeAll()<CR>

" ----------------------------------------------------------------------------
" Git from Vim:  <leader>a  stage / unstage the current file
"                <leader>c  commit what is staged (asks for the message), then
"                           offers to push (the push runs in the terminal panel)
" ----------------------------------------------------------------------------
function! s:GitTop() abort
    let l:dir = (&buftype ==# '' && !empty(expand('%'))) ? expand('%:p:h') : getcwd()
    let l:top = trim(system('git -C ' . shellescape(l:dir) . ' rev-parse --show-toplevel 2>/dev/null'))
    return v:shell_error ? '' : l:top
endfunction

function! s:GitRefresh() abort
    call s:StatusGit(1)
    if exists('*NerdTreeDecorate')
        call NerdTreeDecorate()
    endif
    redrawstatus!
endfunction

function! s:GitStage() abort
    if &buftype !=# '' || empty(expand('%'))
        echo 'Open a file first'
        return
    endif
    let l:top = s:GitTop()
    if empty(l:top)
        echo 'Not in a git repository'
        return
    endif
    silent! update
    call s:StatusGit(1)
    let l:state = get(get(b:, 'gitinfo', {}), 'file', '')
    let l:g = 'git -C ' . shellescape(l:top)
    if l:state ==# 'staged'
        call system(l:g . ' reset -q HEAD -- ' . shellescape(expand('%:p')))
        echo 'Unstaged ' . expand('%:t')
    elseif l:state ==# 'clean'
        echo expand('%:t') . ' has no changes to stage'
        return
    else
        call system(l:g . ' add -- ' . shellescape(expand('%:p')))
        echo 'Staged ' . expand('%:t')
    endif
    call s:GitRefresh()
endfunction

function! s:GitCommit() abort
    let l:top = s:GitTop()
    if empty(l:top)
        echo 'Not in a git repository'
        return
    endif
    let l:g = 'git -C ' . shellescape(l:top)
    if &buftype ==# '' && &modified
        silent! update
    endif
    call system(l:g . ' diff --cached --quiet')
    if v:shell_error == 0
        let l:ch = systemlist(l:g . ' status --porcelain')
        if empty(l:ch)
            echo 'Nothing to commit'
            return
        endif
        if input('Nothing staged. Stage all ' . len(l:ch) . ' changed file(s) with git add -A? [y/N] ') !~? '^y'
            echo ''
            return
        endif
        call system(l:g . ' add -A')
    endif
    let l:sum = trim(system(l:g . ' diff --cached --shortstat'))
    echo 'Staged: ' . l:sum
    let l:msg = trim(input('Commit message: '))
    if empty(l:msg)
        echo 'Commit cancelled'
        return
    endif
    let l:out = systemlist(l:g . ' commit -m ' . shellescape(l:msg) . ' 2>&1')
    if v:shell_error
        echohl ErrorMsg
        echo join(l:out[:3], "\n")
        echohl None
        return
    endif
    call s:GitRefresh()
    redraw
    echo get(l:out, 0, 'Committed')
    if input('Push now? [y/N] ') =~? '^y'
        call s:TermRun('cd ' . shellescape(l:top) . ' && git push')
        " refresh the ahead/behind marks once the push has had time to finish
        call timer_start(4000, function('s:GitRefreshLater'))
    endif
endfunction

function! s:GitRefreshLater(id) abort
    " the terminal panel has the focus after a push: refresh the editor's window
    let l:w = s:EditorWin()
    if l:w > 0
        call win_execute(l:w, 'call s:StatusGit(1)')
    endif
    if exists('*NerdTreeDecorate')
        call NerdTreeDecorate()
    endif
    redrawstatus!
endfunction

nnoremap <silent> <leader>a :call <SID>GitStage()<CR>
nnoremap <silent> <leader>c :call <SID>GitCommit()<CR>

" ----------------------------------------------------------------------------
" Auto-save: after 3 s without typing, when you leave the file, and when Vim
" loses focus (you switch to another window/app). It does NOT run the Norm
" auto-fix (that stays on real saves, so it never reformats while you think).
" :AutoSaveToggle turns it on/off.   :q! still throws changes away.
" ----------------------------------------------------------------------------
let g:autosave = 1
let g:autosave_delay = 3000
let g:autosaving = 0
let s:as_timer = -1

function! s:AutoSaveNow(all) abort
    if !g:autosave
        return
    endif
    let g:autosaving = 1
    try
        if a:all
            silent! wall
        elseif &buftype ==# '' && &modified && &modifiable && !&readonly && !empty(bufname('%'))
            silent! update
        endif
    finally
        let g:autosaving = 0
    endtry
endfunction

function! s:AutoSaveFire(id) abort
    let s:as_timer = -1
    if mode() =~# '^[cR]'
        call s:AutoSaveArm()
        return
    endif
    call s:AutoSaveNow(0)
endfunction

function! s:AutoSaveArm() abort
    if !g:autosave || &buftype !=# ''
        return
    endif
    if s:as_timer != -1
        call timer_stop(s:as_timer)
    endif
    let s:as_timer = timer_start(g:autosave_delay, function('s:AutoSaveFire'))
endfunction

augroup AutoSave
    autocmd!
    autocmd TextChanged,TextChangedI,TextChangedP * call s:AutoSaveArm()
    autocmd BufLeave * call s:AutoSaveNow(0)
    if exists('##FocusLost')
        autocmd FocusLost * call s:AutoSaveNow(1)
    endif
augroup END

command! AutoSaveToggle let g:autosave = !g:autosave
    \ | echo 'Auto-save: ' . (g:autosave ? 'on' : 'off')

" ----------------------------------------------------------------------------
" Copy / paste.  Ctrl+Shift+C and Ctrl+Shift+V belong to your TERMINAL, Vim cannot
" bind them.  What this does so they work well:
"   paste  Ctrl+Shift+V: bracketed paste is on (Vim 9), pasted text is inserted as-is
"          (no auto-indent, no auto-close brackets, no autocomplete popup, one undo)
"   copy   mouse selection in Vim and  y  also go to the system clipboard
"          (Vim +clipboard, wl-copy, xclip, xsel, or the terminal's OSC 52)
"   F4     COPY MODE: mouse/numbers/signs/tree off, so a terminal selection +
"          Ctrl+Shift+C copies clean code.  F4 again restores everything.
" ----------------------------------------------------------------------------
function! s:ClipProvider() abort
    if has('clipboard')
        return 'vim (+ register)'
    elseif !empty($WAYLAND_DISPLAY) && executable('wl-copy')
        return 'wl-copy'
    elseif !empty($DISPLAY) && executable('xclip')
        return 'xclip'
    elseif !empty($DISPLAY) && executable('xsel')
        return 'xsel'
    endif
    return 'OSC 52 (terminal)'
endfunction

function! s:ClipSet(text) abort
    let l:p = s:ClipProvider()
    if l:p ==# 'vim (+ register)'
        call setreg('+', a:text)
        silent! call setreg('*', a:text)
    elseif l:p ==# 'wl-copy'
        call system('wl-copy >/dev/null 2>&1', a:text)
    elseif l:p ==# 'xclip'
        call system('xclip -selection clipboard >/dev/null 2>&1', a:text)
    elseif l:p ==# 'xsel'
        call system('xsel -ib >/dev/null 2>&1', a:text)
    elseif exists('*echoraw')
        let l:b = substitute(system('base64 -w0', a:text), '\n', '', 'g')
        let l:seq = "\e]52;c;" . l:b . "\x07"
        if !empty($TMUX)
            let l:seq = "\ePtmux;\e" . l:seq . "\e\\"
        endif
        call echoraw(l:seq)
    endif
endfunction

function! s:ClipGet() abort
    if has('clipboard')
        return getreg('+')
    elseif !empty($WAYLAND_DISPLAY) && executable('wl-paste')
        return system('wl-paste --no-newline 2>/dev/null')
    elseif !empty($DISPLAY) && executable('xclip')
        return system('xclip -selection clipboard -o 2>/dev/null')
    elseif !empty($DISPLAY) && executable('xsel')
        return system('xsel -ob 2>/dev/null')
    endif
    return ''
endfunction

function! s:ClipPaste() abort
    let l:t = s:ClipGet()
    if empty(l:t)
        echo 'Clipboard is empty or not readable from Vim here: use Ctrl+Shift+V'
        return
    endif
    if l:t =~# "\n$"
        call setreg('p', substitute(l:t, "\n$", '', ''), 'l')
    else
        call setreg('p', l:t, 'c')
    endif
    normal! "pp
endfunction

function! s:OnYank() abort
    if v:event.operator !=# 'y' || has('clipboard')
        return
    endif
    call s:ClipSet(join(v:event.regcontents, "\n") . (v:event.regtype ==# 'V' ? "\n" : ''))
endfunction

augroup ClipCopy
    autocmd!
    autocmd TextYankPost * call s:OnYank()
augroup END

" a mouse selection is copied as soon as you release the button (and stays selected)
vnoremap <silent> <LeftRelease> <LeftRelease>ygv
vnoremap <silent> <leader>y y
nnoremap <silent> <leader>y yy
nnoremap <silent> <leader>p :call <SID>ClipPaste()<CR>
command! ClipboardInfo echo 'Clipboard method: ' . s:ClipProvider()
    \ . '   (Ctrl+Shift+C / Ctrl+Shift+V are the terminal'."'".'s own keys)'

let g:copy_mode = 0
let s:copy_saved = {}

function! s:CopyMode() abort
    if !g:copy_mode
        let s:copy_saved = {'mouse': &mouse, 'tree': s:TreeBuf() > 0, 'wins': {}}
        for l:w in range(1, winnr('$'))
            let s:copy_saved.wins[win_getid(l:w)] = {
                \ 'number': getwinvar(l:w, '&number'), 'rnu': getwinvar(l:w, '&relativenumber'),
                \ 'sign': getwinvar(l:w, '&signcolumn'), 'list': getwinvar(l:w, '&list'),
                \ 'cc': getwinvar(l:w, '&colorcolumn'), 'cul': getwinvar(l:w, '&cursorline')}
        endfor
        if s:copy_saved.tree
            silent! NERDTreeClose
        endif
        set mouse=
        for l:w in range(1, winnr('$'))
            call setwinvar(l:w, '&number', 0)
            call setwinvar(l:w, '&relativenumber', 0)
            call setwinvar(l:w, '&signcolumn', 'no')
            call setwinvar(l:w, '&list', 0)
            call setwinvar(l:w, '&colorcolumn', '')
            call setwinvar(l:w, '&cursorline', 0)
        endfor
        let g:copy_mode = 1
        redrawstatus!
        echo 'COPY MODE: drag with the mouse, then Ctrl+Shift+C.   F4 leaves.'
    else
        let &mouse = s:copy_saved.mouse
        for [l:id, l:o] in items(s:copy_saved.wins)
            let l:w = win_id2win(str2nr(l:id))
            if l:w > 0
                call setwinvar(l:w, '&number', l:o.number)
                call setwinvar(l:w, '&relativenumber', l:o.rnu)
                call setwinvar(l:w, '&signcolumn', l:o.sign)
                call setwinvar(l:w, '&list', l:o.list)
                call setwinvar(l:w, '&colorcolumn', l:o.cc)
                call setwinvar(l:w, '&cursorline', l:o.cul)
            endif
        endfor
        let g:copy_mode = 0
        if s:copy_saved.tree && exists(':NERDTree')
            NERDTree
            wincmd p
        endif
        redrawstatus!
        echo 'Copy mode off'
    endif
endfunction
command! CopyMode call s:CopyMode()
nnoremap <silent> <F4> :call <SID>CopyMode()<CR>

" ----------------------------------------------------------------------------
" Layout (VSCode style): tree on the LEFT, file content on the RIGHT
"   vim .      -> cd into that folder, tree on the left, editor on the right
"   vim        -> same, restoring the files you had open in this folder
"   vim a.c    -> a.c on the right, tree on the left
" Keys: <C-n> toggle tree | <Tab>/<S-Tab> next/prev file | <leader>1..9 jump
"       to file N | <leader>w close file | <C-h>/<C-l> move between panes
" ----------------------------------------------------------------------------
let g:NERDTreeWinPos = 'left'
let g:NERDTreeQuitOnOpen = 0             " tree stays visible after opening a file
" open files in the previous (right) window, keep the tree open
let g:NERDTreeCustomOpenArgs = {'file': {'where': 'p', 'reuse': 'currenttab', 'keepopen': 1}}

" --- no top bar (use <Tab>/<S-Tab>, <leader>b to list/pick files) ---------
set showtabline=0

function! s:CycleBuf(cmd) abort
    if &filetype ==# 'nerdtree' || &buftype ==# 'terminal'
        wincmd p
    endif
    execute a:cmd
endfunction

function! s:GotoBuf(n) abort
    let l:bufs = getbufinfo({'buflisted': 1})
    if a:n > len(l:bufs)
        return
    endif
    if &filetype ==# 'nerdtree' || &buftype ==# 'terminal'
        wincmd p
    endif
    execute 'buffer ' . l:bufs[a:n - 1].bufnr
endfunction

function! s:CloseBuf() abort
    if &filetype ==# 'nerdtree' || &buftype ==# 'terminal'
        return
    endif
    if &modified
        echo 'Unsaved changes (save first or use :bd!)'
        return
    endif
    let l:cur = bufnr('%')
    " never delete the buffer of the last editor window (it would close the
    " pane and leave the tree full-screen): swap in another/empty buffer first
    if len(getbufinfo({'buflisted': 1})) > 1
        bprevious
    else
        enew
    endif
    execute 'bdelete ' . l:cur
endfunction

nnoremap <silent> <Tab>   :call <SID>CycleBuf('bnext')<CR>
nnoremap <silent> <S-Tab> :call <SID>CycleBuf('bprevious')<CR>
nnoremap <silent> <leader>w :call <SID>CloseBuf()<CR>
nnoremap <leader>b :ls<CR>:buffer<Space>
nnoremap <silent> <C-h> <C-w>h
nnoremap <silent> <C-l> <C-w>l
for s:i in range(1, 9)
    execute 'nnoremap <silent> <leader>' . s:i . ' :call <SID>GotoBuf(' . s:i . ')<CR>'
endfor

" --- remember open files per directory (restored on `vim` / `vim .`) -------
set sessionoptions=buffers,curdir,folds

function! s:SessFile() abort
    return expand('~/.vim/sessions/') . substitute(getcwd(), '[/\\:]', '%', 'g') . '.vim'
endfunction

function! s:SessSave() abort
    if empty(filter(getbufinfo({'buflisted': 1}), 'v:val.name !=# ""'))
        return
    endif
    silent! NERDTreeClose
    call mkdir(expand('~/.vim/sessions'), 'p')
    execute 'mksession! ' . fnameescape(s:SessFile())
endfunction

function! s:Startup() abort
    " `vim .` / `vi some/dir`: enter the folder and drop the directory buffer
    let l:dir = (argc() == 1 && isdirectory(argv(0))) ? fnamemodify(argv(0), ':p') : ''
    if !empty(l:dir)
        execute 'cd ' . fnameescape(l:dir)
        let l:old = bufnr('%')
        enew
        silent! execute 'bwipeout ' . l:old
        silent! argdelete *
    endif

    " restore last session of this folder (plain `vim` or `vim .`)
    if (argc() == 0 || !empty(l:dir)) && filereadable(s:SessFile())
        silent! execute 'source ' . fnameescape(s:SessFile())
    endif

    " tree on the left, cursor in the editor on the right
    if exists(':NERDTree')
        NERDTree
        wincmd p
    endif
endfunction

augroup Layout
    autocmd!
    autocmd VimEnter * ++nested call s:Startup()
    autocmd VimLeavePre * call s:SessSave()
augroup END
