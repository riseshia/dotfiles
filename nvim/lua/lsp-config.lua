require('mason').setup()
require('mason-lspconfig').setup({
  ensure_installed = {
    'bashls', -- npm install -g bash-language-server
    'dockerls', -- npm install -g dockerfile-language-server-nodejs
    'jsonnet_ls', -- go install github.com/grafana/jsonnet-language-server@latest
    'rust_analyzer', -- require rust
    'lua_ls',
    -- 'terraformls',
    'tflint',
    'ts_ls', -- npm install -g typescript typescript-language-server
  },
  automatic_enable = {
    exclude = { 'ruby_lsp' },
  },
})
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
end

-- Server config for each language server.
-- mason-lspconfig enables the installed servers (automatic_enable), so only settings live here.

vim.lsp.config('ts_ls', {
  on_attach = on_attach,
})

vim.lsp.config('bashls', {
  on_attach = on_attach,
})

vim.lsp.config('jsonnet_ls', {
  on_attach = on_attach,
})

vim.lsp.config('rust_analyzer', {
  on_attach = function(client, bufnr)
    on_attach(client, bufnr)
    -- Replaces rust-tools' automatic inlay hints.
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
  end,
  settings = {
    -- to enable rust-analyzer settings visit:
    -- https://github.com/rust-analyzer/rust-analyzer/blob/master/docs/user/generated_config.adoc
    ["rust-analyzer"] = {
      -- enable clippy on save
      checkOnSave = true,
      check = {
        command = "clippy"
      },
      diagnostics = {
        disabled = { "inactive-code" } -- Suppress #[cfg(not(test))] warning..
      },
    }
  },
})

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
-- lspconfig.typeprof.setup {}

local format_sync_grp = vim.api.nvim_create_augroup("Format", {})
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.rs",
  callback = function()
    vim.lsp.buf.format({ timeout_ms = 200 })
  end,
  group = format_sync_grp,
})

