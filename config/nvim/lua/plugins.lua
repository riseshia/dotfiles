return require('packer').startup(function()
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'
  use 'bronson/vim-trailing-whitespace'
  use 'christoomey/vim-tmux-navigator'
  use 'tomtom/tcomment_vim'
  use 'tpope/vim-surround'
  use { 'neoclide/coc.nvim', branch = 'release' }
  use { 'junegunn/fzf', { run = function() vim.fn['fzf#install']() end } }
  use 'junegunn/fzf.vim'

  -- statusline
  use 'vim-airline/vim-airline'

  -- Syntax Highlight
  use 'google/vim-jsonnet'
  use 'hashivim/vim-terraform'
  use 'sheerun/vim-polyglot'
  use 'jparise/vim-graphql'
  use 'kevinoid/vim-jsonc'
end)
