# Installation

WraithVim installs entirely inside your home directory and never needs sudo.

| Path | Contents | Touched by updates? |
|---|---|---|
| `~/.local/share/wraithvim/` | The distribution (a Git checkout) | Yes |
| `~/.config/nvim/init.lua` | Generated bootstrap (a few lines) | Rewritten by `install.sh` only |
| `~/.config/wraithvim/` | **Your** settings | Never |
| `~/.local/share/nvim/wraithvim/` | Plugins (lazy.nvim) | Yes |
| `~/.local/state/nvim/wraithvim/` | Log file | — |

XDG variables (`XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME`) are
respected. Plugins are stored in their own directory, so an existing
`~/.local/share/nvim/lazy` from another configuration is not touched.

## 1. Install the requirements

Neovim **0.12 or newer** and Git are required. Everything else is optional; see
the table in the [README](../README.md#requirements).

### Arch Linux / EndeavourOS

```bash
sudo pacman -S --needed neovim git ripgrep fd make gcc curl wl-clipboard   # xclip on X11
sudo pacman -S --needed tree-sitter-cli                                     # optional, parsers
```

### Ubuntu / Debian / Kali

Distribution packages of Neovim are usually older than 0.12. Use the official
release build instead (no root needed):

```bash
sudo apt install git ripgrep fd-find make gcc curl xclip      # or wl-clipboard
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
# ARM64: nvim-linux-arm64.tar.gz
mkdir -p ~/.local/opt && tar -C ~/.local/opt -xzf nvim-linux-x86_64.tar.gz
ln -sf ~/.local/opt/nvim-linux-x86_64/bin/nvim ~/.local/bin/nvim   # ensure ~/.local/bin is on PATH
```

`fd-find` installs the binary as `fdfind`; WraithVim detects that name.

### Fedora

```bash
sudo dnf install neovim git ripgrep fd-find make gcc curl wl-clipboard
nvim --version   # must report 0.12 or newer; otherwise use the release tarball above
```

### tree-sitter CLI (optional)

Needed only to install additional Treesitter parsers (`:InstallParsers`).
nvim-treesitter requires version 0.26.1 or newer and recommends **not** using
the npm package. On Arch use `pacman -S tree-sitter-cli`; elsewhere download the
binary from <https://github.com/tree-sitter/tree-sitter/releases> or run
`cargo install --locked tree-sitter-cli`.

## 2a. Install with the installer

```bash
git clone https://github.com/cachewraith/wraithvim ~/.local/share/wraithvim
cd ~/.local/share/wraithvim
./install.sh --check     # dependency report; exit 1 if something required is missing
./install.sh --dry-run   # print every action; nothing changes
./install.sh             # install
```

If you run `install.sh` from a clone somewhere else (e.g. `~/src/wraithvim`),
it clones that checkout to `~/.local/share/wraithvim` and points its `origin`
at the same upstream URL, so `:Update` keeps working.

What `install.sh` does, in order:

1. Detects the distribution (`/etc/os-release`) and architecture, checks
   Neovim ≥ 0.12 and Git, and reports optional tools with an install command
   for your distribution.
2. Clones the checkout into `~/.local/share/wraithvim`. The clone goes into a
   temporary directory first, so a network or permission failure leaves
   nothing behind. If the directory exists and is already WraithVim, it is left
   as is. Anything else in the way is moved to `<path>.bak.<timestamp>`.
3. Writes the bootstrap `~/.config/nvim/init.lua`. An existing configuration
   directory is **moved** to `~/.config/nvim.bak.<timestamp>`, never deleted.
4. Creates commented starter files in `~/.config/wraithvim/`. Existing files
   are never overwritten. `ui.lua` gets `nerd_font = false` if `fc-list` finds
   no Nerd Font.

Options:

| Option | Meaning |
|---|---|
| `--dry-run` | Print actions only |
| `--check` | Dependency report only |
| `--appname NAME` | Install the bootstrap to `~/.config/NAME` and leave `~/.config/nvim` alone; start with `NVIM_APPNAME=NAME nvim`. `wraithvim` is rejected because `~/.config/wraithvim` holds your settings. |
| `--dir PATH` | Install somewhere other than `~/.local/share/wraithvim` |
| `--repo URL` | Clone from a different URL |
| `--link` | Symlink this checkout instead of cloning (for development) |
| `--sync` | Install the pinned plugins immediately (needs network) |

Running the installer again is safe: it reports "already installed" and
"bootstrap already up to date" and changes nothing.

## 2b. Install from the release download

Every release has a `wraithvim.tar.gz` attached (this is what the website's
download counter counts):

```bash
curl -LO https://github.com/cachewraith/wraithvim/releases/latest/download/wraithvim.tar.gz
tar -xzf wraithvim.tar.gz && cd wraithvim
./install.sh
```

Run from an archive, `install.sh` clones the GitHub repository into
`~/.local/share/wraithvim`, so the result is a normal Git install that
`:Update` can update. Without network access it copies the archive instead
(`:Update` is then unavailable; re-run the installer from a newer archive).

## 2c. Install by cloning, without the installer

```bash
git clone https://github.com/cachewraith/wraithvim ~/.local/share/wraithvim
```

Then write the bootstrap yourself (or run `install.sh`, which notices it is
already in place and only writes the bootstrap and the starter files):

```lua
-- ~/.config/nvim/init.lua
dofile(vim.fn.expand("~/.local/share/wraithvim/init.lua"))
```

## 3. First start

```bash
nvim
```

lazy.nvim clones itself, then installs the plugin versions pinned in
`lazy-lock.json`. Run `:Health` afterwards. If the network is unavailable,
WraithVim still starts with its options, keymaps, commands and terminal (and
the built-in `habamax` colorscheme), logs the Git error to `:Log`, and
asks you to restart once you are online. If lazy.nvim itself installed but some
plugins failed, run `:Lazy restore`.

blink.cmp downloads a prebuilt fuzzy-matcher library for x86_64 and aarch64
Linux on first use. If that is impossible, it silently uses its Lua matcher.

## Updating

```vim
:Update
```

Updates follow the `main` branch. To stay on a release instead, check out its
tag (`git -C ~/.local/share/wraithvim checkout v0.9.0`). `:Update` then
refuses to pull (a detached tag has no branch to fast-forward); switch back
with `git -C ~/.local/share/wraithvim checkout main`.

This runs `git pull --ff-only` in the distribution directory, then
`:Lazy restore` to check out exactly the plugin versions pinned by the new
`lazy-lock.json`. Your `~/.config/wraithvim/` is outside the checkout, so it is
never affected. If `:Lazy update` changed the lockfile locally,
`:Update` offers to reset it. Any other local modification stops the
update with an explanation.

From a shell: `git -C ~/.local/share/wraithvim pull --ff-only && nvim --headless "+Lazy! restore" +qa`.

## Uninstalling

```bash
~/.local/share/wraithvim/uninstall.sh --dry-run   # see what would happen
~/.local/share/wraithvim/uninstall.sh             # asks before each step
```

The uninstaller:

- removes `~/.config/nvim/init.lua` only if it is the WraithVim bootstrap, then
  offers to restore the newest `~/.config/nvim.bak.*`;
- deletes `~/.local/share/wraithvim` (or only the symlink for `--link`
  installs) and the plugin and log directories, each after a confirmation;
- keeps `~/.config/wraithvim` unless you pass `--purge-user-config` **and**
  type `delete` at the prompt (`--yes` does not skip that prompt);
- never deletes backups; it lists them at the end.

Without a terminal (e.g. in a script) every confirmation is answered "no"
unless `--yes` is given.
