# Changelog

All notable changes to WraithVim are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.7.0] - 2026-11-12

### Added

- Open files reload by themselves when another program changes them (an AI
  CLI, a formatter, `git checkout`), within a fraction of a second. Uses the
  operating system's file events, no polling. Buffers with unsaved edits are
  never replaced: you get a warning, and `:DiffDisk` compares your version with
  the one on disk. Option `auto_reload` (#3).
- The explorer updates when files are created or deleted outside Neovim
  (`explorer = { watch = true }`).
- Faster scrolling (#1): the mouse wheel moves 6 lines per notch (option
  `scroll`), `Ctrl+D` / `Ctrl+U` keep the cursor in the middle, `Alt+J` /
  `Alt+K` jump 10 lines, and `}` / `{` jump between folders in the explorer.
- Git graph actions (#2): `d` diffs the commit, `c` checks it out (asks
  first), `y` copies its hash, `q` closes, `?` lists every key. A header in the
  graph shows them.
- `Space g Shift+G` and `:GitGraphAll` show every branch.

### Changed

- The Git graph is easier to read (#2): one commit per line with hash,
  branches, message, author and a relative date ("2 days ago"), clearer branch
  and tag colors. `Space g g` / `:GitGraph` now show the current branch; press
  `a` in the graph to add the others.

## [0.6.1] - 2026-11-12

### Added

- Every GitHub release gets a `wraithvim.tar.gz` asset (release workflow), so
  downloads are counted; `releases/latest/download/wraithvim.tar.gz` always
  points at the newest one.

### Changed

- `install.sh` run from a downloaded archive clones the repository, giving an
  updatable Git install instead of a plain copy (falls back to copying when
  offline).

## [0.6.0] - 2026-11-12

### Added

- Actions palette (like VS Code's Command Palette): `Space p`, `:Actions`,
  and in the VS Code preset `F1` / `Ctrl+Shift+P`. Search any action by name
  and press Enter; each entry shows its key.
- Commands `:Explorer`, `:FindFile`, `:Search` and `:CloseTab`.

### Changed

- Keys are shown in plain words in the cheatsheet, the palette and the docs:
  `Space g Shift+P` instead of `<leader>gP`, `Ctrl+S` instead of `<C-s>`.
  docs/keymaps.md explains how to read them.

## [0.5.0] - 2026-11-12

### Added

- Git graph: `<leader>gg` / `:GitGraph` shows a commit graph of all branches
  (vim-flog); `<CR>` opens a commit, `gq` closes.
- Key-hint popup (which-key): press `Space` and wait to see every next key.
  Turn off with `key_hints = false` in `ui.lua`.
- "Update & tools" keys: `<leader>uu` update, `<leader>uh` health,
  `<leader>up` plugins, `<leader>uc` settings folder, `<leader>ul` log,
  `<leader>un` notifications, `<leader>ut` parsers, `<leader>um` Mason tools.
- Quick single keys: `<leader><space>` find file, `<leader>/` search text,
  `<leader>,` switch tab, `<leader>x` close tab, `<leader>q` quit.

### Changed (breaking)

- `<leader>e` toggles the explorer (was `<leader>ee`), `<leader>E` reveals the
  current file (was `<leader>ef`), explorer Git changes moved to `<leader>ge`.
  `<leader>eb`, `<leader>e>` and `<leader>e<` were removed (use `<leader>,`,
  mouse dragging or `<leader>w>`/`<leader>w<`).
- `<leader>t` toggles the terminal (was `<leader>tt`); the other terminal keys
  moved to `<leader>T…` (`Tn`, `Th`, `Tv`, `Tf`, `Tc`).
- `<leader>fd` was removed; format with `<leader>cf`.
- Clearer descriptions for all mappings.

## [0.4.0] - 2026-11-12

### Added

- VS Code-style terminal panel: a header showing the shell and its folder
  with clickable **New**, **Hide** and **Kill** buttons; a readable statusline
  (shell, folder, and a hint for the current mode) instead of the raw
  `term://…` name and `[RO]`.
- Entering a terminal window or clicking inside it starts typing.
- `:TerminalNew` / `<leader>tn`: another terminal beside the panel.
- `ui.terminal.shell` to choose the shell (e.g. `"fish"`), `ui.terminal.winbar`
  to hide the header. The header follows `cd` for shells that emit OSC 7.

### Changed

- The shell starts directly instead of through an extra `sh -c` process.

### Fixed

- WraithVim highlight groups (dashboard, terminal header) survive
  `:colorscheme` changes.

## [0.3.0] - 2026-11-11

### Changed (breaking)

- Commands no longer carry a `Wraith` prefix. Old → new:
  `WraithUpdate` → `Update`, `WraithHealth` → `Health`, `WraithLog` → `Log`,
  `WraithProfile` → `Profile`, `WraithBenchmark` → `Benchmark`,
  `WraithConfig` → `Config`, `WraithKeys` → `Keys`,
  `WraithNotifications` → `Notifications`, `WraithBufferCleanup` → `BufferCleanup`,
  `WraithTerminal[Split|Close]` → `Terminal[Split|Close]`,
  `WraithGit*` → `Git*` (`GitStatus`, `GitDiff`, `GitCommit`, `GitPush`, …),
  `WraithConflict*` → `Conflict*`, `WraithFormat[Toggle]` → `Format[Toggle]`,
  `WraithTSInstall` → `InstallParsers`, `WraithInstallTools` → `InstallTools`.
  A test guarantees none of them clashes with Neovim or bundled plugin commands.

### Added

- `` Ctrl+Shift+` `` opens (or focuses) the terminal at the bottom, in normal,
  insert and terminal mode, for every keymap preset.

### Fixed

- Opening a terminal (or switching windows) right after startup could be
  undone when the explorer finished its startup render and returned focus to
  the editor.

## [0.2.0] - 2026-11-11

### Added

- VS Code keymap preset: `return { preset = "vscode" }` in
  `~/.config/wraithvim/keymaps.lua` adds Ctrl+P, Ctrl+Shift+P/F1, Ctrl+Shift+F,
  Ctrl+F, Ctrl+G, Ctrl+B, Ctrl+`, Ctrl+\, Ctrl+Tab/Ctrl+PgDn, Ctrl+W,
  Ctrl+Z/Y, Ctrl+A, Ctrl+C/X/V, Ctrl+/, Alt+Up/Down, Shift+Alt+Up/Down, F2,
  F12, Shift+F12, Ctrl+., F8, Shift+Alt+F and more, plus VS Code-style
  selection (Shift+Arrows and mouse drags select; typing replaces). Keys work
  in classic terminals and with the kitty keyboard protocol.
- `<leader>?` lists the VS Code keys when the preset is enabled.

### Changed

- `:WraithUpdate` only syncs plugins (and opens the lazy.nvim window) when the
  update changed `lazy-lock.json`.

## [0.1.1] - 2026-11-11

### Fixed

- First start no longer shows `Error during "tree-sitter build"` when Treesitter
  parsers from a previous configuration exist in `~/.local/share/nvim/site`
  and the tree-sitter CLI is not installed. Installed parsers are rebuilt after
  plugin updates only when the CLI is available.
- `install.sh` detected installed Nerd Fonts as missing on most systems (a
  `fc-list | grep -q` pipeline failed under `pipefail`) and wrote
  `icons = { nerd_font = false }` to `~/.config/wraithvim/ui.lua`. Existing
  installs: set `nerd_font = true` in that file if you use a Nerd Font.
- `:WraithUpdate` reports "up to date" instead of always asking for a restart,
  and explains when the checkout is pinned to a release tag.

## [0.1.0] - 2026-11-11

First public release.

### Added

- Modular Lua distribution for Neovim 0.12+ with lazy.nvim and pinned plugins
  (`lazy-lock.json`).
- User configuration in `~/.config/wraithvim/` (`options`, `ui`, `languages`,
  `plugins`, `keymaps`) with validation and helpful error messages.
- UI: TokyoNight, lualine with event-driven refresh (no polling timers),
  bufferline with project/branch header, neo-tree with single-click and
  ASCII fallback, dashboard, floating notifications, `default`/`compact`/
  `minimal` presets.
- Mouse support for tabs, explorer, splits, scrolling, selection, statusline
  items, dashboard and terminal, covered by pty-driven tests.
- Native terminal panel and split terminals (`:WraithTerminal*`).
- Native LSP (`vim.lsp.config`/`vim.lsp.enable`) with nvim-lspconfig
  definitions, blink.cmp completion, conform.nvim formatting (format-on-save
  opt-in), on-demand Treesitter highlighting with nvim-treesitter `main` for
  parser installation.
- Language profiles: PHP, JavaScript/TypeScript, Java, Python, Go, C/C++,
  Lua, SQL, Bash, YAML, plus custom profiles. Optional Mason with
  confirmation-only installs.
- Git: gitsigns, fugitive, diffview, and a three-way conflict resolver built on
  Git index stages (`:WraithConflict*`).
- `:WraithHealth`, `:WraithLog`, `:WraithUpdate`, `:WraithProfile`,
  `:WraithBenchmark` and other `:Wraith*` commands.
- `install.sh` (dry-run, check, backups, idempotent, `--appname`, `--link`),
  `uninstall.sh` (confirmations, user data preserved).
- Plenary Busted test suite (unit, installer, headless and real-TUI
  integration), StyLua, Luacheck, ShellCheck, GitHub Actions, benchmark script.

[Unreleased]: https://github.com/cachewraith/wraithvim/compare/v0.7.0...HEAD
[0.7.0]: https://github.com/cachewraith/wraithvim/compare/v0.6.1...v0.7.0
[0.6.1]: https://github.com/cachewraith/wraithvim/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/cachewraith/wraithvim/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/cachewraith/wraithvim/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/cachewraith/wraithvim/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/cachewraith/wraithvim/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/cachewraith/wraithvim/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/cachewraith/wraithvim/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/cachewraith/wraithvim/releases/tag/v0.1.0
