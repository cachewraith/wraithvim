# Configuration reference

Personal settings live in `~/.config/wraithvim/` (or `$XDG_CONFIG_HOME/wraithvim`,
or the directory in `$WRAITHVIM_CONFIG_DIR`). Every file is optional and returns
a Lua table. Updates never touch this directory.

| File | Loaded | Purpose |
|---|---|---|
| `options.lua` | after WraithVim's vim options | editor behaviour, formatting, LSP, Treesitter, Mason, extra vim options |
| `ui.lua` | before plugins | preset, theme, icons, panels |
| `languages.lua` | before plugins | enable/disable and customise languages |
| `plugins.lua` | before plugins | extra lazy.nvim specs, disabled plugins |
| `keymaps.lua` | after WraithVim's mappings | extra mappings, removed mappings |

Tables are **deep-merged** over the defaults: you only write the keys you
change. Lists replace the default list instead of being appended to.

## Validation and errors

Before use, WraithVim checks each file against the defaults:

- a syntax or runtime error in a file is reported and that file is ignored;
- a value of the wrong type (e.g. `width = "wide"`) is reported and the default
  is used;
- unknown keys (typos) are reported but kept;
- a file that returns something other than a table is reported and ignored.

Problems appear as a notification at startup and in `:Health`. WraithVim
always finishes starting.

## options.lua

```lua
return {
  leader = " ",
  localleader = "\\",
  system_clipboard = true,          -- clipboard=unnamedplus, set after startup
  large_file_size = 1536 * 1024,    -- bytes; larger files skip Treesitter, syntax, format-on-save
  scroll = {
    wheel = 6,                      -- lines per mouse-wheel notch (Neovim's default is 3)
    wheel_horizontal = 8,
  },
  auto_reload = true,               -- reload open files changed by other programs (never unsaved ones)
  format = {
    on_save = false,                -- opt-in format on save
    timeout_ms = 1000,
    lsp_fallback = true,            -- use the LSP formatter when no conform formatter applies
  },
  lsp = {
    notify_missing = true,          -- one hint per session when a file's server is not installed
    inlay_hints = false,            -- enable inlay hints on attach (toggle with <leader>lH)
  },
  diagnostics = {
    virtual_text = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
  },
  treesitter = {
    highlight = true,
    indent = false,                 -- nvim-treesitter's indent is experimental upstream
    folds = false,                  -- Treesitter folding (foldlevel 99)
    extra_parsers = { "markdown", "markdown_inline", "vim", "vimdoc", "query", "json", "toml", "diff", "gitcommit" },
    extra_filetypes = { "markdown", "vim", "help", "query", "json", "jsonc", "toml", "diff", "gitcommit" },
  },
  mason = {
    enabled = false,                -- see languages.md
  },
  opt = {},                         -- any vim option, e.g. { relativenumber = true, wrap = true }
}
```

You may also call `vim.opt`, `vim.g` or `vim.api` directly in `options.lua`;
it runs after WraithVim's own vim options are set.

### Files changed by other programs

With `auto_reload = true` (the default), WraithVim watches the folder of every
open file through the operating system (inotify on Linux, no polling). When an
AI CLI, a formatter or `git checkout` changes a file you have open, the buffer
reloads within a fraction of a second and a notification names the file.

A buffer with unsaved edits is never replaced. You get a warning instead, and
choose: `:DiffDisk` shows your version and the disk version side by side,
`:e!` loads the disk version, `:w` keeps yours. A file deleted on disk keeps
its buffer; `:w` writes it back.

## ui.lua

Merged in this order: defaults → preset → `ui.lua`.

```lua
return {
  preset = "default",                -- default | compact | minimal
  theme = {
    colorscheme = "tokyonight",      -- any installed colorscheme
    style = "night",                 -- tokyonight: night | storm | moon | day
    transparent = false,
  },
  icons = { nerd_font = true },      -- false = ASCII icons, no devicons
  border = "rounded",                -- floating window borders
  key_hints = true,                  -- popup listing the next keys after Space (which-key)
  separators = "default",            -- default | slant | round | none
  colors = {},                       -- { GroupName = { fg = "#..", bg = "..", bold = true } }
  explorer = {
    enabled = true,
    position = "left",               -- left | right | float
    width = 30,
    auto_open = true,                -- show after startup when files/dirs are given (needs >= 100 columns)
    single_click = true,
    show_hidden = true,              -- dotfiles (gitignored files stay hidden)
    git_status = true,
    diagnostics = false,
    watch = true,                    -- update the tree when files change outside Neovim
    header = true,                   -- New File / New Folder / Refresh / Collapse buttons above the tree
    hide = { ".git", "node_modules", "__pycache__", ".mypy_cache", ".pytest_cache", ".DS_Store" },
  },
  tabline = {
    enabled = true,
    header = true,                   -- project name + Git branch on the right
    close_icons = true,
    diagnostics = true,
    always_show = true,
  },
  statusline = {
    enabled = true,
    global = true,                   -- one statusline for all windows
    lsp = true,
    diff = true,
    diagnostics = true,
    encoding = true,
  },
  terminal = {
    enabled = true,
    position = "bottom",             -- bottom | top | left | right | float
    height = 12,
    width = 80,
    shell = "",                      -- "" = your $SHELL; e.g. "fish" or "zsh -l"
    winbar = true,                   -- header with shell, folder and New/Hide/Kill buttons
  },
  dashboard = { enabled = true },
  notifications = {
    enabled = true,                  -- false = Neovim's built-in message area
    timeout = 3000,                  -- ms (errors stay twice as long)
    max_width = 60,
    level = vim.log.levels.INFO,     -- minimum level shown
  },
}
```

