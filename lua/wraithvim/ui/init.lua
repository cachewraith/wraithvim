-- UI orchestration: theme, highlight overrides, dashboard, notifications and
-- panel defaults. Component configuration for plugins lives next to this
-- file (statusline.lua, tabline.lua, explorer.lua) and is read lazily.

local utils = require("wraithvim.core.utils")
local logger = require("wraithvim.core.logger")

local M = {}

--- WraithVim's own highlight groups, linked to standard groups so every
--- colorscheme styles them. `:colorscheme` clears them, so this runs after
--- every colorscheme load.
function M.define_highlights()
  local links = {
    WraithDashboardHeader = "Title",
    WraithDashboardItem = "Normal",
    WraithDashboardFooter = "Comment",
    WraithTermTitle = "Title",
    WraithTermInfo = "Comment",
    WraithTermButton = "Special",
    WraithTreeButton = "Special",
    WraithTreeIcon = "Comment",
  }
  for group, target in pairs(links) do
    vim.api.nvim_set_hl(0, group, { link = target, default = true })
  end
end

--- Apply `ui.colors` overrides. Runs after every :colorscheme.
---@param colors table<string, table>
function M.apply_colors(colors)
  for group, spec in pairs(colors) do
    local ok, err = pcall(vim.api.nvim_set_hl, 0, group, spec)
    if not ok then
      logger.warn("ui.colors.%s: %s", group, err)
    end
  end
end

---@param ui table
function M.apply_theme(ui)
  local name = ui.theme.colorscheme
  if name == "tokyonight" and ui.theme.style then
    name = "tokyonight-" .. ui.theme.style
  end
  local ok, err = pcall(vim.cmd.colorscheme, name)
  if not ok then
    logger.notify(vim.log.levels.WARN, ("Colorscheme %q failed to load, using habamax: %s"):format(name, err))
    pcall(vim.cmd.colorscheme, "habamax")
  end
end

---@param cfg table effective configuration
---@param plugins_ok boolean whether lazy.nvim was set up
function M.setup(cfg, plugins_ok)
  local ui = cfg.ui

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = utils.augroup("ui_colors"),
    callback = function()
      M.define_highlights()
      M.apply_colors(ui.colors)
    end,
  })
  M.define_highlights()

  if ui.notifications.enabled then
    require("wraithvim.ui.notifications").setup(ui.notifications)
  end

  if plugins_ok then
    M.apply_theme(ui)
  else
    pcall(vim.cmd.colorscheme, "habamax")
  end

  if not ui.tabline.enabled then
    vim.o.showtabline = 1
  end
  if not ui.statusline.enabled then
    vim.o.laststatus = 2
  end

  if ui.dashboard.enabled then
    require("wraithvim.ui.dashboard").setup()
  end

  if plugins_ok and ui.explorer.enabled and ui.explorer.auto_open then
    require("wraithvim.features.explorer").setup_auto_open()
  end
end

return M
