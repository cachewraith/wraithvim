# Architecture

## Startup sequence

`~/.config/nvim/init.lua` (the generated bootstrap) runs
`~/.local/share/wraithvim/init.lua`, which enables `vim.loader`, puts the
distribution on the runtimepath and calls `require("wraithvim").setup()`:

1. **Built-in options** (`config/options.lua → apply_defaults`). These run
   before any user file, so direct `vim.opt` calls in `options.lua` win.
2. **Version check** (`core/bootstrap.lua`). On Neovim < 0.12 WraithVim prints
   an error and stops after step 1.
3. **Configuration** (`core/config.lua`). Loads `options.lua`, `ui.lua`,
   `languages.lua` and `plugins.lua` from `~/.config/wraithvim/`, merges them
   over `config/defaults.lua` and the selected UI preset, and validates them.
   Errors become warnings; invalid values fall back to defaults.
4. **lazy.nvim** (`core/plugin_manager.lua`). Bootstraps lazy.nvim if needed
   and registers the plugin specs. Every plugin is lazy. Background update
   checks and config-file watching are disabled.
5. **Native setup**: diagnostics, the Treesitter `FileType` hook, autocommands,
   `:Wraith*` commands, keymaps (then the user's `keymaps.lua`).
6. **UI** (`ui/init.lua`): colorscheme (loads TokyoNight on demand),
   notifications, dashboard, explorer auto-open scheduled for `VeryLazy`.

At the end of startup only lazy.nvim and the colorscheme are loaded. lualine,
bufferline and (when a file was given) neo-tree load on `VeryLazy`, right after
the first screen is drawn.

## Directory layout

```text
init.lua                       entry point
lazy-lock.json                 pinned plugin commits
lua/wraithvim/
  init.lua                     setup sequence above
  health.lua                   :checkhealth wraithvim (must live at this path)
  core/
    bootstrap.lua              version check, lazy.nvim clone, plugin directory
    config.lua                 user file loading, merging, validation
    plugin_manager.lua         lazy.nvim options, spec assembly, plugin disable
    logger.lua                 file log with redaction, :WraithLog
    performance.lua            stats, :WraithProfile, :WraithBenchmark
    update.lua                 :WraithUpdate
    utils.lua                  merge, cached executable lookup, shell-free process runner
  config/
    defaults.lua               every default setting (documented in configuration.md)
    options.lua                vim options
    keymaps.lua                single keymap registry + user keymaps
    autocmds.lua               core autocommands (all in named augroups)
    commands.lua               :Wraith* commands
  ui/
    init.lua                   theme, colors, panels, dashboard, notifications
    presets/{default,compact,minimal}.lua
    icons.lua                  Nerd Font and ASCII icon sets
    statusline.lua             lualine options + event-driven refresh
    tabline.lua                bufferline options + header
    explorer.lua               neo-tree options + single-click handler
    dashboard.lua              start screen (no plugin)
    notifications.lua          vim.notify replacement (no plugin)
  features/
    explorer.lua search.lua buffers.lua terminal.lua
    git.lua conflicts.lua diagnostics.lua
  languages/
    registry.lua               builtin list, aliases, profile resolution
    init.lua                   enabled profiles and derived data
    <language>.lua             one profile per language
  integrations/
    lsp.lua formatter.lua treesitter.lua mason.lua
  plugins/
    init.lua                   explicit list of spec modules
    ui/ editor/ completion/ lsp/ git/ syntax/   one spec per plugin
```

Deviations from the original proposal, and why:

- `health.lua` sits at `lua/wraithvim/health.lua` because that is where
  `:checkhealth wraithvim` looks.
- Plugin-specific UI options live in `ui/statusline.lua`, `ui/tabline.lua` and
  `ui/explorer.lua` rather than `ui/components/`. Terminal behaviour is a
  feature (`features/terminal.lua`). A separate `layout.lua` was not needed:
  presets are plain configuration tables merged by `core/config.lua`.
- `:Wraith` commands live only in `config/commands.lua`, so there is no
  duplicate `features/commands.lua`.
- `integrations/` holds one file per integration; subdirectories would add
  nothing.

## Design rules

- **Lazy everything.** Plugin specs are pure data; option builders such as
  `ui/statusline.lua` run only when the plugin loads. Keymaps call `require()`
  inside the mapping, and lazy.nvim loads the plugin on first use.
- **One source of truth.** Keymaps come from one registry (tested for
  duplicates and documentation). Language data comes from profiles; LSP,
  conform, Treesitter, Mason and health all derive from them.
- **No polling.** No repeating timers while idle. The statusline refreshes on
  events (`ModeChanged`, `BufEnter`, `DiagnosticChanged`, `LspAttach`,
  `GitSignsUpdate`, …), coalesced to at most one refresh per event-loop tick.
  Cursor position uses `%l`/`%P`, which Neovim evaluates itself. Notifications
  use one one-shot timer per visible message.
- **No shell.** Every external command is an argument list passed to
  `vim.system()`, so filenames are never interpreted by a shell.
- **Fail soft.** Missing optional tools, plugins or user files produce
  messages, not errors. A broken plugin setup still leaves a usable editor.
- **Augroups everywhere.** Every autocommand lives in a named augroup created
  with `clear = true`, so nothing is registered twice.

## Plugins

| Plugin | Role | Loads on |
|---|---|---|
| lazy.nvim | plugin manager | startup |
| tokyonight.nvim | colorscheme | `:colorscheme` (startup) |
| lualine.nvim | statusline | `VeryLazy` |
| bufferline.nvim | buffer tabs | `VeryLazy` |
| neo-tree.nvim (+ plenary, nui) | explorer | `:Neotree`, explorer keys, directory argument, auto-open |
| nvim-web-devicons | icons (Nerd Font only) | dependency |
| telescope.nvim (+ fzf-native when make/cc exist) | search | `:Telescope`, search keys |
| flash.nvim | jump labels | `s`, `S`, `r` |
| blink.cmp (+ friendly-snippets) | completion, signature help | `InsertEnter`, `CmdlineEnter`, or first file (LSP capabilities) |
| nvim-lspconfig | server definitions | first file opened |
| mason.nvim | optional tool installer | `:Mason` (only when enabled) |
| gitsigns.nvim | signs, hunks, blame | first file opened |
| vim-fugitive | Git porcelain | `:Git` and Git keys |
| diffview.nvim | diffs, history | `:Diffview*` and Git keys |
| nvim-treesitter (`main`) | parser installation | `:TSInstall`, `:WraithTSInstall` |
| conform.nvim | formatting | first save, format keys |

LuaSnip was not added: blink.cmp expands snippets with Neovim's built-in
`vim.snippet`, and friendly-snippets provides the snippet collection.
