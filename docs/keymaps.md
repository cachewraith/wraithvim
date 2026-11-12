# Keymaps

Leader is <kbd>Space</kbd>, local leader is `\`. **Press <kbd>Space</kbd> and
wait a moment**: a popup lists every key you can press next and what it does
(turn it off with `key_hints = false` in `ui.lua`). `<leader>?` (or `:Keys`)
opens a full cheatsheet, and `<leader>fk` fuzzy-searches every mapping.

All mappings live in one registry, `lua/wraithvim/config/keymaps.lua`; a test
checks that every entry is documented here. Mappings marked with a plugin are
skipped automatically when that plugin is disabled.

Neovim's own defaults remain available, for example `K` (hover), `grn`
(rename), `gra` (code action), `grr` (references), `gri` (implementation),
`gO` (document symbols), `[d`/`]d` (diagnostics), `[b`/`]b` (buffers) and
`<C-w>` window commands.

### Quick keys

One key after <kbd>Space</kbd> for the things you do most.

| Keys | Action | Mode |
|---|---|---|
| `<leader><space>` | Find file | n |
| `<leader>/` | Search text in project | n |
| `<leader>,` | Switch tab | n |
| `<leader>e` | Explorer | n |
| `<leader>E` | Show file in explorer | n |
| `<leader>t` | Terminal | n |
| `<leader>x` | Close tab | n |
| `<leader>q` | Quit (asks to save) | n |
| `<leader>?` | All keymaps | n |

### Buffers (tabs) (`<leader>b…`)

| Keys | Action | Mode |
|---|---|---|
| `<leader>bb` | Pick tab | n |
| `<leader>bd` | Close tab | n |
| `<leader>bD` | Close tab (discard changes) | n |
| `<leader>bo` | Close other tabs | n |
| `<leader>bc` | Close hidden tabs | n |
| `<leader>bn` | Next tab | n |
| `<leader>bp` | Previous tab | n |

### Code (`<leader>c…`)

| Keys | Action | Mode |
|---|---|---|
| `<leader>cf` | Format | n, x |
| `<leader>cF` | Toggle format on save | n |

### Diagnostics (`<leader>d…`)

| Keys | Action | Mode |
|---|---|---|
| `<leader>dd` | Show line problems | n |
| `<leader>dn` | Next problem | n |
| `<leader>dp` | Previous problem | n |
| `<leader>dq` | All problems (quickfix) | n |
| `<leader>dl` | File problems (list) | n |
| `<leader>dt` | Toggle inline problems | n |
| `<leader>dT` | Toggle problems for file | n |
| `<leader>dx` | Search problems | n |

### Find (`<leader>f…`)

| Keys | Action | Mode |
|---|---|---|
| `<leader>ff` | Files | n |
| `<leader>fg` | Text (live grep) | n |
| `<leader>fw` | Word / selection | n, x |
| `<leader>fb` | Open tabs | n |
| `<leader>fr` | Recent files | n |
| `<leader>fv` | Git files | n |
| `<leader>fx` | Problems | n |
| `<leader>fh` | Help | n |
| `<leader>fk` | Keymaps | n |
| `<leader>fc` | Commands | n |
| `<leader>f/` | In this file | n |
| `<leader>fR` | Resume last search | n |

### Git (`<leader>g…`)

| Keys | Action | Mode |
|---|---|---|
| `<leader>gg` | Graph (all branches) | n |
| `<leader>gs` | Status | n |
| `<leader>gd` | Diff all changes | n |
| `<leader>gD` | Close diff | n |
| `<leader>gb` | Switch branch | n |
| `<leader>gc` | Commit | n |
| `<leader>gC` | Amend last commit | n |
| `<leader>gp` | Push | n |
| `<leader>gP` | Pull | n |
| `<leader>gl` | History (log) | n |
| `<leader>gf` | File history | n |
| `<leader>ge` | Changed files in explorer | n |
| `<leader>ga` | Stage file | n |
| `<leader>gu` | Unstage file | n |
| `<leader>gh` | Stage / unstage hunk | n |
| `<leader>gh` | Stage / unstage selected lines | x |
| `<leader>gr` | Undo hunk changes | n |
| `<leader>gr` | Undo changes in selected lines | x |
| `<leader>gS` | Stage whole file (hunks) | n |
| `<leader>gR` | Undo all file changes | n |
| `<leader>gv` | Preview hunk | n |
| `<leader>gB` | Blame line | n |
| `<leader>gx` | List merge conflicts | n |
| `<leader>gm` | Resolve merge conflict | n |
| `]h` | Next change (hunk) | n |
| `[h` | Previous change (hunk) | n |

### Terminals (`<leader>T…`)

| Keys | Action | Mode |
|---|---|---|
| `<leader>Tn` | New terminal beside | n |
| `<leader>Th` | Terminal below (split) | n |
| `<leader>Tv` | Terminal right (split) | n |
| `<leader>Tf` | Floating terminal | n |
| `<leader>Tc` | Kill terminal panel | n |

### Update & tools (`<leader>u…`)

| Keys | Action | Mode |
|---|---|---|
| `<leader>uu` | Update WraithVim | n |
| `<leader>uh` | Health check | n |
| `<leader>up` | Plugins | n |
| `<leader>uc` | Open settings folder | n |
| `<leader>ul` | Log | n |
| `<leader>un` | Notification history | n |
| `<leader>ut` | Install syntax parsers | n |
| `<leader>um` | Install language tools (Mason) | n |

### Windows (`<leader>w…`)

| Keys | Action | Mode |
|---|---|---|
| `<leader>wv` | Split right | n |
| `<leader>ws` | Split below | n |
| `<leader>wc` | Close window | n |
| `<leader>wo` | Close other windows | n |
| `<leader>w=` | Equal sizes | n |
| `<leader>wh` | Go left | n |
| `<leader>wj` | Go down | n |
| `<leader>wk` | Go up | n |
| `<leader>wl` | Go right | n |
| `<leader>w+` | Taller | n |
| `<leader>w-` | Shorter | n |
| `<leader>w>` | Wider | n |
| `<leader>w<` | Narrower | n |

### Other keys

| Keys | Action | Mode |
|---|---|---|
| `` <C-S-`> `` | Open terminal at the bottom | n, i, t |
| `<C-~>` | Open terminal at the bottom (Ctrl+Shift+`) | n, i, t |
| `s` | Flash jump | n, x, o |
| `S` | Flash Treesitter select | n, x, o |
| `r` | Flash remote operation | o |
| `<C-s>` | Save file | n, i, x |

### LSP (only when a language server is attached)

| Keys | Action | Mode |
|---|---|---|
| `gd` | Go to definition | n |
| `gD` | Go to declaration | n |
| `<leader>ld` | Definition | n |
| `<leader>lD` | Declaration | n |
| `<leader>lr` | References | n |
| `<leader>li` | Implementations | n |
| `<leader>lt` | Type definition | n |
| `<leader>lh` | Hover | n |
| `<leader>lk` | Signature help | n |
| `<leader>ls` | Document symbols | n |
| `<leader>lS` | Workspace symbols | n |
| `<leader>lR` | Restart language server | n |
| `<leader>lI` | LSP info | n |
| `<leader>lH` | Toggle inlay hints | n |
| `<leader>rn` | Rename symbol | n |
| `<leader>ca` | Code action | n, x |

### Inside special buffers

| Where | Keys | Action |
|---|---|---|
| Terminal | `<Esc><Esc>` | Stop typing, to scroll or select/copy output |
| Terminal | click inside, or `i` | Type again (entering a terminal window starts typing automatically) |
| Terminal header | **New** / **Hide** / **Kill** (click) | Another terminal beside it / hide the panel (shell keeps running) / stop the shell |
| Explorer (neo-tree) | `<CR>`, `l`, single click | Open file / toggle directory |
| Explorer | `h` | Collapse directory |
| Explorer | `a` / `A` | Add file (end with `/` for a directory) / add directory |
| Explorer | `r`, `d`, `c`, `m` | Rename, delete, copy, move |
| Explorer | `y`, `x`, `p` | Copy, cut, paste via the explorer clipboard |
| Explorer | `H`, `R`, `?` | Toggle hidden files, refresh, help |
| Dashboard | letter shown in `[ ]`, `<CR>`, click | Run the item |
| Conflict RESULT pane | `<leader>co` `<leader>ct` `<leader>cb` `<leader>c0` `<leader>cn` | Take ours / theirs / both / base / none for the conflict under the cursor |
| Conflict RESULT pane | `]x` / `[x` | Next / previous conflict |
| Conflict RESULT pane | `<leader>cr` / `<leader>cq` | Mark resolved and stage / close the view |
| Conflict OURS/BASE/THEIRS pane | `dp` | Put the hunk under the cursor into RESULT |
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
| Window separators, explorer edge | Drag | Resize splits and panels |
| Any window | Wheel | Scroll |
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
