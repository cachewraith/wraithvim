-- Enabled language profiles and the data derived from them.

local registry = require("wraithvim.languages.registry")
local logger = require("wraithvim.core.logger")

local M = {}

---@type table[]?
local cache

--- Resolved profiles for enabled languages, sorted by name.
---@param cfg? table effective configuration
---@return table[]
function M.enabled(cfg)
  if cache and not cfg then
    return cache
  end
  cfg = cfg or require("wraithvim.core.config").get()
  -- Fold aliases into their canonical profile. Canonical names first, so an
  -- alias (e.g. `javascript = false`) deterministically overrides them.
  local utils = require("wraithvim.core.utils")
  local settings = {}
  for _, pass_aliases in ipairs({ false, true }) do
    for name, value in pairs(cfg.languages) do
      if (registry.aliases[name] ~= nil) == pass_aliases then
        local canonical = registry.canonical(name)
        settings[canonical] = utils.merge(settings[canonical] or {}, value)
      end
    end
  end
  local profiles = {}
  for name, user in pairs(settings) do
    if user.enabled ~= false then
      local profile, err = registry.resolve(name, user)
      if profile then
        profiles[#profiles + 1] = profile
      else
        logger.notify(vim.log.levels.WARN, err)
      end
    end
  end
  table.sort(profiles, function(a, b)
    return a.name < b.name
  end)
  cache = profiles
  return profiles
end

--- Forget cached profiles (tests, config reload).
function M.reset()
  cache = nil
end

---@param profiles? table[]
---@return string[]
function M.filetypes(profiles)
  local seen, out = {}, {}
  for _, p in ipairs(profiles or M.enabled()) do
    for _, ft in ipairs(p.filetypes) do
      if not seen[ft] then
        seen[ft] = true
        out[#out + 1] = ft
      end
    end
  end
  return out
end

---@param profiles? table[]
---@return string[]
function M.parsers(profiles)
  local seen, out = {}, {}
  for _, p in ipairs(profiles or M.enabled()) do
    for _, parser in ipairs(p.parsers) do
      if not seen[parser] then
        seen[parser] = true
        out[#out + 1] = parser
      end
    end
  end
  return out
end

--- Language servers of enabled profiles: { name, cmd, mason, install, config, language }.
---@param profiles? table[]
---@return table[]
function M.servers(profiles)
  local out = {}
  for _, p in ipairs(profiles or M.enabled()) do
    local names = vim.tbl_keys(p.servers)
    table.sort(names)
    for _, name in ipairs(names) do
      local s = p.servers[name]
      -- filetypes: custom servers unknown to nvim-lspconfig would otherwise
      -- attach to every buffer.
      out[#out + 1] =
        vim.tbl_extend("force", s, { name = name, language = p.name, filetypes = p.filetypes, config = s.config or {} })
    end
  end
  return out
end

--- Extra tools (linters) of enabled profiles: { name, cmd, mason, install, language }.
---@param profiles? table[]
---@return table[]
function M.tools(profiles)
  local out = {}
  for _, p in ipairs(profiles or M.enabled()) do
    local names = vim.tbl_keys(p.tools or {})
    table.sort(names)
    for _, name in ipairs(names) do
      out[#out + 1] = vim.tbl_extend("force", p.tools[name], { name = name, language = p.name })
    end
  end
  return out
end

--- Formatters of enabled profiles, deduplicated by name.
---@param profiles? table[]
---@return table[]
function M.formatters(profiles)
  local seen, out = {}, {}
  for _, p in ipairs(profiles or M.enabled()) do
    local names = vim.tbl_keys(p.formatters)
    table.sort(names)
    for _, name in ipairs(names) do
      if not seen[name] then
        seen[name] = true
        out[#out + 1] = vim.tbl_extend("force", p.formatters[name], { name = name, language = p.name })
      end
    end
  end
  return out
end

--- conform.nvim `formatters_by_ft`.
---@param profiles? table[]
---@return table<string, string[]>
function M.formatters_by_ft(profiles)
  local by_ft = {}
  for _, p in ipairs(profiles or M.enabled()) do
    local names = vim.tbl_keys(p.formatters)
    table.sort(names)
    for _, name in ipairs(names) do
      for _, ft in ipairs(p.formatters[name].filetypes or p.filetypes) do
        by_ft[ft] = by_ft[ft] or {}
        if not vim.tbl_contains(by_ft[ft], name) then
          table.insert(by_ft[ft], name)
        end
      end
    end
  end
  return by_ft
end

return M
