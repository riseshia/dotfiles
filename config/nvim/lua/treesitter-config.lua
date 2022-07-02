require'nvim-treesitter.configs'.setup {
  -- A directory to install the parsers into.
  -- If this is excluded or nil parsers are installed
  -- to either the package dir, or the "site" dir.
  -- If a custom path is used (not nil) it must be added to the runtimepath.
  -- parser_install_dir = "/some/path/to/store/parsers",

  -- A list of parser names, or "all"
  ensure_installed = {
    "graphql",
    "javascript",
    "json5",
    "ruby",
    "rust",
    "tsx",
    "typescript",
    "vim",
  },

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,
  -- List of parsers to ignore installing (for "all")
  -- ignore_install = { "javascript" },

  highlight = {
    -- `false` will disable the whole extension
    enable = true,
    -- list of language that will be disabled
    -- disable = { "c", "rust" },

    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },
}
-- vim.opt.runtimepath:append("/some/path/to/store/parsers")
