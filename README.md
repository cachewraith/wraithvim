# WraithVim

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

- **Fast and idle-quiet.** About 20 ms headless startup, 2 of 19 plugins loaded
  at startup, and **0 ms of CPU while idle** with a file open (see
  [performance](docs/performance.md)).
- **No polling.** The statusline is driven by events, not lualine's timers.
  There are no file watchers in the explorer, no background indexing and no
  update checker.
- **Native first.** Built-in LSP client (`vim.lsp.config`/`vim.lsp.enable`),
  `vim.snippet`, `vim.treesitter`, built-in terminal.
- **Mouse everywhere it works for real.** Click tabs, click files and folders,
  drag splits, scroll, select text, click statusline items and the dashboard.
- **Git-first.** Signs, hunk staging, fugitive status/commit/push/pull,
  diffview diffs and history, and a WraithVim three-way conflict resolver built
  on Git's index stages.
- **Your settings survive updates.** Personal configuration lives in
  `~/.config/wraithvim/`; the distribution lives in `~/.local/share/wraithvim/`.

## Requirements

| | |
|---|---|
| Required | Neovim **0.12+** (LuaJIT build), Git, Linux (x86_64; ARM64 where plugin binaries exist) |
| Recommended | ripgrep, fd, a C compiler + make (fzf-native), a Nerd Font, a clipboard tool (wl-clipboard / xclip) |
| Optional | tree-sitter CLI ≥ 0.26.1 (parser installation), language servers and formatters for your languages, Mason |

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
`git -C ~/.local/share/wraithvim checkout v0.2.0`. `:WraithUpdate` follows the
`main` branch.

Try WraithVim **next to your current config**:

```bash
./install.sh --appname wvim
NVIM_APPNAME=wvim nvim
```

Full details: [docs/installation.md](docs/installation.md).

## Update and uninstall

```vim
:WraithUpdate      " git pull --ff-only, then sync plugins to lazy-lock.json
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

Leader is <kbd>Space</kbd>. Press `<leader>?` for an in-editor cheatsheet. The
full list is in [docs/keymaps.md](docs/keymaps.md).

| Keys | Action | Keys | Action |
|---|---|---|---|
| `<leader>ee` | Toggle explorer | `<leader>gs` | Git status |
| `<leader>ff` | Find files | `<leader>gd` | Diff all changes |
| `<leader>fg` | Live grep | `<leader>gb` | Switch branch |
| `<leader>fb` | Find buffers | `<leader>gc` | Commit |
| `<leader>fr` | Recent files | `<leader>gm` | Resolve merge conflict |
| `<leader>tt` | Toggle terminal | `]h` / `[h` | Next / previous hunk |
| `<leader>bd` | Delete buffer | `<leader>gh` | Stage hunk |
| `gd` / `K` | Definition / hover | `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action | `<leader>fd` | Format document |
| `s` | Flash jump | `<C-s>` | Save |

## Commands

| Command | Purpose |
|---|---|
| `:WraithHealth` | Health checks (`:checkhealth wraithvim`) |
| `:WraithUpdate` | Update the distribution and plugins |
| `:WraithLog` | Open the WraithVim log |
| `:WraithProfile` | Plugin load profile (`:Lazy profile`) |
| `:WraithBenchmark` | Run `scripts/benchmark.sh` in a terminal split |
| `:WraithConfig` | Open `~/.config/wraithvim/` |
| `:WraithKeys` | Keymap cheatsheet |
| `:WraithNotifications` | Notification history |
| `:WraithBufferCleanup` | Delete hidden, unmodified buffers |
| `:WraithTerminal [pos]` | Toggle the terminal panel (`bottom`, `top`, `left`, `right`, `float`) |
| `:WraithTerminalSplit [vertical]` | Independent terminal in a new split |
| `:WraithTerminalClose` | Stop the panel shell and remove its buffer |
| `:WraithGitStatus` | fugitive status |
| `:WraithGitDiff` / `:WraithGitDiffClose` | diffview of all changes / close it |
| `:WraithGitCommit` / `:WraithGitAmend` | Commit / amend |
| `:WraithGitPush` / `:WraithGitPull` | Push / pull |
| `:WraithGitBranches` | Branch picker (checkout on <kbd>Enter</kbd>) |
| `:WraithGitLog` / `:WraithGitFileHistory` | Repository / file history |
| `:WraithGitStage` / `:WraithGitUnstage` | Stage / unstage the current file |
| `:WraithConflict [file]` | Three-way conflict view |
| `:WraithConflicts` | Conflicted files in the quickfix list |
| `:WraithConflictChoose[!] {side} [all]` | Take `ours`/`theirs`/`both`/`base`/`none` (`!` = whole file) |
| `:WraithConflictResolve [file]` | Check, `git add`, report remaining conflicts |
| `:WraithConflictClose` | Close the conflict view |
| `:WraithFormat` | Format buffer or range |
| `:WraithFormatToggle[!]` | Toggle format-on-save (`!` = this buffer only) |
| `:WraithTSInstall [parsers]` | Install Treesitter parsers for enabled languages |
| `:WraithInstallTools` | Install missing tools with Mason (only when enabled; asks first) |

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
├── config/        defaults, options, keymaps, autocmds, :Wraith commands
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

Start with `:WraithHealth`, then `:WraithLog`. Common problems and fixes are in
[docs/troubleshooting.md](docs/troubleshooting.md).

## Contributing

```bash
make deps tools   # sandboxed plugins + pinned StyLua/Luacheck/ShellCheck
make check        # lint, format check, tests, health check
```

See [CONTRIBUTING.md](CONTRIBUTING.md). WraithVim is released under the
[MIT License](LICENSE).
