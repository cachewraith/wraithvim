# Changelog

All notable changes to WraithVim are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

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

[Unreleased]: https://github.com/cachewraith/wraithvim/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/cachewraith/wraithvim/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/cachewraith/wraithvim/releases/tag/v0.1.0
