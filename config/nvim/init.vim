filetype off
filetype plugin indent on

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

colorscheme monokai

lua require('plugins')
lua require('treesitter-config')
lua require('lsp-config')

" Make inactive panel darker
" autocmd WinEnter,BufWinEnter * setlocal wincolor=
" autocmd WinLeave * setlocal wincolor=NormalIA

" airline config
let g:airline_section_x = ''
let g:airline_section_y = ''
let g:airline_section_z = ''

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

:command EE Explore

" Quickfix mapping
nnoremap <silent> [q :cprevious<CR>
nnoremap <silent> ]q :cnext<CR>
nnoremap <silent> [Q :cfirst<CR>
nnoremap <silent> ]Q :clast<CR>


" Add git grep command
set grepprg=git\ grep\ -I\ --line-number
set grepformat=%f:%l:%m
function! s:gitgrep(query)
  execute 'silent grep ' . a:query
  cw
  redraw!
endfunction
command! -nargs=+ Ggrep execute 'silent grep <args> | cw | redraw!'

nnoremap <silent> <C-p> :Buffers<CR>
