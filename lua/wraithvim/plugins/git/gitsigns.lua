-- Git signs, hunk staging and blame.
return function(_)
  return {
    "lewis6991/gitsigns.nvim",
    event = require("wraithvim.plugins").lazy_file,
    opts = function()
      return require("wraithvim.features.git").gitsigns_opts()
    end,
  }
end
