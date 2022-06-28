return require('packer').startup(function()
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  use 'bronson/vim-trailing-whitespace'
  use 'christoomey/vim-tmux-navigator'
  use 'tomtom/tcomment_vim'
  use 'tpope/vim-surround'
  use { 'junegunn/fzf', { run = function() vim.fn['fzf#install']() end } }
  use 'junegunn/fzf.vim'

  use 'github/copilot.vim'

  use {
    "williamboman/nvim-lsp-installer",
    "neovim/nvim-lspconfig",
  }

  -- statusline
  use 'vim-airline/vim-airline'

  -- Syntax Highlight
  use { 'nvim-treesitter/nvim-treesitter', { run = ':TSUpdate' } }
  use 'google/vim-jsonnet'
  use 'hashivim/vim-terraform'
  use 'kevinoid/vim-jsonc'
end)
