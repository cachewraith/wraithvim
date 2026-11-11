# Keymaps

Leader is <kbd>Space</kbd>, local leader is `\`. Press `<leader>?` (or run
`:WraithKeys`) for an in-editor cheatsheet, or `<leader>fk` to fuzzy-search
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
| `<leader>tc` | n | Close terminal | |

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
| Terminal | `<Esc><Esc>` | Leave terminal mode |
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
  -- remove defaults: an lhs (all modes) or { mode(s), lhs }
  disable = { "s", "S", { "n", "<leader>wv" } },

  -- add mappings: { mode(s), lhs, rhs, desc = ..., and any vim.keymap.set option }
  { "n", "<leader>qq", "<cmd>qa<cr>", desc = "Quit all" },
  { { "n", "x" }, "<leader>y", '"+y', desc = "Yank to clipboard" },
}
```

Direct `vim.keymap.set()` calls in `keymaps.lua` also work: the file runs after
WraithVim's defaults are defined.
