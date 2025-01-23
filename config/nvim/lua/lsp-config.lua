require('mason').setup()
require('mason-lspconfig').setup({
  ensure_installed = {
    'bashls', -- npm install -g bash-language-server
    'dockerls', -- npm install -g dockerfile-language-server-nodejs
    -- 'jsonnet_ls', -- require golang
    'rust_analyzer', -- require rust
    'solargraph', -- require ruby
    'lua_ls',
    -- 'terraformls',
    'tflint',
    'ts_ls', -- npm install -g typescript typescript-language-server
  }
})
local rt = require('rust-tools')

-- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local opts = { noremap=true, silent=true }
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, opts)

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  -- KK するとホーバーしたやつの中にカーソルが移る
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
  -- vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  -- vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  -- vim.keymap.set('n', '<space>wl', function()
  --   print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  -- end, bufopts)
  vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
  -- vim.keymap.set('n', '<space>f', vim.lsp.buf.formatting, bufopts)

  vim.keymap.set('n', '<C-space>', rt.hover_actions.hover_actions, { buffer = bufnr })
end

-- Server config for each language server.

require('lspconfig')['ts_ls'].setup{
  on_attach = on_attach,
}

require('lspconfig')['solargraph'].setup{
  on_attach = on_attach,
  cmd = {
    "rbenv", "exec", "solargraph", "stdio"
  }
}

require('lspconfig')['bashls'].setup{
  on_attach = on_attach,
}

local rust_opts = {
  tools = { -- rust-tools options
    inlay_hints = {
      auto = true,
      show_parameter_hints = false,
      parameter_hints_prefix = "",
      other_hints_prefix = "",
    },
  },

  -- all the opts to send to nvim-lspconfig
  -- these override the defaults set by rust-tools.nvim
  -- see https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#rust_analyzer
  server = {
    -- on_attach is a callback called when the language server attachs to the buffer
    on_attach = on_attach,
    settings = {
      -- to enable rust-analyzer settings visit:
      -- https://github.com/rust-analyzer/rust-analyzer/blob/master/docs/user/generated_config.adoc
      ["rust-analyzer"] = {
        -- enable clippy on save
        checkOnSave = {
          command = "clippy"
        },
        diagnostics = {
          disabled = { "inactive-code" } -- Suppress #[cfg(not(test))] warning..
        },
      }
    }
  },
}
rt.setup(rust_opts)

local lspconfig = require 'lspconfig'
local configs = require 'lspconfig.configs'

-- if not configs.typeprof then
--   configs.typeprof = {
--     default_config = {
--       cmd = { 'typeprof', '--lsp' },
--       root_dir = lspconfig.util.root_pattern('.git'),
--       filetypes = { 'ruby' },
--     },
--   }
-- end

local format_sync_grp = vim.api.nvim_create_augroup("Format", {})
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.rs",
  callback = function()
    vim.lsp.buf.format({ timeout_ms = 200 })
  end,
  group = format_sync_grp,
})

lspconfig.typeprof.setup {}
