-- Diagnostic display configuration (native vim.diagnostic).

local M = {}

---@param cfg table effective configuration
---@return vim.diagnostic.Opts
function M.opts(cfg)
  local d = cfg.options.diagnostics
  local ic = require("wraithvim.ui.icons").get().diagnostics
  local sev = vim.diagnostic.severity
  return {
    underline = d.underline,
    update_in_insert = d.update_in_insert,
    severity_sort = d.severity_sort,
    virtual_text = d.virtual_text and { spacing = 2, source = "if_many", prefix = "●" } or false,
    float = { border = cfg.ui.border, source = "if_many" },
    signs = {
      text = {
        [sev.ERROR] = ic.Error,
        [sev.WARN] = ic.Warn,
        [sev.INFO] = ic.Info,
        [sev.HINT] = ic.Hint,
      },
    },
  }
end

---@param cfg table
function M.setup(cfg)
  vim.diagnostic.config(M.opts(cfg))
end

--- Toggle inline virtual text.
function M.toggle_virtual_text()
  local current = vim.diagnostic.config().virtual_text
  if current then
    vim.diagnostic.config({ virtual_text = false })
  else
    vim.diagnostic.config({ virtual_text = { spacing = 2, source = "if_many", prefix = "●" } })
  end
  vim.notify("Diagnostic virtual text " .. (current and "off" or "on"), vim.log.levels.INFO, { title = "WraithVim" })
end

--- Toggle diagnostics for the current buffer.
function M.toggle_buffer()
  local enabled = vim.diagnostic.is_enabled({ bufnr = 0 })
  vim.diagnostic.enable(not enabled, { bufnr = 0 })
  vim.notify(
    "Diagnostics " .. (enabled and "disabled" or "enabled") .. " for this buffer",
    vim.log.levels.INFO,
    { title = "WraithVim" }
  )
end

return M
