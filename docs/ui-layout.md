# UI layout

```text
┌──────────────────────────────────────────────────────────────────┐
│ WraithVim         │ ▎ init.lua × │ config.lua × │      wraithvim  main │ ← tabline
├───────────────────┼──────────────────────────────────────────────┤
│  lua              │                                              │
│    wraithvim      │                 editor                       │
│  tests            │                                              │
│  README.md        │                                              │
│  (explorer)       ├──────────────────────────────────────────────┤
│                   │ terminal panel (<leader>t)                   │
├───────────────────┴──────────────────────────────────────────────┤
│ NORMAL │  main  +2 ~1 │ lua/x.lua ●  E1 W2      lua_ls │ lua │ utf-8 │ LF │ 42% │ 10:4 │
└──────────────────────────────────────────────────────────────────┘
```

| Component | Implementation | Configure with |
|---|---|---|
| Tabline | bufferline.nvim; the left offset over the explorer shows "WraithVim", and the right side shows project + branch | `ui.tabline` |
| Explorer | neo-tree.nvim | `ui.explorer` |
| Statusline | lualine.nvim with event-driven refresh | `ui.statusline` |
| Terminal | Neovim's built-in terminal | `ui.terminal` |
| Dashboard | WraithVim (`ui/dashboard.lua`), no plugin | `ui.dashboard` |
| Notifications | WraithVim (`ui/notifications.lua`), no plugin | `ui.notifications` |
| Search | Telescope (flex layout: side-by-side preview on wide screens, stacked on narrow ones) | `plugins.lua` |
| Diagnostics | Native signs, virtual text and floats | `options.diagnostics` |
| Theme | TokyoNight | `ui.theme`, `ui.colors` |

## Presets

`preset` is applied first; anything else in `ui.lua` overrides it.

| Setting | default | compact | minimal |
|---|---|---|---|
| Explorer | 30 columns, opens on start with files | 24 columns, opens on start | on demand only (`<leader>e`) |
| Tabline | always shown, header, close icons | shown with 2+ buffers, no header, no close icons | off |
| Statusline | branch, diff, file, diagnostics, LSP, filetype, encoding, position | no encoding | branch, file, diagnostics, filetype, position |
| Separators | thin bars + powerline-style sections | none | none |
| Terminal | bottom, 12 lines | bottom, 10 lines | bottom, 12 lines |
| Dashboard | on | on | off |
| Notifications | floating, top right | floating, top right | Neovim message area |

## Small terminals

- The explorer auto-opens only when the terminal is at least 100 columns wide.
  Open it anytime with `<leader>e`.
- The global statusline (`laststatus=3`) uses a single line for all windows.
- Telescope switches to a stacked layout below 120 columns.
- Dashboard content is centred and recomputed on resize.
- Splits are rebalanced when the terminal is resized.

## Without a Nerd Font

Set `icons = { nerd_font = false }`. WraithVim then uses ASCII markers (`E`,
`W`, `+`, `~`, `-`, `+`/`-` folders), disables devicons in the explorer,
tabline, statusline and Telescope, and drops powerline separators. The
installer chooses this automatically when `fc-list` finds no Nerd Font.

## Creating files and folders

Any of these opens a prompt that already contains the target folder, for
example `src/components/`. Type the name and press <kbd>Enter</kbd>:

- click **File** or **Folder** in the explorer header (creates in the selected folder)
- right click a folder or file in the explorer, then **New File** / **New Folder**
- press `a` (file) or `A` (folder) on an explorer item
- press `Space n` / `Space Shift+N` anywhere (creates next to the current file)

A name with slashes such as `api/v2/routes.lua` creates the missing folders,
and a name ending in `/` creates a folder. The new file opens straight away.
If the file already exists it is opened, never overwritten. Press
<kbd>Esc</kbd> to cancel.

## Resizing panels

- Drag any window separator with the mouse, including the explorer edge.
- `<leader>w+`, `<leader>w-`, `<leader>w>`, `<leader>w<` resize the current
  window; `<leader>w=` equalises.
- The terminal panel keeps its height when other windows change
  (`winfixheight`).

## Terminal panel

```text
  TERMINAL  bash   ~/projects/api                    New   Hide   Kill
 ❯ npm run dev
 ...
 TERMINAL │  bash │  ~/projects/api              Esc Esc: scroll & copy
```

- `<leader>t` / `:Terminal` toggles one panel terminal; `` Ctrl+Shift+` ``
  always opens (or focuses) it at the bottom. Hiding it keeps the shell
  running; showing it again reuses the same shell.
- **Typing works like VS Code:** entering the terminal window, or clicking
  inside it, starts typing. `Esc Esc` stops typing so you can scroll or
  select and copy output; the statusline shows which mode you are in.
- **Header buttons:** **New** opens another terminal beside the panel
  (`<leader>Tn`, `:TerminalNew`), **Hide** hides the panel, **Kill** stops that
  terminal's shell. The header shows the shell and its folder; shells that
  report directory changes (fish does by default) update it after `cd`.
- The shell is your `$SHELL`, started directly in the current folder. Use
  another one with `terminal = { shell = "fish" }` in `ui.lua`, or turn the
  header off with `terminal = { winbar = false }`.
- `:Terminal float` opens the panel as a floating window; `<leader>Th` /
  `<leader>Tv` open independent terminals in splits.
- Terminal buffers never appear as tabs and are removed when their shell
  exits. `:TerminalClose` stops the panel shell.
