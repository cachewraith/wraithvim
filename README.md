# WraithVim

**Website:** <https://cachewraith.github.io/wraithvim-site/> — install guide,
first steps with an animated demo, and a searchable list of every key.

A lightweight, VS Code-inspired Neovim distribution for developers who live in
the terminal. WraithVim gives you an explorer, buffer tabs, fuzzy search,
LSP, completion, formatting, a complete Git workflow (including three-way
merge-conflict resolution) and a terminal panel, while keeping Neovim fast,
quiet when idle, and recognisably Neovim.

```text
┌──────────────────────────────────────────────────────────┐
│ WraithVim  │ init.lua  config.lua           project  main │  ← buffer tabs + header
├────────────┬─────────────────────────────────────────────┤
│ Explorer   │                                             │
│  lua/      │               Code editor                   │
│  tests/    │                                             │
├────────────┴─────────────────────────────────────────────┤
│ NORMAL  main +2 ~1  lua/x.lua ●   lua_ls  lua  utf-8  LF │  ← statusline
└──────────────────────────────────────────────────────────┘
```

> Screenshots: start `nvim` on a project with `nvim .` or `nvim some/file.lua`
> in a terminal with a Nerd Font and capture the window; the layout above is
> what the default preset draws.

## Highlights

- **Fast and idle-quiet.** About 20 ms headless startup, 2 of 21 plugins loaded
  at startup, and **0 ms of CPU while idle** with a file open (see
  [performance](docs/performance.md)).
- **No polling.** The statusline is driven by events, not lualine's timers.
  No background indexing and no update checker.
- **Live files.** When an AI CLI, a formatter or `git checkout` changes an
  open file, it reloads on its own (OS file events, never your unsaved edits).
- **29 languages, set up for you.** Open a Go, Rust, TypeScript, Python, …
  file and WraithVim offers to install its language server, linter and
  formatter: completion, errors as you type and formatting, no restart
  ([languages](docs/languages.md)).
- **Native first.** Built-in LSP client (`vim.lsp.config`/`vim.lsp.enable`),
  `vim.snippet`, `vim.treesitter`, built-in terminal.
- **Mouse everywhere it works for real.** Click tabs, click files and folders,
  drag splits, scroll, select text, click statusline items and the dashboard.
- **Git-first.** Signs, hunk staging, fugitive status/commit/push/pull,
  diffview diffs and history, a readable commit graph, and a WraithVim three-way conflict resolver built
  on Git's index stages.
- **Your settings survive updates.** Personal configuration lives in
  `~/.config/wraithvim/`; the distribution lives in `~/.local/share/wraithvim/`.

## Requirements

| | |
|---|---|
| Required | Neovim **0.12+** (LuaJIT build), Git, Linux (x86_64; ARM64 where plugin binaries exist) |
| Recommended | ripgrep, fd, a C compiler + make (fzf-native), a Nerd Font, a clipboard tool (wl-clipboard / xclip) |
| Optional | tree-sitter CLI ≥ 0.26.1 (syntax parsers); Node.js, Go, Python, … for the language tools that need them (installed on demand) |

Supported and tested distributions: Arch Linux, EndeavourOS, Ubuntu, Debian,
Fedora, Kali Linux. Nothing assumes a particular shell, terminal emulator,
window manager or desktop. Neovim never needs sudo.

## Installation

```bash
git clone https://github.com/cachewraith/wraithvim ~/.local/share/wraithvim
cd ~/.local/share/wraithvim
./install.sh --check      # dependency report only
./install.sh --dry-run    # show every action, change nothing
./install.sh              # install
nvim                      # first start installs the pinned plugins
```

Cloned straight into its install location, WraithVim stays in place. The
installer moves an existing `~/.config/nvim` to a timestamped backup
(`~/.config/nvim.bak.<date>`), writes a small bootstrap
`~/.config/nvim/init.lua`, and creates commented starter files in
`~/.config/wraithvim/`. Running it again changes nothing. Run `./install.sh`
from a clone anywhere else and it clones itself to `~/.local/share/wraithvim`.

To install a specific release, check out its tag first, e.g.
`git -C ~/.local/share/wraithvim checkout v0.13.0`. `:Update` follows the
`main` branch.

