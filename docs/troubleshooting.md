# Troubleshooting

Always start with:

```vim
:Health     " everything WraithVim checks, with advice
:Log        " warnings and errors (secrets in messages are redacted)
:Notifications
:Lazy             " plugin state; :Lazy log for recent changes
```

## Startup

**"WraithVim requires Neovim >= 0.12"**: your `nvim` is too old. See
[installation](installation.md#1-install-the-requirements) for the release
tarball. Check which binary runs with `which -a nvim`.

**"Failed to clone lazy.nvim … Running without plugins"**: no network (or a
proxy or firewall blocks GitHub). WraithVim still works without plugins.
Restart once you are online. Behind a proxy, set `https_proxy` for Git.

**Some plugins are missing** (`:Health` lists them): run `:Lazy restore`.

**"WraithVim not found at …"**: the bootstrap points to a directory that no
longer exists. Re-run `install.sh`, or set `WRAITHVIM_DIR`.

**A configuration problem notification at startup**: the message names the
file and key, e.g. `ui.explorer.width: expected number, got string (using
default)`. Fix the file in `~/.config/wraithvim/`. WraithVim keeps running with
defaults for the broken parts.

**Slow startup**: run `:Profile` (lazy.nvim's profiler) or
`nvim --startuptime /tmp/wraithvim-startup.log +qa` and read
[performance](performance.md#reading---startuptime). Plugins you add in
`plugins.lua` with `lazy = false` load during startup; prefer `event`, `cmd`
or `keys`.

**A plugin from `plugins.lua` never loads**: WraithVim sets lazy.nvim's
`defaults.lazy = true`, so a spec needs a trigger (`event`, `cmd`, `keys`,
`ft`), another plugin depending on it, a `require()` of its module, or
`lazy = false`.

## Display

**Boxes or question marks instead of icons**: your terminal font is not a
Nerd Font. Install one (e.g. JetBrainsMono Nerd Font) and select it in the
terminal, or set `icons = { nerd_font = false }` in `ui.lua`.

**Colours look wrong**: the terminal must support 24-bit colour
(`termguicolors` is on). With tmux, add
`set -as terminal-features ",*:RGB"` to `~/.tmux.conf`.

**Mouse does nothing**: check `:set mouse?` (should be `a`). In tmux enable
`set -g mouse on`. Some terminals need "mouse reporting" enabled in their
settings.

**The explorer did not open at startup**: it only auto-opens when files or a
directory are given and the terminal is at least 100 columns wide. Use
`<leader>e`.

## Search

**Live grep says ripgrep is missing**: install `ripgrep`. Inside a Git
repository WraithVim falls back to `git grep`, with a one-time hint.

**Find files is slow**: install `fd` (`fd-find` on Debian/Ubuntu/Kali/Fedora).
Without fd or rg, `find` is used.

**Sorting feels worse than usual**: telescope-fzf-native needs `make` and a C
compiler at install time. Install them, then run `:Lazy build
telescope-fzf-native.nvim`.

## LSP, completion, formatting

**No LSP features**: `:Health` lists each server as installed or not.
The server must be on `PATH` *for Neovim*: GUI launchers and some shells do
not load your interactive shell's `PATH`. Check with `:echo exepath("gopls")`.
Then `:checkhealth vim.lsp` (or `<leader>lI`) shows attached clients and
their logs. `:LspLog` opens the LSP log.

**Wrong project root**: servers use nvim-lspconfig's root markers (e.g.
`go.mod`, `package.json`, `.git`). Open Neovim inside the project, or add a
marker file.

**Completion is slow on huge lists**: blink.cmp could not download its native
fuzzy matcher (offline install or an unsupported architecture) and uses the
Lua implementation. Run `:BlinkCmp status` to check.

**"No formatter available"**: install the formatter listed for the language
in `:Health`, or check `:ConformInfo`. Format-on-save is **off** by
default; see [configuration](configuration.md#optionslua).

**`:InstallParsers` fails**: install the tree-sitter CLI (≥ 0.26.1, not from
npm), a C compiler, `curl` and `tar`. The error message lists what is missing.
`:TSLog` shows nvim-treesitter's log.

## Git

**No signs in the gutter**: the file must be inside a Git repository and
tracked or untracked (not ignored). Files longer than 40 000 lines are skipped.

**`:Update` refuses to update**: the distribution checkout has local
changes. Move personal changes to `~/.config/wraithvim/`, then
`git -C ~/.local/share/wraithvim stash` (or `checkout .`).

**Conflict view shows "could not read BASE"**: the index no longer has that
stage, for example after `git add`. Run `:Conflicts` to see what is still
unmerged.

## Resetting

```bash
rm -rf ~/.local/share/nvim/wraithvim ~/.local/state/nvim/wraithvim   # plugins, log
nvim                                                                  # reinstalls pinned plugins
```

Your settings in `~/.config/wraithvim` are unaffected.

## Reporting bugs

Include the output of `:Health`, `nvim --version`, your distribution,
the relevant part of `:Log`, and the smallest `~/.config/wraithvim`
that reproduces the problem.
