-- Optional tool installer. Mason's bin directory is appended to PATH so that
-- system-installed executables always take priority.
return function(cfg)
  return {
    "mason-org/mason.nvim",
    enabled = cfg.options.mason.enabled,
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog" },
    init = function()
      require("wraithvim.integrations.mason").add_to_path()
    end,
    opts = {
      PATH = "skip", -- handled by integrations.mason.add_to_path()
      ui = { border = cfg.ui.border },
    },
  }
end
