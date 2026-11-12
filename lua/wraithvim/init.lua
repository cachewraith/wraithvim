-- WraithVim setup sequence.
--
--   1. built-in editor options (before user files, so user vim.opt calls win)
--   2. version check
--   3. user configuration (~/.config/wraithvim/*.lua)
--   4. lazy.nvim with lazy-loaded plugin specs
--   5. diagnostics, Treesitter hook, autocommands, commands, keymaps
--   6. UI: theme, notifications, dashboard, explorer auto-open

local M = {}

--- Released version; kept in sync with CHANGELOG.md (tested).
M.version = "0.12.0"

local did_setup = false

---@class wraithvim.SetupOpts
---@field root? string distribution directory
---@field config? table overrides merged over user files (tests, embedding)
---@field plugins? boolean set false to skip lazy.nvim entirely

---@param opts? wraithvim.SetupOpts
function M.setup(opts)
  if did_setup then
    return
  end
  did_setup = true
  opts = opts or {}
  if opts.root then
    vim.g.wraithvim_root = opts.root
  end

  local options = require("wraithvim.config.options")
  options.apply_defaults()

  local ok, msg = require("wraithvim.core.bootstrap").check_version()
  if not ok then
    vim.api.nvim_echo({ { msg, "ErrorMsg" } }, true, {})
    return
  end

  local cfg = require("wraithvim.core.config").setup(opts.config)
  options.apply_user(cfg)

  local plugins_ok = false
  if opts.plugins ~= false then
    plugins_ok = require("wraithvim.core.plugin_manager").setup(cfg)
  end

  require("wraithvim.features.diagnostics").setup(cfg)
  require("wraithvim.integrations.treesitter").setup(cfg)
  require("wraithvim.config.autocmds").setup(cfg)
  require("wraithvim.features.autoreload").setup(cfg)
  require("wraithvim.integrations.mason").setup(cfg)
  require("wraithvim.config.commands").setup()
  require("wraithvim.config.keymaps").setup()
  require("wraithvim.features.files").setup()
  require("wraithvim.ui").setup(cfg, plugins_ok)
end

return M