`colors` overrides are applied after every `:colorscheme`, so they also work
with other themes. See [ui-layout.md](ui-layout.md) for the presets.

## languages.lua

```lua
return {
  go = false,                                 -- shorthand for { enabled = false }
  python = { enabled = true },
  javascript = { enabled = true },            -- alias of `typescript`; `c` is an alias of `cpp`

  php = {
    servers = {
      intelephense = {                        -- extend the server's vim.lsp.config
        config = { settings = { intelephense = { format = { enable = false } } } },
      },
    },
    formatters = { pint = false },            -- false removes an entry
  },

  lua = { lsp = false },                      -- keep formatting, drop the server
  sql = { format = false },                   -- keep the server, drop formatting

  -- a custom language profile
  zig = {
    filetypes = { "zig" },
    parsers = { "zig" },
    servers = { zls = { cmd = "zls" } },                    -- nvim-lspconfig name + executable
    formatters = { zigfmt = { cmd = "zig", filetypes = { "zig" } } }, -- conform.nvim formatter name
  },
}
```

Each server entry accepts `cmd` (executable to look for), `mason` (Mason
package name), `install` (hint shown when missing) and `config` (passed to
`vim.lsp.config(name, config)`). Servers unknown to nvim-lspconfig get
`cmd = { <cmd> }` and the profile's filetypes automatically. Formatter entries
accept `cmd`, `mason`, `install` and `filetypes`. The key is the conform.nvim
formatter name.

## plugins.lua

```lua
return {
  -- disable bundled plugins by name
  disable = { "flash.nvim" },

  -- add plugins (any lazy.nvim spec)
  { "folke/todo-comments.nvim", event = "BufReadPost", opts = {} },

  -- reconfigure a bundled plugin: lazy.nvim merges specs with the same name
  { "folke/tokyonight.nvim", opts = { styles = { comments = { italic = false } } } },
  { "saghen/blink.cmp", opts = { keymap = { preset = "default" } } },
}
```

WraithVim sets lazy.nvim's `defaults.lazy = true`: give added plugins a
trigger (`event`, `cmd`, `keys`, `ft`) or `lazy = false`, otherwise they load
only when their Lua module is first required.

Mappings that belong to a plugin disabled through `disable` (or through a spec
with `enabled = false`) are skipped automatically. When neo-tree is disabled
with `disable = { "neo-tree.nvim" }` or `ui.explorer.enabled = false`, Neovim's
netrw is re-enabled.

## keymaps.lua

```lua
return {
  preset = "default",                              -- or "vscode": VS Code shortcuts and selection
  disable = { "s", "S", { "n", "<leader>wv" } },   -- lhs (all modes) or { mode(s), lhs }
  { "n", "<leader>qq", "<cmd>qa<cr>", desc = "Quit all" },
  { { "n", "x" }, "<leader>y", '"+y', desc = "Yank to clipboard" },
}
```

Each entry is `{ mode(s), lhs, rhs, desc = ..., <vim.keymap.set options> }`.
`disable` also applies to LSP buffer mappings. See [keymaps.md](keymaps.md).

## Environment variables

| Variable | Effect |
|---|---|
| `WRAITHVIM_CONFIG_DIR` | Use another directory for personal settings |
| `WRAITHVIM_DIR` | Override the distribution location used by the bootstrap |
| `NVIM_APPNAME` | Standard Neovim variable; use with `install.sh --appname` |

## Lua API

`require("wraithvim").setup(opts)` accepts:

| Field | Meaning |
|---|---|
| `root` | Distribution directory (set by `init.lua`) |
| `config` | Table with the same shape as the user files (`{ options = …, ui = …, languages = …, plugins = …, keymaps = … }`), merged **over** the user files |
| `plugins` | `false` to skip lazy.nvim entirely |

`require("wraithvim.core.config").get()` returns the effective configuration.
