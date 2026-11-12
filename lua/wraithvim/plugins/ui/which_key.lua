-- Key hints: after pressing <leader> (or another prefix), a popup lists the
-- next keys and what they do. Groups and options come from ui/which_key.lua.
return function(cfg)
  return {
    "folke/which-key.nvim",
    enabled = cfg.ui.key_hints,
    event = "VeryLazy",
    opts = function()
      return require("wraithvim.ui.which_key").opts()
    end,
  }
end
