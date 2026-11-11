-- WraithVim entry point.
--
-- This file is sourced by the small bootstrap written to ~/.config/nvim/init.lua
-- by install.sh. It can also be used directly, e.g. `nvim -u path/to/wraithvim/init.lua`.

-- Byte-compile and cache Lua modules (lazy.nvim would enable this later anyway;
-- doing it first speeds up every require before plugin setup).
vim.loader.enable()

local source = debug.getinfo(1, "S").source:sub(2)
local root = vim.fs.dirname(vim.uv.fs_realpath(source) or source)

vim.g.wraithvim_root = root
vim.opt.rtp:prepend(root)

require("wraithvim").setup({ root = root })
