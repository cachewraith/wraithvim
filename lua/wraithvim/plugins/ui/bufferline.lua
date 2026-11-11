-- Buffer tabs.
return function(cfg)
  return {
    "akinsho/bufferline.nvim",
    enabled = cfg.ui.tabline.enabled,
    version = "*",
    event = "VeryLazy",
    opts = function()
      return require("wraithvim.ui.tabline").opts()
    end,
  }
end
