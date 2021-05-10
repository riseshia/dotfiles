" Normally this if-block is not needed, because `:set nocp` is done
" automatically when .vimrc is found. However, this might be useful
" when you execute `vim -u .vimrc` from the command line.
if &compatible
  " `:set nocp` has many side effects. Therefore this should be done
  " only when 'compatible' is set.
  set nocompatible
endif

filetype off                  " required

" Init minpac
packadd minpac
call minpac#init()

" minpac must have {'type': 'opt'} so that it can be loaded with `packadd`.
call minpac#add('k-takata/minpac', {'type': 'opt'})

" Enable plugins
call minpac#add('bronson/vim-trailing-whitespace')

call minpac#add('christoomey/vim-tmux-navigator')
call minpac#add('sgur/vim-editorconfig')
call minpac#add('tomtom/tcomment_vim')
call minpac#add('tpope/vim-surround')
call minpac#add('neoclide/coc.nvim')

" Plugin 'airblade/vim-gitgutter'
" Plugin 'jgdavey/vim-blockle'
" Plugin 'nathanaelkane/vim-indent-guides'
" Plugin 'tpope/vim-rhubarb'
" Plugin 'tpope/tpope-vim-abolish'
" Plugin 'tpope/vim-fugitive'
" Plugin 'tpope/vim-rails'
" Plugin 'tpope/vim-unimpaired'

" Snippet
" Plugin 'SirVer/ultisnips'
" Plugin 'honza/vim-snippets'

" Syntax Highlight
call minpac#add('google/vim-jsonnet')
call minpac#add('hashivim/vim-terraform')
call minpac#add('sheerun/vim-polyglot')
call minpac#add('jparise/vim-graphql')
call minpac#add('kevinoid/vim-jsonc')

" End of Loading plugins

" Add command for minpac
command! PackUpdate call minpac#update()
command! PackClean  call minpac#clean()
command! PackStatus call minpac#status()

filetype plugin indent on    " required

set expandtab
set hlsearch
set nobackup
set noswapfile
set nowritebackup
set number
set scrolloff=10
set shiftwidth=2
set autoindent
set smartindent
set tabstop=2
set cursorline

syntax enable
syntax sync fromstart
" colorscheme monokai

" Disable output and VCS files
set wildignore+=*.o,*.out,*.obj,.git,*.rbc,*.rbo,*.class,.svn,*.gem

" Ignore images and log files
set wildignore+=*.gif,*.jpg,*.png,*.log

" Disable archive files
set wildignore+=*.zip,*.tar.gz,*.tar.bz2,*.rar,*.tar.xz

" Ignore bundler and sass cache
set wildignore+=*/vendor/gems/*,*/vendor/cache/*,*/.bundle/*,*/.sass-cache/*

" Ignore rails temporary asset caches
set wildignore+=*/tmp/cache/assets/*/sprockets/*,*/tmp/cache/assets/*/sass/*

" Disable OS X index files
set wildignore+=.DS_Store

" Python Indent configuration
let g:pyindent_open_paren = '&sw'
let g:pyindent_continue = '&sw'

" Treat *.jb as ruby
au BufRead,BufNewFile *.jb set filetype=ruby

" Disable plugin indent support on ts
let g:typescript_indent_disable = 1

" vim-terraform
let g:terraform_align=1

runtime macros/matchit.vim

cnoremap <expr> %% getcmdtype() == ':' ? expand('%:h').'/' : '%%'

" http://mattn.kaoriya.net/software/vim/20150209151638.htm …
if (exists('+colorcolumn'))
  set colorcolumn=80
  highlight ColorColumn ctermbg=9
endif

" puts the caller
nnoremap <leader>wtf oputs "#" * 90<c-m>puts caller<c-m>puts "#" * 90<esc>

" fzf - buffer selection
set rtp+=/usr/local/opt/fzf
function! s:buflist()
  redir => ls
  silent ls
  redir END
  return split(ls, '\n')
endfunction

function! s:bufopen(e)
  execute 'buffer' matchstr(a:e, '^[ 0-9]*')
endfunction

:command EE Explore

" Git grep shortcut
:command -nargs=+ GgrepCw execute 'silent Ggrep' <q-args> | cw | redraw!
nnoremap <silent> vv :GgrepCw
nnoremap <silent> <C-w>p :FZF<CR>
nnoremap <silent> <C-p> :call fzf#run({
\   'source':  reverse(<sid>buflist()),
\   'sink':    function('<sid>bufopen'),
\   'options': '+m',
\   'down':    len(<sid>buflist()) + 2
\ })<CR>
