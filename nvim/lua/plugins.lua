return require('packer').startup(function()
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  use 'bronson/vim-trailing-whitespace'
  use 'christoomey/vim-tmux-navigator'
  use 'tomtom/tcomment_vim'
  use 'tpope/vim-surround'
  use { 'junegunn/fzf', run = function() vim.fn['fzf#install']() end }
  use 'junegunn/fzf.vim'

  use {
    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',
    'neovim/nvim-lspconfig',
  }
  use { 'simrat39/rust-tools.nvim' }

  use 'hrsh7th/vim-vsnip'
  use {
    'hrsh7th/nvim-cmp',
    -- LSP completion source for nvim-cmp
    'hrsh7th/cmp-nvim-lsp',
    -- Snippet completion source for nvim-cmp
    'hrsh7th/cmp-vsnip',
    -- Other usefull completion sources
    'hrsh7th/cmp-path',
    'hrsh7th/cmp-buffer',
  }

  -- statusline
  use 'vim-airline/vim-airline'

  -- Syntax Highlight
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }
  use 'google/vim-jsonnet'
  use 'hashivim/vim-terraform'
  use 'kevinoid/vim-jsonc'
  use 'othree/html5.vim'
  use 'pangloss/vim-javascript'
  use 'evanleck/vim-svelte'
end)
