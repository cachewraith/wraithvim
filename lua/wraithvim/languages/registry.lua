-- Language profile registry.
--
-- A profile describes filetypes, Treesitter parsers, language servers and
-- formatters. Servers and formatters are maps keyed by name so user overrides
-- in languages.lua merge naturally; setting an entry to `false` removes it.

local utils = require("wraithvim.core.utils")

local M = {}

M.builtin = { "bash", "cpp", "go", "java", "lua", "php", "python", "sql", "typescript", "yaml" }

-- Alternative names accepted in languages.lua.
M.aliases = { javascript = "typescript", c = "cpp", sh = "bash" }

---@param name string
---@return string canonical name
function M.canonical(name)
  return M.aliases[name] or name
end

---@param name string
---@return boolean
function M.is_builtin(name)
  return vim.tbl_contains(M.builtin, name)
end

--- Drop entries set to `false`.
---@param map table?
---@return table
local function prune(map)
  local out = {}
  for k, v in pairs(map or {}) do
    if v ~= false then
      out[k] = v
    end
  end
  return out
end

--- Merge a builtin profile (if any) with user settings.
---@param name string canonical language name
---@param user table settings from languages.lua (may be a custom profile)
---@return table? profile, string? err
function M.resolve(name, user)
  local base = {}
  if M.is_builtin(name) then
    base = require("wraithvim.languages." .. name)
  elseif type(user.filetypes) ~= "table" then
    return nil, ("languages.%s: unknown language (custom profiles need a `filetypes` list)"):format(name)
  end
  local merged = utils.merge(base, user)
  merged.name = name
  merged.filetypes = merged.filetypes or {}
  merged.parsers = merged.parsers or {}
  merged.servers = prune(merged.servers)
  merged.formatters = prune(merged.formatters)
  if user.lsp == false then
    merged.servers = {}
  end
  if user.format == false then
    merged.formatters = {}
  end
  return merged
end

return M
