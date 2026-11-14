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

## Icons

The explorer uses the look of VS Code's Material Icon Theme. Folders get an
icon and color by name: `src` green, `docs` blue, `tests` teal, `scripts`
amber, `.github`, `.git`, `node_modules`, `config`, `assets`, `dist`, `lib`,
`utils`, `types`, `components`, `api`, `db`, `styles` and more each have their
own. Other folders are blue-grey. Files use nvim-web-devicons' colored icons,
and `README`, `CHANGELOG`, `LICENSE`, `CONTRIBUTING`, `CODE_OF_CONDUCT` and
`SECURITY` get their Material icons.

Change a color with `ui.colors` in `ui.lua`, for example
`colors = { WraithIconGreen = { fg = "#a6e3a1" } }`. The groups are
`WraithIconFolder` (other folders) and `WraithIconGreen`, `Lime`, `Teal`,
`Cyan`, `Blue`, `Indigo`, `Purple`, `Pink`, `Red`, `Orange`, `Amber`, `Brown`,
`Slate`.

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

## Side panel

```text
 Explorer │ main.go                       │  Git graph  Enter open  d diff …
          │                               │ * a1b2c3d (HEAD -> main) Fix login
          │                               │ * 9f8e7d6 Add tests
```

- A column beside the editor, on the right by default, like VS Code's
  secondary side bar. It shows one view at a time: **Git graph**
  (`Space s g`), **changed files** (`Space s c`) or the **terminal**
  (`Space s t`). `:SidePanel graph left` does the same as a command.
- The graph and the changed files update live: a commit, checkout or `rm`
  in a shell, a file saved or deleted in the explorer shows up right away.
- `Space s s` (VS Code preset: `Ctrl+Alt+B`) hides it and brings back the
  last view; `Space s m` moves it to the other side. Set the default side
  and width with `side_panel = { position = "left", width = 50 }` in `ui.lua`.
- In the changed files, `Enter` opens a file, `d` shows its diff, `ga` / `gu`
  stage / unstage it and `gc` commits. The graph keys are listed in its
  header.
- The terminal moves there with the same shell, and back to the bottom with
  `` Ctrl+Shift+` ``.
- **Move the cursor between panels** from any mode, even while typing in a
  terminal: `Alt+1` code, `Alt+2` side panel, `Alt+3` terminal, `Alt+0`
  explorer.

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
