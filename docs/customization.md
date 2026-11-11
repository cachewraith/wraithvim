# Customization recipes

All examples go in `~/.config/wraithvim/`. Open it with `:WraithConfig`.
Restart Neovim after changes. The full key reference is in
[configuration.md](configuration.md).

## Use VS Code shortcuts

```lua
-- keymaps.lua
return { preset = "vscode" }
```

`Ctrl+P` opens files, `Ctrl+Shift+F` searches the project, `Ctrl+B` toggles the
explorer, `` Ctrl+` `` the terminal, `Ctrl+/` comments, `Ctrl+C/X/V/Z/Y`
copy, cut, paste, undo and redo, Shift+Arrows select, and typing replaces the
selection. See [keymaps](keymaps.md#vs-code-keymap-preset).

## Use relative numbers and wrap long lines

```lua
-- options.lua
return { opt = { relativenumber = true, wrap = true } }
```

## Format on save

```lua
-- options.lua
return { format = { on_save = true, timeout_ms = 2000 } }
```

Toggle at runtime with `<leader>cF` / `:WraithFormatToggle`, or only for the
current buffer with `:WraithFormatToggle!`.

## A quieter, smaller UI

```lua
-- ui.lua
return {
  preset = "minimal",
  statusline = { lsp = true },     -- presets are a starting point; override anything
}
```

## Another colorscheme

```lua
-- plugins.lua
return {
  { "catppuccin/nvim", name = "catppuccin", lazy = true },
}
```

```lua
-- ui.lua
return { theme = { colorscheme = "catppuccin-mocha" } }
```

lazy.nvim loads the colorscheme plugin when `:colorscheme` asks for it, so it
stays lazy. If it fails to load, WraithVim falls back to `habamax` and tells
you why.

## Tweak highlight groups

```lua
-- ui.lua
return {
  colors = {
    CursorLine = { bg = "#1f2335" },
    WinSeparator = { fg = "#3b4261" },
    WraithDashboardHeader = { fg = "#7aa2f7", bold = true },
  },
}
```

## Replace or disable a plugin

```lua
-- plugins.lua
return {
  disable = { "flash.nvim", "bufferline.nvim" },
  { "kylechui/nvim-surround", event = "VeryLazy", opts = {} },
}
```

Disabling `bufferline.nvim` is equivalent to `tabline = { enabled = false }`.
Disabling `lualine.nvim` leaves Neovim's built-in statusline.

## Change plugin options

Specs with the same name are merged by lazy.nvim:

```lua
-- plugins.lua
return {
  { "saghen/blink.cmp", opts = { keymap = { preset = "super-tab" } } },
  { "lewis6991/gitsigns.nvim", opts = { current_line_blame = true } },
}
```

`current_line_blame` runs `git blame` while the cursor rests. It is off by
default to keep Git subprocesses to a minimum.

## Keymaps

```lua
-- keymaps.lua
return {
  disable = { "<C-s>" },
  { "n", "<leader>qq", "<cmd>qa<cr>", desc = "Quit all" },
  { "n", "<S-l>", "<cmd>bnext<cr>", desc = "Next buffer" },
  { "n", "<S-h>", "<cmd>bprevious<cr>", desc = "Previous buffer" },
}
```

## Languages

```lua
-- languages.lua
return {
  java = false,
  sql = false,
  python = {
    servers = {
      basedpyright = false,
      pyright = { cmd = "pyright-langserver", mason = "pyright" },
    },
  },
}
```

## Use Mason for missing tools

```lua
-- options.lua
return { mason = { enabled = true } }
```

Then run `:WraithInstallTools`. It lists the missing servers and formatters
for your enabled languages and installs them only after you confirm. Tools
already on your `PATH` are always preferred.

## Run WraithVim beside another configuration

```bash
./install.sh --appname wvim
alias wvim='NVIM_APPNAME=wvim nvim'
```
