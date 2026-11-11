-- Minimal init for test processes: WraithVim's Lua modules and plenary on the
-- runtimepath, without running WraithVim's setup. Integration tests start
-- separate Neovim processes with the real init.lua.

local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local plugins = vim.fs.joinpath(vim.fn.stdpath("data"), "wraithvim", "plugins")

vim.opt.rtp:prepend(root)
vim.opt.rtp:append(vim.fs.joinpath(plugins, "plenary.nvim"))
package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path

vim.g.wraithvim_root = root
vim.o.swapfile = false
vim.o.shadafile = "NONE"

vim.cmd("runtime plugin/plenary.vim")
