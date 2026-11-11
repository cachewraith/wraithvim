-- File explorer. Loaded on :Neotree, on explorer keymaps, or at startup when
-- Neovim is given a directory argument (netrw replacement).
return function(cfg)
  return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    enabled = cfg.ui.explorer.enabled,
    cmd = "Neotree",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    init = function()
      if vim.fn.argc(-1) == 1 then
        local stat = vim.uv.fs_stat(vim.fn.argv(0) --[[@as string]])
        if stat and stat.type == "directory" then
          require("lazy").load({ plugins = { "neo-tree.nvim" } })
        end
      end
    end,
    opts = function()
      return require("wraithvim.ui.explorer").opts()
    end,
  }
end
