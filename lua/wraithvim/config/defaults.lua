-- Default WraithVim configuration.
--
-- Every key here is documented in docs/configuration.md. User files in
-- ~/.config/wraithvim/ are deep-merged on top of these tables (lists replace).
-- Keys listed in `open_tables` (config.lua) accept arbitrary children.

return {
  -- ~/.config/wraithvim/options.lua
  options = {
    leader = " ",
    localleader = "\\",
    -- Use the system clipboard for yank/paste. Enabled after startup because
    -- clipboard provider detection can spawn processes.
    system_clipboard = true,
    -- Files larger than this (bytes) skip Treesitter and other per-buffer work.
    large_file_size = 1536 * 1024,
    format = {
      on_save = false,
      timeout_ms = 1000,
      -- Use the LSP formatter when no conform formatter is configured.
      lsp_fallback = true,
    },
    lsp = {
      -- Show a one-time hint when a file is opened whose server is not installed.
      notify_missing = true,
      inlay_hints = false,
    },
    diagnostics = {
      virtual_text = true,
      underline = true,
      update_in_insert = false,
      severity_sort = true,
    },
    treesitter = {
      highlight = true,
      indent = false, -- nvim-treesitter indentation is experimental upstream
      folds = false,
      -- Parsers installed by :WraithTSInstall in addition to those of enabled languages.
      extra_parsers = { "markdown", "markdown_inline", "vim", "vimdoc", "query", "json", "toml", "diff", "gitcommit" },
      -- Filetypes highlighted when a parser is present, in addition to enabled languages.
      extra_filetypes = { "markdown", "vim", "help", "query", "json", "jsonc", "toml", "diff", "gitcommit" },
    },
    mason = {
      -- Optional. When enabled, Mason's bin directory is appended to PATH so
      -- system-installed tools keep priority. Nothing is installed without
      -- running :WraithInstallTools and confirming.
      enabled = false,
    },
    -- Extra Neovim options applied after WraithVim's defaults, e.g. { relativenumber = true }.
    opt = {},
  },

  -- ~/.config/wraithvim/ui.lua (merged on top of the selected preset)
  ui = {
    preset = "default",
    theme = {
      colorscheme = "tokyonight",
      style = "night", -- night | storm | moon | day
      transparent = false,
    },
    icons = {
      -- Set to false when your terminal font is not a Nerd Font; ASCII fallbacks are used.
      nerd_font = true,
    },
    border = "rounded", -- none | single | double | rounded | solid | shadow
    separators = "default", -- default | slant | round | none
    -- Highlight overrides applied after every colorscheme load: { GroupName = { fg = "#ffffff" } }
    colors = {},
    explorer = {
      enabled = true,
      position = "left", -- left | right | float
      width = 30,
      -- Open the explorer after startup when Neovim is started with a file or directory.
      auto_open = true,
      -- Single left click opens files and toggles directories (VS Code style).
      single_click = true,
      show_hidden = true,
      git_status = true,
      diagnostics = false,
      hide = { ".git", "node_modules", "__pycache__", ".mypy_cache", ".pytest_cache", ".DS_Store" },
    },
    tabline = {
      enabled = true,
      -- Right-hand header with project name and Git branch.
      header = true,
      close_icons = true,
      diagnostics = true,
      always_show = true,
    },
    statusline = {
      enabled = true,
      global = true,
      lsp = true,
      diff = true,
      diagnostics = true,
      encoding = true,
    },
    terminal = {
      enabled = true,
      position = "bottom", -- bottom | top | left | right | float
      height = 12,
      width = 80,
    },
    dashboard = {
      enabled = true,
    },
    notifications = {
      enabled = true,
      timeout = 3000,
      max_width = 60,
      level = vim.log.levels.INFO,
    },
  },

  -- ~/.config/wraithvim/languages.lua. Missing entries use these values.
  -- Servers and formatters only start when their executable is installed.
  languages = {
    bash = { enabled = true },
    cpp = { enabled = true },
    go = { enabled = true },
    java = { enabled = true },
    lua = { enabled = true },
    php = { enabled = true },
    python = { enabled = true },
    sql = { enabled = true },
    typescript = { enabled = true },
    yaml = { enabled = true },
  },

  -- ~/.config/wraithvim/plugins.lua contributes `specs`; `disable` lists plugin names.
  plugins = {
    disable = {},
  },

  -- ~/.config/wraithvim/keymaps.lua contributes extra mappings; `disable` lists lhs to remove.
  keymaps = {
    disable = {},
  },
}
