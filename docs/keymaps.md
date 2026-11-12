# Keymaps

**Don't want to remember keys?** Press `Space p` (or `F1`, `Ctrl+Shift+P`, or
type `:Actions`) and type what you want — "pull", "graph", "terminal" — then
Enter. Every action is listed with its key, so you pick them up as you go.
Most actions are also plain commands: `:Explorer`, `:FindFile`, `:Search`,
`:Terminal`, `:GitGraph`, `:GitPull`, `:Update`, … (see the README).

**Press <kbd>Space</kbd> and wait a moment**: a popup lists every key you can
press next (turn it off with `key_hints = false` in `ui.lua`). `Space ?` (or
`:Keys`) opens a full cheatsheet.

### How to read the keys

| Written | Press |
|---|---|
| `Space g p` | Space, then g, then p — one after another, not together |
| `Shift+P` (Vim: a capital `P`) | hold Shift and press p |
| `Ctrl+S` (Vim: `<C-s>`) | hold Ctrl and press s |
| `Alt+Down` (Vim: `<A-Down>`, `<M-…>`) | hold Alt and press Down |
| Vim notation `<leader>` | Space |

So `<leader>gP` in Vim notation means **Space, g, Shift+P** (Git pull).

All mappings live in one registry, `lua/wraithvim/config/keymaps.lua`; a test
checks that every entry is documented here. Mappings marked with a plugin are
skipped automatically when that plugin is disabled.

Neovim's own defaults remain available, for example `K` (hover), `grn`
(rename), `gra` (code action), `grr` (references), `gri` (implementation),
`gO` (document symbols), `[d`/`]d` (diagnostics), `[b`/`]b` (buffers) and
`<C-w>` window commands.

### Quick keys

One key after <kbd>Space</kbd> for the things you do most.

| Press | Action | Vim notation | Mode |
|---|---|---|---|
| Space Space | Find file | `<leader><space>` | n |
| Space / | Search text in project | `<leader>/` | n |
| Space , | Switch tab | `<leader>,` | n |
| Space e | Explorer | `<leader>e` | n |
| Space Shift+E | Show file in explorer | `<leader>E` | n |
| Space n | New file (here) | `<leader>n` | n |
| Space Shift+N | New folder (here) | `<leader>N` | n |
| Space t | Terminal | `<leader>t` | n |
| Space x | Close tab | `<leader>x` | n |
| Space q | Quit (asks to save) | `<leader>q` | n |
| Space p | Actions (search by name) | `<leader>p` | n |
| Space ? | All keymaps | `<leader>?` | n |

### Buffers (tabs) (`<leader>b…`)

| Press | Action | Vim notation | Mode |
|---|---|---|---|
| Space b b | Pick tab | `<leader>bb` | n |
| Space b d | Close tab | `<leader>bd` | n |
| Space b Shift+D | Close tab (discard changes) | `<leader>bD` | n |
| Space b o | Close other tabs | `<leader>bo` | n |
| Space b c | Close hidden tabs | `<leader>bc` | n |
| Space b n | Next tab | `<leader>bn` | n |
| Space b p | Previous tab | `<leader>bp` | n |

### Code (`<leader>c…`)

| Press | Action | Vim notation | Mode |
|---|---|---|---|
| Space c f | Format | `<leader>cf` | n, x |
| Space c Shift+F | Toggle format on save | `<leader>cF` | n |

### Diagnostics (`<leader>d…`)

| Press | Action | Vim notation | Mode |
|---|---|---|---|
| Space d d | Show line problems | `<leader>dd` | n |
| Space d n | Next problem | `<leader>dn` | n |
| Space d p | Previous problem | `<leader>dp` | n |
| Space d q | All problems (quickfix) | `<leader>dq` | n |
| Space d l | File problems (list) | `<leader>dl` | n |
| Space d t | Toggle inline problems | `<leader>dt` | n |
| Space d Shift+T | Toggle problems for file | `<leader>dT` | n |
| Space d x | Search problems | `<leader>dx` | n |

### Find (`<leader>f…`)

