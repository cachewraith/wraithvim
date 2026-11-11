-- Statusline. Loaded after the first screen is drawn.
return function(cfg)
  return {
    "nvim-lualine/lualine.nvim",
    enabled = cfg.ui.statusline.enabled,
    event = "VeryLazy",
    init = function()
      -- Avoid a flash of the default statusline before lualine loads.
      if vim.fn.argc(-1) > 0 then
        vim.o.statusline = " "
      else
        vim.o.laststatus = 0
      end
    end,
    opts = function()
      return require("wraithvim.ui.statusline").opts()
    end,
    config = function(_, opts)
      require("lualine").setup(opts)
      -- lualine's own refresh queue is not polled (see ui/statusline.lua).
      require("wraithvim.ui.statusline").request_refresh()
    end,
  }
end
