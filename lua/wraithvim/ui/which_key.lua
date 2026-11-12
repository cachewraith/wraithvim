-- which-key options. Group names come from the keymap registry so the popup,
-- the cheatsheet and docs/keymaps.md agree.

local M = {}

---@return table which-key setup options
function M.opts()
  local cfg = require("wraithvim.core.config").get()
  local spec = {}
  for _, g in ipairs(require("wraithvim.config.keymaps").groups) do
    spec[#spec + 1] = { g[1], group = g[2] }
  end
  return {
    preset = "modern",
    delay = 300,
    spec = spec,
    icons = { mappings = cfg.ui.icons.nerd_font },
    win = { border = cfg.ui.border },
  }
end

return M
