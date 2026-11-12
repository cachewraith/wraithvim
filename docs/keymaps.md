# Keymaps

Leader is <kbd>Space</kbd>, local leader is `\`. Press `<leader>?` (or run
`:Keys`) for an in-editor cheatsheet, or `<leader>fk` to fuzzy-search
every mapping.

All mappings live in one registry, `lua/wraithvim/config/keymaps.lua`; a test
checks that every entry is documented here. Mappings marked with a plugin are
skipped automatically when that plugin is disabled.

Neovim's own defaults remain available, for example `K` (hover), `grn`
(rename), `gra` (code action), `grr` (references), `gri` (implementation),
`gO` (document symbols), `[d`/`]d` (diagnostics), `[b`/`]b` (buffers) and
`<C-w>` window commands.

### Explorer

| Keys | Mode | Action | Plugin |
|---|---|---|---|
| `<leader>ee` | n | Toggle explorer | neo-tree.nvim |
| `<leader>ef` | n | Reveal current file | neo-tree.nvim |
| `<leader>eg` | n | Explorer: Git changes | neo-tree.nvim |
| `<leader>eb` | n | Explorer: open buffers | neo-tree.nvim |
| `<leader>e>` | n | Widen explorer | neo-tree.nvim |
| `<leader>e<` | n | Narrow explorer | neo-tree.nvim |

### Find / search

| Keys | Mode | Action | Plugin |
|---|---|---|---|
| `<leader>ff` | n | Find files | telescope.nvim |
| `<leader>fg` | n | Live grep | telescope.nvim |
| `<leader>fw` | n, x | Search word / selection | telescope.nvim |
| `<leader>fb` | n | Find buffers | telescope.nvim |
| `<leader>fr` | n | Recent files | telescope.nvim |
| `<leader>fv` | n | Git files | telescope.nvim |
| `<leader>fx` | n | Search diagnostics | telescope.nvim |
| `<leader>fh` | n | Help tags | telescope.nvim |
| `<leader>fk` | n | Keymaps | telescope.nvim |
| `<leader>fc` | n | Commands | telescope.nvim |
| `<leader>f/` | n | Search in buffer | telescope.nvim |
| `<leader>fR` | n | Resume last search | telescope.nvim |
| `<leader>fd` | n, x | Format document | conform.nvim |

### Git

| Keys | Mode | Action | Plugin |
|---|---|---|---|
| `<leader>gs` | n | Git status | vim-fugitive |
| `<leader>gd` | n | Git diff (all changes) | diffview.nvim |
| `<leader>gD` | n | Close diff view | diffview.nvim |
| `<leader>gb` | n | Git branches | telescope.nvim |
| `<leader>gc` | n | Git commit | vim-fugitive |
| `<leader>gC` | n | Git commit --amend | vim-fugitive |
| `<leader>gp` | n | Git push | vim-fugitive |
| `<leader>gP` | n | Git pull | vim-fugitive |
| `<leader>gl` | n | Commit history | diffview.nvim |
| `<leader>gf` | n | File history | diffview.nvim |
| `<leader>ga` | n | Stage file | |
| `<leader>gu` | n | Unstage file | |
| `<leader>gh` | n | Stage / unstage hunk | gitsigns.nvim |
| `<leader>gh` | x | Stage / unstage selected lines | gitsigns.nvim |
| `<leader>gr` | n | Reset hunk | gitsigns.nvim |
| `<leader>gr` | x | Reset selected lines | gitsigns.nvim |
| `<leader>gS` | n | Stage buffer | gitsigns.nvim |
| `<leader>gR` | n | Reset buffer | gitsigns.nvim |
| `<leader>gv` | n | Preview hunk | gitsigns.nvim |
| `<leader>gB` | n | Blame line | gitsigns.nvim |
| `<leader>gx` | n | List merge conflicts | |
| `<leader>gm` | n | Resolve merge conflict (3-way) | |

### Git hunks

| Keys | Mode | Action | Plugin |
|---|---|---|---|
| `]h` | n | Next hunk | gitsigns.nvim |
| `[h` | n | Previous hunk | gitsigns.nvim |

### Buffers

| Keys | Mode | Action | Plugin |
|---|---|---|---|
| `<leader>bb` | n | Pick buffer | bufferline.nvim |
| `<leader>bd` | n | Delete buffer | |
| `<leader>bD` | n | Delete buffer (discard changes) | |
| `<leader>bo` | n | Delete other buffers | |
| `<leader>bc` | n | Delete hidden buffers | |
| `<leader>bn` | n | Next buffer | |
| `<leader>bp` | n | Previous buffer | |

### Terminal

| Keys | Mode | Action | Plugin |
|---|---|---|---|
| `<leader>tt` | n | Toggle terminal | |
| `<leader>th` | n | Terminal in horizontal split | |
| `<leader>tv` | n | Terminal in vertical split | |
| `<leader>tf` | n | Floating terminal | |
| `<leader>tn` | n | New terminal beside the panel | |
| `<leader>tc` | n | Close terminal | |
| `` <C-S-`> `` | n, i, t | Open terminal at the bottom (`` Ctrl+Shift+` ``) | |
| `<C-~>` | n, i, t | Same key as reported by some terminals | |

### Diagnostics

| Keys | Mode | Action | Plugin |
|---|---|---|---|
| `<leader>dd` | n | Line diagnostics | |
| `<leader>dn` | n | Next diagnostic | |
| `<leader>dp` | n | Previous diagnostic | |
| `<leader>dq` | n | Diagnostics to quickfix | |
| `<leader>dl` | n | Buffer diagnostics to location list | |
| `<leader>dt` | n | Toggle inline diagnostics | |
| `<leader>dT` | n | Toggle buffer diagnostics | |
| `<leader>dx` | n | Search all diagnostics | telescope.nvim |

### Code

| Keys | Mode | Action | Plugin |
|---|---|---|---|
| `<leader>cf` | n, x | Format | conform.nvim |
| `<leader>cF` | n | Toggle format on save | conform.nvim |

### Windows

| Keys | Mode | Action | Plugin |
|---|---|---|---|
| `<leader>wv` | n | Split vertically | |
| `<leader>ws` | n | Split horizontally | |
| `<leader>wc` | n | Close window | |
| `<leader>wo` | n | Close other windows | |
| `<leader>w=` | n | Equalize windows | |
| `<leader>wh` | n | Focus left window | |
| `<leader>wj` | n | Focus window below | |
| `<leader>wk` | n | Focus window above | |
| `<leader>wl` | n | Focus right window | |
| `<leader>w+` | n | Taller window | |
| `<leader>w-` | n | Shorter window | |
| `<leader>w>` | n | Wider window | |
| `<leader>w<` | n | Narrower window | |

### Navigation and general

| Keys | Mode | Action | Plugin |
|---|---|---|---|
| `s` | n, x, o | Flash jump | flash.nvim |
| `S` | n, x, o | Flash Treesitter select | flash.nvim |
| `r` | o | Flash remote operation | flash.nvim |
| `<C-s>` | n, i, x | Save file | |
| `<leader>?` | n | Keymap cheatsheet | |

### LSP (buffer-local, only when a language server is attached)

| Keys | Mode | Action | Plugin |
|---|---|---|---|
| `gd` | n | Go to definition | |
| `gD` | n | Go to declaration | |
| `<leader>ld` | n | Definition | |
| `<leader>lD` | n | Declaration | |
| `<leader>lr` | n | References | |
| `<leader>li` | n | Implementations | |
| `<leader>lt` | n | Type definition | |
| `<leader>lh` | n | Hover | |
| `<leader>lk` | n | Signature help | |
| `<leader>ls` | n | Document symbols | telescope.nvim |
| `<leader>lS` | n | Workspace symbols | telescope.nvim |
| `<leader>lR` | n | Restart language server | |
| `<leader>lI` | n | LSP info | |
| `<leader>lH` | n | Toggle inlay hints | |
| `<leader>rn` | n | Rename symbol | |
| `<leader>ca` | n, x | Code action | |

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