| Press | Action | Vim notation | Mode |
|---|---|---|---|
| Space f f | Files | `<leader>ff` | n |
| Space f g | Text (live grep) | `<leader>fg` | n |
| Space f w | Word / selection | `<leader>fw` | n, x |
| Space f b | Open tabs | `<leader>fb` | n |
| Space f r | Recent files | `<leader>fr` | n |
| Space f v | Git files | `<leader>fv` | n |
| Space f x | Problems | `<leader>fx` | n |
| Space f h | Help | `<leader>fh` | n |
| Space f k | Keymaps | `<leader>fk` | n |
| Space f c | Commands | `<leader>fc` | n |
| Space f / | In this file | `<leader>f/` | n |
| Space f Shift+R | Resume last search | `<leader>fR` | n |

### Git (`<leader>g…`)

| Press | Action | Vim notation | Mode |
|---|---|---|---|
| Space g g | Graph (this branch) | `<leader>gg` | n |
| Space g Shift+G | Graph (all branches) | `<leader>gG` | n |
| Space g s | Status | `<leader>gs` | n |
| Space g d | Diff all changes | `<leader>gd` | n |
| Space g Shift+D | Close diff | `<leader>gD` | n |
| Space g b | Switch branch | `<leader>gb` | n |
| Space g c | Commit | `<leader>gc` | n |
| Space g Shift+C | Amend last commit | `<leader>gC` | n |
| Space g p | Push | `<leader>gp` | n |
| Space g Shift+P | Pull | `<leader>gP` | n |
| Space g l | History (log) | `<leader>gl` | n |
| Space g f | File history | `<leader>gf` | n |
| Space g e | Changed files in explorer | `<leader>ge` | n |
| Space g a | Stage file | `<leader>ga` | n |
| Space g u | Unstage file | `<leader>gu` | n |
| Space g h | Stage / unstage hunk | `<leader>gh` | n |
| Space g h | Stage / unstage selected lines | `<leader>gh` | x |
| Space g r | Undo hunk changes | `<leader>gr` | n |
| Space g r | Undo changes in selected lines | `<leader>gr` | x |
| Space g Shift+S | Stage whole file (hunks) | `<leader>gS` | n |
| Space g Shift+R | Undo all file changes | `<leader>gR` | n |
| Space g v | Preview hunk | `<leader>gv` | n |
| Space g Shift+B | Blame line | `<leader>gB` | n |
| Space g x | List merge conflicts | `<leader>gx` | n |
| Space g m | Resolve merge conflict | `<leader>gm` | n |
| ] h | Next change (hunk) | `]h` | n |
| [ h | Previous change (hunk) | `[h` | n |

### Terminals (`<leader>T…`)

| Press | Action | Vim notation | Mode |
|---|---|---|---|
| Space Shift+T n | New terminal beside | `<leader>Tn` | n |
| Space Shift+T h | Terminal below (split) | `<leader>Th` | n |
| Space Shift+T v | Terminal right (split) | `<leader>Tv` | n |
| Space Shift+T f | Floating terminal | `<leader>Tf` | n |
| Space Shift+T c | Kill terminal panel | `<leader>Tc` | n |

### Update & tools (`<leader>u…`)

| Press | Action | Vim notation | Mode |
|---|---|---|---|
| Space u u | Update WraithVim | `<leader>uu` | n |
| Space u h | Health check | `<leader>uh` | n |
| Space u p | Plugins | `<leader>up` | n |
| Space u c | Open settings folder | `<leader>uc` | n |
| Space u l | Log | `<leader>ul` | n |
| Space u n | Notification history | `<leader>un` | n |
| Space u t | Install syntax parsers | `<leader>ut` | n |
| Space u m | Install language tools (Mason) | `<leader>um` | n |

### Windows (`<leader>w…`)

| Press | Action | Vim notation | Mode |
|---|---|---|---|
| Space w v | Split right | `<leader>wv` | n |
| Space w s | Split below | `<leader>ws` | n |
| Space w c | Close window | `<leader>wc` | n |
| Space w o | Close other windows | `<leader>wo` | n |
| Space w = | Equal sizes | `<leader>w=` | n |
| Space w h | Go left | `<leader>wh` | n |
| Space w j | Go down | `<leader>wj` | n |
| Space w k | Go up | `<leader>wk` | n |
| Space w l | Go right | `<leader>wl` | n |
| Space w + | Taller | `<leader>w+` | n |
| Space w - | Shorter | `<leader>w-` | n |
| Space w > | Wider | `<leader>w>` | n |
| Space w < | Narrower | `<leader>w<` | n |

### Scrolling

| Press | Action | Vim notation | Mode |
|---|---|---|---|
| Ctrl+D | Half page down (cursor centered) | `<C-d>` | n, x |
| Ctrl+U | Half page up (cursor centered) | `<C-u>` | n, x |
| Alt+J | Jump 10 lines down | `<A-j>` | n, x |
| Alt+K | Jump 10 lines up | `<A-k>` | n, x |

`PageDown`/`PageUp` scroll a full page and `gg`/`G` go to the first/last line,
as in plain Neovim. In the explorer, `}`/`{` jump to the next/previous folder
and `z` collapses everything. One mouse-wheel notch moves 6 lines; change it
with `scroll = { wheel = 10 }` in `options.lua`.

### Other keys

| Press | Action | Vim notation | Mode |
|---|---|---|---|
| Ctrl+Shift+` | Open terminal at the bottom | `` <C-S-`> `` | n, i, t |
| Ctrl+~ | Open terminal at the bottom (Ctrl+Shift+`) | `<C-~>` | n, i, t |
| s | Flash jump | `s` | n, x, o |
| Shift+S | Flash Treesitter select | `S` | n, x, o |
| r | Flash remote operation | `r` | o |
| Ctrl+S | Save file | `<C-s>` | n, i, x |

### LSP (only when a language server is attached)

| Press | Action | Vim notation | Mode |
|---|---|---|---|
| g d | Go to definition | `gd` | n |
| g Shift+D | Go to declaration | `gD` | n |
| Space l d | Definition | `<leader>ld` | n |
| Space l Shift+D | Declaration | `<leader>lD` | n |
| Space l r | References | `<leader>lr` | n |
| Space l i | Implementations | `<leader>li` | n |
| Space l t | Type definition | `<leader>lt` | n |
| Space l h | Hover | `<leader>lh` | n |
| Space l k | Signature help | `<leader>lk` | n |
| Space l s | Document symbols | `<leader>ls` | n |
| Space l Shift+S | Workspace symbols | `<leader>lS` | n |
| Space l Shift+R | Restart language server | `<leader>lR` | n |
| Space l Shift+I | LSP info | `<leader>lI` | n |
| Space l Shift+H | Toggle inlay hints | `<leader>lH` | n |
| Space r n | Rename symbol | `<leader>rn` | n |
| Space c a | Code action | `<leader>ca` | n, x |

### Inside special buffers

| Where | Keys | Action |
|---|---|---|
| Terminal | `<Esc><Esc>` | Stop typing, to scroll or select/copy output |
| Terminal | click inside, or `i` | Type again (entering a terminal window starts typing automatically) |
| Terminal header | **New** / **Hide** / **Kill** (click) | Another terminal beside it / hide the panel (shell keeps running) / stop the shell |
| Explorer (neo-tree) | `<CR>`, `l`, single click | Open file / toggle directory |
| Explorer | `h` | Collapse directory |
| Explorer | `}` / `{` | Next / previous folder |
| Explorer | `z` | Collapse all folders |
| Explorer | `a` / `A` | New file / new folder in the folder under the cursor (nested paths like `api/v2/x.lua` work) |
| Explorer | right click | Menu: New File, New Folder, Open to the Side, Rename, Delete, Copy Path, Refresh, Collapse All |
| Explorer | `r`, `d`, `c`, `m` | Rename, delete, copy, move |
| Explorer | `y`, `x`, `p` | Copy, cut, paste via the explorer clipboard |
| Explorer | `H`, `R`, `?` | Show / hide items listed in `explorer.hide` (cursor in the explorer), refresh, help |
| Dashboard | letter shown in `[ ]`, `<CR>`, click | Run the item |
| Conflict RESULT pane | `<leader>co` `<leader>ct` `<leader>cb` `<leader>c0` `<leader>cn` | Take ours / theirs / both / base / none for the conflict under the cursor |
| Conflict RESULT pane | `]x` / `[x` | Next / previous conflict |
| Conflict RESULT pane | `<leader>cr` / `<leader>cq` | Mark resolved and stage / close the view |
| Conflict OURS/BASE/THEIRS pane | `dp` | Put the hunk under the cursor into RESULT |
| Git graph | `<CR>` | Open the commit |
| Git graph | `d` / `c` / `y` | Diff of the commit / check it out (asks first) / copy its hash |
| Git graph | `a` / `u` / `?` / `q` | All branches on/off / refresh / every graph key / close |
| Completion menu | `<Tab>` / `<S-Tab>` | Next / previous item (or snippet jump) |
| Completion menu | `<CR>` | Accept the selected item |
| Completion menu | `<C-space>`, `<C-e>` | Open menu or docs / close menu |
| `help`, quickfix, `man`, health | `q` | Close the window |

`<C-s>` saves in normal, insert and visual mode. In insert mode this replaces
Neovim's default `<C-s>` signature-help mapping; blink.cmp shows signature
help automatically while you type arguments, and `<leader>lk` shows it on
demand.

`s`/`S` (flash.nvim) replace the rarely used `s` (substitute character, same
as `cl`) and `S` (same as `cc`). Disable them with
`disable = { "s", "S" }` in `keymaps.lua`. Native `f`/`t`/`F`/`T` and `/` are
unchanged.

## VS Code keymap preset

For VS Code muscle memory, turn on the VS Code preset:

```lua
-- ~/.config/wraithvim/keymaps.lua
return { preset = "vscode" }
```

It adds the shortcuts below on top of everything above and makes selection
work like VS Code:

- **Shift+Arrows / Shift+Home/End** and **mouse drags** select text.
- **Typing replaces the selection**, and Backspace deletes it (Neovim's
  Select mode). Plain arrows cancel the selection.
- Arrow keys move across line ends.
- Copy, cut and paste use the system clipboard.

Keys with *classic terminals* in their description are the bytes that
terminals without the kitty keyboard protocol send for the same key, so the
shortcut works in every terminal. `Ctrl+Shift+…`, `Ctrl+.` and `Ctrl+Tab` need
a terminal with that protocol (kitty, foot, WezTerm, Ghostty, Alacritty);
every action also has a key that works everywhere (for example `F1`,
`Ctrl+PgDn`, `<leader>ca`, `<leader>fg`).

`` Ctrl+Shift+` `` (open the terminal at the bottom) works in every preset;
see the Terminal table above.

| Keys | Action | Modes |
|---|---|---|
| `<C-p>` | Quick open file | normal |
| `<F1>` | Command palette | normal, insert |
| `<C-S-p>` | Command palette | normal, insert |
| `<C-S-f>` | Search in project | normal, insert |
| `<C-f>` | Find in file | normal |
| `<C-g>` | Go to line | normal |
| `<C-n>` | New file | normal |
| `<C-b>` | Toggle explorer | normal |
| `<C-S-e>` | Show file in explorer | normal |
| `` <C-`> `` | Toggle terminal | normal, terminal |
| `<C-Space>` | Toggle terminal (Ctrl+` in classic terminals) | normal, terminal |
| `<C-\>` | Split editor right | normal |
| `<C-S-g>` | Source control | normal |
| `<C-Tab>` | Next tab | normal |
| `<C-S-Tab>` | Previous tab | normal |
| `<C-PageDown>` | Next tab | normal |
| `<C-PageUp>` | Previous tab | normal |
| `<C-w>` | Close tab | normal |
| `<C-z>` | Undo | normal, insert |
| `<C-y>` | Redo | normal, insert |
| `<C-S-z>` | Redo | normal, insert |
| `<C-a>` | Select all | normal, insert |
| `<C-c>` | Copy line | normal |
| `<C-x>` | Cut line | normal |
| `<C-v>` | Paste | normal, insert, cmdline |
| `<C-/>` | Toggle line comment | normal, insert |
| `<C-_>` | Toggle line comment (Ctrl+/ in classic terminals) | normal, insert |
| `<A-Down>` | Move line down | normal, insert |
| `<A-Up>` | Move line up | normal, insert |
| `<S-A-Down>` | Duplicate line down | normal, insert |
| `<S-A-Up>` | Duplicate line up | normal, insert |
| `<C-S-k>` | Delete line | normal, insert |
| `<F2>` | Rename symbol | normal |
| `<F12>` | Go to definition | normal |
| `<S-F12>` | Find references | normal |
| `<F24>` | Find references (Shift+F12) | normal |
| `<C-.>` | Quick fix / code action | normal, insert, visual |
| `<F8>` | Next problem | normal |
| `<S-F8>` | Previous problem | normal |
| `<F20>` | Previous problem (Shift+F8) | normal |
| `<C-S-o>` | Go to symbol in file | normal |
| `<C-t>` | Go to symbol in workspace | normal |
| `<S-A-f>` | Format document | normal, insert |
| `<M-F>` | Format document (Shift+Alt+F in classic terminals) | normal, insert |
| `<C-c>` | Copy | visual, select |
| `<C-x>` | Cut | visual, select |
| `<C-v>` | Paste over selection | visual, select |
| `<Tab>` | Indent | visual, select |
| `<S-Tab>` | Outdent | visual, select |
| `<C-/>` | Toggle comment | visual, select |
| `<C-_>` | Toggle comment (Ctrl+/ in classic terminals) | visual, select |
| `<A-Down>` | Move lines down | visual, select |
| `<A-Up>` | Move lines up | visual, select |

What the preset changes from Neovim's defaults:

| Key | Neovim default | Still available as |
|---|---|---|
| `Ctrl+W` | window commands prefix | `<leader>w…` (`<leader>wh/wj/wk/wl/wv/ws/wc/wo`) |
| `Ctrl+V` (normal) | block selection | `Ctrl+Q` |
| `Ctrl+A` / `Ctrl+X` (normal) | increment / decrement a number | `Ctrl+A` on a visual selection still increments; for decrement, add `"<C-x>"` to `disable` |
| `Ctrl+F` / `Ctrl+B` | page down / up | `PageDown` / `PageUp` |
| `Ctrl+Z` | suspend Neovim | `:suspend` |
| `Ctrl+P` / `Ctrl+N` | line up / down | `k` / `j`, arrows |
| `Ctrl+G` / `Ctrl+T` | file info / tag jump back | `:file` / `:pop` |
| `Ctrl+Y` | scroll line up | mouse wheel |
| `Ctrl+Space` (in terminals) | sent to the shell | — (used for Ctrl+\` in classic terminals) |

Remove any of them with `disable`, e.g. `return { preset = "vscode", disable = { "<C-w>" } }`.

## Mouse

`mouse=a` is enabled. These interactions are implemented and covered by
tests that send real terminal mouse sequences (`tests/integration/tui_spec.lua`):

| Where | Action | Result |
|---|---|---|
| Buffer tabs | Left click | Switch to the buffer |
| Buffer tabs | Middle click, or click the close icon | Close the buffer (asks to save if modified) |
| Explorer | Single click on a file | Open it |
| Explorer | Single click on a directory | Expand / collapse it |
| Explorer header | Click **File** / **Folder** | New file / folder in the selected folder |
| Explorer | Right click | File menu (New File, New Folder, Rename, Delete, …) |
| Window separators, explorer edge | Drag | Resize splits and panels |
| Any window | Wheel | Scroll 6 lines per notch (`options.scroll`) |
| Text | Drag | Visual selection |
| Text | Right click | Neovim's context menu (definition, references, …) |
| Statusline branch | Click | Branch picker |
| Statusline diff counts | Click | Git status |
| Statusline diagnostics | Click | Diagnostics of the buffer in Telescope |
| Statusline LSP names | Click | `:checkhealth vim.lsp` |
| Statusline filetype | Click | Filetype picker |
| Dashboard | Click an item | Run it |
| Terminal panel | Click / wheel | Focus and scroll; clicking another window leaves the terminal |

Right-clicking a buffer tab intentionally does nothing (bufferline's default
would force-delete the buffer and discard changes). Single-click opening in the
explorer can be turned off with `explorer = { single_click = false }` in
`ui.lua`, which restores neo-tree's double-click behaviour. Releasing the mouse
after dragging a separator never opens an explorer item.

## Customising keymaps

```lua
-- ~/.config/wraithvim/keymaps.lua
return {
  preset = "vscode",   -- optional: VS Code shortcuts (see above); default is "default"

  -- remove defaults: an lhs (all modes) or { mode(s), lhs }
  disable = { "s", "S", { "n", "<leader>wv" } },

  -- add mappings: { mode(s), lhs, rhs, desc = ..., and any vim.keymap.set option }
  { "n", "<leader>qq", "<cmd>qa<cr>", desc = "Quit all" },
  { { "n", "x" }, "<leader>y", '"+y', desc = "Yank to clipboard" },
}
```

Direct `vim.keymap.set()` calls in `keymaps.lua` also work: the file runs after
WraithVim's defaults are defined.
