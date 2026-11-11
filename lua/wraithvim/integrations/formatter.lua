-- conform.nvim integration. Formatters come from enabled language profiles;
-- the LSP formatter is only used when no conform formatter applies, so two
-- formatters never fight over the same buffer. Formatters discover project
-- config files (.prettierrc, stylua.toml, pyproject.toml, ...) themselves.

local M = {}

---@return table options.format
local function settings()
  return require("wraithvim.core.config").get().options.format
end

--- Whether format-on-save is active for a buffer (buffer toggle wins over global).
---@param buf integer
---@return boolean
function M.on_save_enabled(buf)
  local b = vim.b[buf].wraith_format_on_save
  if b ~= nil then
    return b
  end
  if vim.g.wraith_format_on_save ~= nil then
    return vim.g.wraith_format_on_save
  end
  return settings().on_save
end

---@return table conform setup options
function M.opts()
  local s = settings()
  local cfg = require("wraithvim.core.config").get()
  local lsp_format = s.lsp_fallback and "fallback" or "never"
  return {
    formatters_by_ft = require("wraithvim.languages").formatters_by_ft(),
    default_format_opts = { lsp_format = lsp_format, timeout_ms = s.timeout_ms },
    format_on_save = function(buf)
      if not M.on_save_enabled(buf) then
        return nil
      end
      if require("wraithvim.core.utils").is_large_file(buf, cfg.options.large_file_size) then
        return nil
      end
      return { timeout_ms = s.timeout_ms, lsp_format = lsp_format }
    end,
    notify_on_error = true,
    notify_no_formatters = false,
  }
end

--- Format the current buffer (or a visual range).
---@param opts? { range?: table }
function M.format(opts)
  opts = opts or {}
  local conform = require("conform")
  local buf = vim.api.nvim_get_current_buf()
  local s = settings()
  local formatters = conform.list_formatters_to_run(buf)
  local has_lsp = s.lsp_fallback and #vim.lsp.get_clients({ bufnr = buf, method = "textDocument/formatting" }) > 0
  if #formatters == 0 and not has_lsp then
    vim.notify(
      ("No formatter available for filetype %q. Install one listed in :Health, or check :ConformInfo."):format(
        vim.bo[buf].filetype
      ),
      vim.log.levels.WARN,
      { title = "Format" }
    )
    return
  end
  conform.format({ bufnr = buf, async = false, range = opts.range, timeout_ms = s.timeout_ms })
end

--- Toggle format-on-save globally or for the current buffer.
---@param buffer_only? boolean
function M.toggle(buffer_only)
  local buf = vim.api.nvim_get_current_buf()
  local new = not M.on_save_enabled(buf)
  if buffer_only then
    vim.b[buf].wraith_format_on_save = new
  else
    vim.g.wraith_format_on_save = new
    vim.b[buf].wraith_format_on_save = nil
  end
  vim.notify(
    ("Format on save %s%s"):format(new and "enabled" or "disabled", buffer_only and " (buffer)" or ""),
    vim.log.levels.INFO,
    { title = "Format" }
  )
end

return M
