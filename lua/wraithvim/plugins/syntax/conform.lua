-- Formatting. Loaded on first save (format-on-save is opt-in) or on demand.
return function(_)
  return {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    opts = function()
      return require("wraithvim.integrations.formatter").opts()
    end,
  }
end
