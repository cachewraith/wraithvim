# Changelog

All notable changes to WraithVim are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.13.1] - 2026-11-12

### Fixed

- Opening a Rust file no longer shows "Client rust_analyzer quit with exit
  code 1" when rustup is installed without its rust-analyzer component.
  WraithVim now sees that rust-analyzer is missing and offers to install it,
  and `:Health` reports it as missing instead of OK. The same goes for other
  rustup tools such as `rustfmt`.

## [0.13.0] - 2026-11-12

### Added

- Side panel: a column beside the editor (right by default, or left) that
  shows the Git graph (`Space s g`), the changed files (`Space s c`; Enter
  opens, `d` diffs, `ga`/`gu` stage) or the terminal (`Space s t`), one at a
  time, like VS Code's secondary side bar. `Space s s` hides / shows it,
  `Space s m` moves it to the other side; `:SidePanel graph left` as a
  command; `side_panel` in `ui.lua` sets the default side and width.
- Move the cursor between panels from any mode, even from inside a
  terminal: `Alt+1` code, `Alt+2` side panel, `Alt+3` terminal, `Alt+0`
  explorer. The VS Code preset adds `Ctrl+1`, `Ctrl+0` and `Ctrl+Alt+B`.
- `:Terminal right` (or any other place) moves a visible terminal there with
  the same shell; hidden, it comes back where it was.

### Fixed

- `uninstall.sh --dir path/` with a trailing slash could delete the contents
  of a checkout installed with `--link`; it now removes only the link.
- Git actions on files with `[`, `*` or `?` in their name (e.g. Next.js
  `[id].tsx`) could also stage, unstage or delete files with similar names.
  Resolving a "deleted by them" conflict could remove unrelated files.
- `install.sh --dir ~/.config/nvim` is refused instead of producing a broken
  install; a failed clone puts back what it moved aside, and archives
  extracted inside another Git folder install again.
- Merge conflicts in Windows (CRLF) files are found, so they are no longer
  staged with conflict markers; a `========` Markdown underline is no longer
  mistaken for a conflict separator.
- Syntax colors for `.tsx`, `.jsx`, shell scripts, C#, `tsconfig.json` and
  other files whose filetype differs from their parser name.
- Hiding the terminal from another tab no longer empties the file in that tab;
  "New terminal" works when the terminal is floating.
- The VS Code preset no longer replaces keys you map yourself in
  `keymaps.lua`; `mapleader`, clipboard and other options set directly in
  `options.lua` are no longer overwritten.
- `:'<,'>Format` includes the last selected line with language servers.
- `:Update` reinstalls the pinned plugins after resetting `lazy-lock.json`.
- Staging a new, unsaved file in another repository than the current folder.
- Text search after changing folder without ripgrep installed.
- Custom language profiles without a `description` no longer break the
  install prompt, and their servers attach only to their own filetypes.
- Notifications from mappings no longer error; wide (CJK) text wraps to the
  window; `%` in folder or branch names no longer breaks the tabline.
- The statusline updates after `:set ff=…`, `:file` and `cd` in the terminal.
- Command completion narrows to what you typed; `keymaps.disable` matches
  keys however they are written; a misspelled language name turned off in
  `languages.lua` is reported; older Neovim versions show the "requires
  0.12" message instead of an error.

## [0.12.0] - 2026-11-12

### Added

- Line blame like GitLens: the end of the current line shows who changed it,
  when and the commit message ("Ana, 3 weeks ago • Fix login"), or
  "You • Uncommitted changes". On by default (`ui.line_blame`); `Space g t`
  hides / shows it, `Space g Shift+B` shows the full commit. It updates when
  the cursor moves and does nothing while idle.

## [0.11.0] - 2026-11-12

### Added

- Opening a file offers to install what its language needs, once per
  language: the language server (completion, errors), linters, the formatter
  and the Treesitter parser. Tools install through Mason in the background and
  the server starts in the open file without a restart. Missing toolchains
  (Node.js, Go, …) are named in the prompt. `options.mason.auto_install =
  "ask" | "always" | "never"`.
