-- WraithVim entry point.
--
-- This file is sourced by the small bootstrap written to ~/.config/nvim/init.lua
-- by install.sh. It can also be used directly, e.g. `nvim -u path/to/wraithvim/init.lua`.

-- Byte-compile and cache Lua modules (lazy.nvim would enable this later anyway;
-- doing it first speeds up every require before plugin setup).
-- Guarded so that Neovims too old to run WraithVim still reach its version message.
if vim.loader then
  vim.loader.enable()
  -- The cache folder is only created here. When a cache cleaner deletes it
  -- while WraithVim runs, every module loaded afterwards fails with ENOENT
  -- (completion breaks first). Recreate it before a new module is loaded.
  local uv = vim.uv or vim.loop
  local function ensure_cache_dir(dir)
    if not uv.fs_stat(dir) then
      ensure_cache_dir(vim.fs.dirname(dir))
      uv.fs_mkdir(dir, 493) -- 0755
    end
  end
  table.insert(package.loaders, 2, function()
    ensure_cache_dir(vim.loader.path)
  end)
  local loadfile = _G.loadfile
  _G.loadfile = function(...)
    ensure_cache_dir(vim.loader.path)
    return loadfile(...)
  end
end

local source = debug.getinfo(1, "S").source:sub(2)
local root = vim.fs.dirname((vim.uv or vim.loop).fs_realpath(source) or source)

vim.g.wraithvim_root = root
vim.opt.rtp:prepend(root)

require("wraithvim").setup({ root = root })
