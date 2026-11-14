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
    -- Lines moved per mouse-wheel notch (Neovim's own default is 3).
    scroll = {
      wheel = 6,
      wheel_horizontal = 8,
    },
    search = {
      -- Folders skipped by file and text search (Space Space, Space /), like
      -- VS Code's search.exclude. Everything else the explorer shows is
      -- searched, including dotfiles and files ignored by .gitignore.
      exclude = { ".git", "node_modules" },
    },
    -- Reload open files the moment another program (an AI CLI, a formatter,
    -- git) changes them on disk. Buffers with unsaved edits are never touched.
    auto_reload = true,
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
      -- Parsers installed by :InstallParsers in addition to those of enabled languages.
      extra_parsers = { "markdown", "markdown_inline", "vim", "vimdoc", "query", "json", "toml", "diff", "gitcommit" },
      -- Filetypes highlighted when a parser is present, in addition to enabled languages.
      extra_filetypes = { "markdown", "vim", "help", "query", "json", "jsonc", "toml", "diff", "gitcommit" },
    },
    mason = {
      -- Mason installs language servers, linters and formatters into
      -- ~/.local/share/nvim/mason. Its bin directory is appended to PATH, so
      -- tools you installed yourself keep priority.
      enabled = true,
      -- When you open a file whose tools are missing:
      --   "ask"    offer to install them (once per language)
      --   "always" install them right away
      --   "never"  only show how to install them
      auto_install = "ask",
    },
    completion = {
      -- Open the suggestion list by itself while you type. Off: Ctrl+Space
      -- opens it.
      auto_show = false,
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
    -- Popup listing the next keys after <leader> or another prefix (which-key).
    key_hints = true,
    -- Git blame at the end of the current line: "Ana, 3 weeks ago • Fix login".
    -- Toggle with Space g t.
    line_blame = true,
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
      -- Show dotfiles (.env, .github, …).
      show_hidden = true,
      -- Show files ignored by .gitignore (dimmed, like VS Code).
      show_gitignored = true,
      git_status = true,
      diagnostics = false,
      -- Update the tree when files are created or deleted outside Neovim.
      watch = true,
      -- Buttons above the tree: New File, New Folder, Refresh, Collapse All.
      header = true,
      -- Names never shown, e.g. { ".git", "node_modules" }. Shift+H in the
      -- explorer shows them anyway.
      hide = {},
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
    -- Column beside the editor for the Git graph, the changed files or the
    -- terminal, one at a time (Space s). Alt+2 puts the cursor in it.
    side_panel = {
      position = "right", -- right | left
      width = 60,
      -- Update the Git graph and the changed files as soon as Git or the
      -- files change (a commit or `rm` in a shell, a file saved, …).
      watch = true,
    },
    terminal = {
      enabled = true,
      position = "bottom", -- bottom | top | left | right | float
      height = 12,
      width = 80,
      -- Shell to start; "" uses Neovim's 'shell' (your $SHELL), e.g. "fish" or "zsh -l".
      shell = "",
      -- Header with the shell, its folder and New / Hide / Kill buttons.
      winbar = true,
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
    csharp = { enabled = true },
    css = { enabled = true },
    dart = { enabled = true },
    docker = { enabled = true },
    elixir = { enabled = true },
    go = { enabled = true },
    graphql = { enabled = true },
    html = { enabled = true },
    java = { enabled = true },
    json = { enabled = true },
    kotlin = { enabled = true },
    lua = { enabled = true },
    markdown = { enabled = true },
    nix = { enabled = true },
    php = { enabled = true },
    prisma = { enabled = true },
    python = { enabled = true },
    ruby = { enabled = true },
    rust = { enabled = true },
    sql = { enabled = true },
    svelte = { enabled = true },
    swift = { enabled = true },
    terraform = { enabled = true },
    toml = { enabled = true },
    typescript = { enabled = true },
    yaml = { enabled = true },
    zig = { enabled = true },
  },

  -- ~/.config/wraithvim/plugins.lua contributes `specs`; `disable` lists plugin names.
  plugins = {
    disable = {},
  },

  -- ~/.config/wraithvim/keymaps.lua contributes extra mappings; `disable` lists lhs to remove.
  keymaps = {
    -- "default" keeps Neovim's own keys; "vscode" adds VS Code shortcuts and
    -- VS Code-style selection (see docs/keymaps.md).
    preset = "default",
    disable = {},
  },
}