- 19 more languages: Rust, HTML (with Emmet), CSS/SCSS/Less, JSON, Markdown,
  Dockerfile, TOML, C#, Ruby, Kotlin, Zig, Terraform/HCL, GraphQL, Svelte,
  Elixir, Prisma, Nix, Dart/Flutter and Swift (29 in total).
- Lint: ESLint for JavaScript/TypeScript, Ruff for Python, staticcheck in
  gopls, Clippy in rust-analyzer, clang-tidy in clangd, ShellCheck for Bash.

### Changed

- Mason is enabled by default. Tools you installed yourself still win.
- Headless runs never offer or start installs.

## [0.10.1] - 2026-11-12

### Fixed

- File search (`Space Space`) and text search (`Space /`) now find what the
  explorer shows, including files ignored by `.gitignore` such as `.env` or
  `dist/`. `.git` and `node_modules` are skipped, like VS Code's search; change
  that with `options.search.exclude`. Search follows `explorer.show_hidden`,
  `explorer.show_gitignored` and `explorer.hide`.

## [0.10.0] - 2026-11-12

### Changed

- The explorer shows everything by default: dotfiles, files ignored by
  `.gitignore` (dimmed), `.git` and `node_modules`. Nothing is hidden
  unless you list it in `explorer = { hide = { ... } }`.

### Added

- Option `explorer = { show_gitignored = true }`.

## [0.9.0] - 2026-11-12

### Added

- Material Icon Theme look in the explorer: folders get an icon and color by
  name (`src`, `docs`, `tests`, `scripts`, `.github`, `.git`, `node_modules`,
  `config`, `assets`, `dist`, `lib`, `utils`, `types`, `api`, `styles`, …), and
  `README`, `CHANGELOG`, `LICENSE`, `CONTRIBUTING` get their Material icons.
  Colors can be changed through `WraithIcon*` highlight groups.

### Fixed

- Nerd Font icons that were blank: folder icons in the explorer, the default
  file icon, diagnostic and Git status signs, terminal header and dashboard
  icons, and the rounded statusline separators. Glyphs are now stored as
  `\u{...}` escapes so they cannot be stripped again, and a test fails if any
  icon is empty.

## [0.8.0] - 2026-11-12

### Added

- Easier file creation. The explorer header has **File** and **Folder**
  buttons (plus Refresh and Collapse All), right-clicking an explorer item
  opens a file menu (New File, New Folder, Open to the Side, Rename, Delete,
  Copy Path), and `Space n` / `Space Shift+N` (`:NewFile` / `:NewFolder`)
  create a file or folder next to the current file from anywhere.
- The prompt starts with the target folder, so you only type the name.
  Nested names such as `api/v2/routes.lua` create the missing folders.
- Option `explorer = { header = true }`.

### Changed

- `a` / `A` in the explorer use the same prompt, and the new file opens right
  away. Existing files are opened, never overwritten.

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

[Unreleased]: https://github.com/cachewraith/wraithvim/compare/v0.13.1...HEAD
[0.13.1]: https://github.com/cachewraith/wraithvim/compare/v0.13.0...v0.13.1
[0.13.0]: https://github.com/cachewraith/wraithvim/compare/v0.12.0...v0.13.0
[0.12.0]: https://github.com/cachewraith/wraithvim/compare/v0.11.0...v0.12.0
[0.11.0]: https://github.com/cachewraith/wraithvim/compare/v0.10.1...v0.11.0
[0.10.1]: https://github.com/cachewraith/wraithvim/compare/v0.10.0...v0.10.1
[0.10.0]: https://github.com/cachewraith/wraithvim/compare/v0.9.0...v0.10.0
[0.9.0]: https://github.com/cachewraith/wraithvim/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/cachewraith/wraithvim/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/cachewraith/wraithvim/compare/v0.6.1...v0.7.0
[0.6.1]: https://github.com/cachewraith/wraithvim/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/cachewraith/wraithvim/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/cachewraith/wraithvim/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/cachewraith/wraithvim/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/cachewraith/wraithvim/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/cachewraith/wraithvim/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/cachewraith/wraithvim/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/cachewraith/wraithvim/releases/tag/v0.1.0