Prefer a download? Every release has
[`wraithvim.tar.gz`](https://github.com/cachewraith/wraithvim/releases/latest/download/wraithvim.tar.gz)
attached; extract it and run `./install.sh` (it still sets up an updatable Git
install).

Try WraithVim **next to your current config**:

```bash
./install.sh --appname wvim
NVIM_APPNAME=wvim nvim
```

Full details: [docs/installation.md](docs/installation.md).

## Update and uninstall

```vim
:Update      " git pull --ff-only, then sync plugins to lazy-lock.json
```

```bash
~/.local/share/wraithvim/uninstall.sh --dry-run
~/.local/share/wraithvim/uninstall.sh
```

The uninstaller asks before removing anything. It restores your previous
configuration from a backup if one exists, and never deletes
`~/.config/wraithvim` or backups unless you pass `--purge-user-config` and type
a confirmation.

## Essential keymaps

Coming from VS Code? Put `return { preset = "vscode" }` in
`~/.config/wraithvim/keymaps.lua` for `Ctrl+P`, `Ctrl+Shift+F`, `Ctrl+B`,
`` Ctrl+` ``, `Ctrl+/`, `Ctrl+C/X/V/Z`, `F2`, `F12`, `Alt+↑/↓`, Shift+Arrow
selection and more ([full list](docs/keymaps.md#vs-code-keymap-preset)).

Leader is <kbd>Space</kbd>. **Press Space and wait**: a popup shows every key
you can press next. **`Space p`** lets you search every action by name (like
VS Code's Command Palette), and `Space ?` opens a full cheatsheet. Keys are
pressed one after another; `Shift+P` means hold Shift and press p. The complete
list is in [docs/keymaps.md](docs/keymaps.md).

| Keys | Action | Keys | Action |
|---|---|---|---|
| `Space Space` | Find file | `Space g g` | Git graph |
| `Space /` | Search text in project | `Space g s` | Git status |
| `Space e` | Explorer | `Space g d` | Diff all changes |
| `Space t` | Terminal | `Space g c` | Commit |
| `Space x` | Close tab | `Space g b` | Switch branch |
| `Space n` | **New file** | `Space Shift+N` | New folder |
| `Space ,` | Switch tab | `Space u u` | Update WraithVim |
| `Space q` | Quit | `Space u h` | Health check |
| `Space p` | **Search actions by name** | `Space ?` | All keys |
| `gd` / `K` | Definition / hover | `Space r n` | Rename symbol |
| `Space c a` | Code action | `Space c f` | Format |
| `` Ctrl+Shift+` `` | Terminal at the bottom | `Ctrl+S` | Save |
| `Space s g` | Git graph in the side panel | `Space s c` | Changed files in the side panel |
| `Alt+1` / `Alt+2` | Go to code / side panel | `Alt+3` / `Alt+0` | Go to terminal / explorer |

## Commands

| Command | Purpose |
|---|---|
| `:Health` | Health checks (`:checkhealth wraithvim`) |
| `:Update` | Update the distribution and plugins |
| `:Log` | Open the WraithVim log |
| `:Profile` | Plugin load profile (`:Lazy profile`) |
| `:Benchmark` | Run `scripts/benchmark.sh` in a terminal split |
| `:Config` | Open `~/.config/wraithvim/` |
| `:Actions` | Search and run any action by name (also `Space p`, `F1`) |
| `:Explorer` / `:FindFile` / `:Search` | Toggle explorer / find a file / search text in the project |
| `:CloseTab` | Close the current tab |
| `:NewFile` / `:NewFolder` | New file / folder next to the current file (asks for the name) |
| `:Keys` | Keymap cheatsheet |
| `:Notifications` | Notification history |
| `:BufferCleanup` | Delete hidden, unmodified buffers |
| `:Terminal [pos]` | Toggle the terminal panel (`bottom`, `top`, `left`, `right`, `float`) |
| `:TerminalSplit [vertical]` | Independent terminal in a new split |
| `:TerminalClose` | Stop the panel shell and remove its buffer |
| `:TerminalNew` | Another terminal beside the panel (like VS Code's **+**) |
| `:SidePanel [view] [side]` | Show the Git graph, changed files or terminal (`graph`, `changes`, `terminal`) beside the editor, `left` or `right`; no argument shows / hides it |
| `:GitGraph` / `:GitGraphAll` | Commit graph of the current branch / all branches (<kbd>Enter</kbd> opens a commit, <kbd>?</kbd> lists keys, <kbd>q</kbd> closes) |
| `:GitStatus` | fugitive status |
| `:GitDiff` / `:GitDiffClose` | diffview of all changes / close it |
| `:GitCommit` / `:GitAmend` | Commit / amend |
| `:GitPush` / `:GitPull` | Push / pull |
| `:GitBranches` | Branch picker (checkout on <kbd>Enter</kbd>) |
| `:GitLog` / `:GitFileHistory` | Repository / file history |
| `:GitStage` / `:GitUnstage` | Stage / unstage the current file |
| `:Conflict [file]` | Three-way conflict view |
| `:Conflicts` | Conflicted files in the quickfix list |
| `:ConflictChoose[!] {side} [all]` | Take `ours`/`theirs`/`both`/`base`/`none` (`!` = whole file) |
| `:ConflictResolve [file]` | Check, `git add`, report remaining conflicts |
| `:ConflictClose` | Close the conflict view |
| `:DiffDisk` | Compare your unsaved buffer with the version on disk |
| `:Format` | Format buffer or range |
| `:FormatToggle[!]` | Toggle format-on-save (`!` = this buffer only) |
| `:InstallParsers [parsers]` | Install Treesitter parsers for enabled languages |
| `:InstallTools` | Install every missing language server, linter and formatter with Mason (asks first) |

## Languages

PHP, JavaScript/TypeScript, Java, Python, Go, C/C++, Lua, SQL, Bash and YAML
profiles ship with WraithVim. A language server or formatter starts only when
its language is enabled, its executable is installed, and a matching file is
opened. Nothing is installed for you. See [docs/languages.md](docs/languages.md)
for per-distribution install commands.

| Language | LSP | Formatter |
|---|---|---|
| PHP | intelephense | pint |
| JavaScript / TypeScript | vtsls | prettier |
| Java | jdtls | google-java-format |
| Python | basedpyright | ruff |
| Go | gopls | gofumpt |
| C / C++ | clangd | clang-format |
| Lua | lua-language-server | stylua |
| SQL | sqls | sql-formatter |
| Bash | bash-language-server | shfmt |
| YAML | yaml-language-server | prettier |

## Customization

```text
~/.config/wraithvim/
├── options.lua    editor settings, format-on-save, Mason, vim options
├── ui.lua         preset (default | compact | minimal), panels, theme, icons
├── languages.lua  enable/disable languages, override servers and formatters
├── plugins.lua    add lazy.nvim specs, disable or reconfigure plugins
└── keymaps.lua    add mappings, remove default ones
```

```lua
-- ~/.config/wraithvim/ui.lua
return {
  preset = "compact",
  explorer = { width = 34 },
  terminal = { position = "right", width = 90 },
  icons = { nerd_font = false },
}
```

Missing files are fine; mistakes are reported, not fatal. See
[docs/configuration.md](docs/configuration.md),
[docs/customization.md](docs/customization.md) and
[docs/ui-layout.md](docs/ui-layout.md).

## Architecture

```text
init.lua                     entry point (also sourced by the generated bootstrap)
lua/wraithvim/
├── core/          config loading, lazy.nvim bootstrap, logger, update, performance
├── config/        defaults, options, keymaps, autocmds, user commands
├── ui/            presets, statusline/tabline/explorer settings, dashboard, notifications
├── features/      explorer, search, buffers, terminal, git, conflicts, diagnostics
├── languages/     language registry and profiles
├── integrations/  LSP, formatter, Treesitter and Mason glue
├── plugins/       one lazy.nvim spec per plugin, grouped by responsibility
└── health.lua     :checkhealth wraithvim
```

Details: [docs/architecture.md](docs/architecture.md).

## Performance philosophy

Every plugin is lazy-loaded. There are no timers, pollers or file watchers
while you are idle, apart from gitsigns' event-driven (inotify) watch on
`.git`. Expensive work happens only when you ask for it. Measure it yourself:

```bash
scripts/benchmark.sh           # installed WraithVim
nvim --startuptime /tmp/wraithvim-startup.log +qa
```

See [docs/performance.md](docs/performance.md) for methodology and results.

## Troubleshooting

Start with `:Health`, then `:Log`. Common problems and fixes are in
[docs/troubleshooting.md](docs/troubleshooting.md).

## Contributing

```bash
make deps tools   # sandboxed plugins + pinned StyLua/Luacheck/ShellCheck
make check        # lint, format check, tests, health check
```

See [CONTRIBUTING.md](CONTRIBUTING.md). WraithVim is released under the
[MIT License](LICENSE).
