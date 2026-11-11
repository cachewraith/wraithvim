-- Fuzzy finder. fzf-native is only installed when a C toolchain is available.
return function(cfg)
  local utils = require("wraithvim.core.utils")
  return {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        enabled = function()
          return utils.executable("make")
            and (utils.executable("cc") or utils.executable("gcc") or utils.executable("clang"))
        end,
      },
    },
    opts = function()
      return require("wraithvim.features.search").telescope_opts(cfg)
    end,
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      pcall(telescope.load_extension, "fzf")
    end,
  }
end
