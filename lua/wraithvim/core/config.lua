-- Configuration loading, merging and validation.
--
-- Distribution defaults live in `wraithvim.config.defaults`. Personal settings
-- live in `$XDG_CONFIG_HOME/wraithvim/*.lua` (or `$WRAITHVIM_CONFIG_DIR`), which
-- the installer and updater never touch. Each user file returns a table; a
-- missing file is equivalent to returning `{}`.

local utils = require("wraithvim.core.utils")
local logger = require("wraithvim.core.logger")

local M = {}

-- keymaps.lua is loaded later by `load_keymaps()` so that direct
-- `vim.keymap.set()` calls in it run after the default mappings exist.
M.files = { "options", "ui", "languages", "plugins" }

-- Paths whose children are free-form and therefore not validated.
local open_tables = {
  ["options.opt"] = true,
  ["ui.colors"] = true,
}

---@type table?
M.values = nil

---@type string[]
M.problems = {}

---@return string
function M.dir()
  if vim.env.WRAITHVIM_CONFIG_DIR and vim.env.WRAITHVIM_CONFIG_DIR ~= "" then
    return vim.fs.normalize(vim.env.WRAITHVIM_CONFIG_DIR)
  end
  local base = vim.env.XDG_CONFIG_HOME
  if not base or base == "" then
    base = vim.fs.joinpath(vim.env.HOME or vim.fn.expand("~"), ".config")
  end
  return vim.fs.joinpath(base, "wraithvim")
end

---@param name string
---@return string
function M.path(name)
  return vim.fs.joinpath(M.dir(), name .. ".lua")
end

--- Load one user configuration file.
---@param name string one of M.files
---@return table? value, string? err  `value` is nil only on error
function M.load_file(name)
  local path = M.path(name)
  if not vim.uv.fs_stat(path) then
    return {}
  end
  local chunk, load_err = loadfile(path)
  if not chunk then
    return nil, ("%s: syntax error: %s"):format(path, load_err)
  end
  local ok, result = pcall(chunk)
  if not ok then
    return nil, ("%s: runtime error: %s"):format(path, result)
  end
  if result == nil then
    return {}
  end
  if type(result) ~= "table" then
    return nil, ("%s: must return a table, got %s"):format(path, type(result))
  end
  return result
end

--- Validate `value` against the shape of `default`.
--- Type mismatches are replaced by the default; unknown keys are reported.
---@param value table
---@param default table
---@param path string
---@param problems string[]
---@return table sanitized copy of value
function M.validate(value, default, path, problems)
  local out = {}
  for key, v in pairs(value) do
    local key_path = path == "" and tostring(key) or (path .. "." .. tostring(key))
    local d = default[key]
    if d == nil then
      problems[#problems + 1] = ("%s: unknown option"):format(key_path)
      out[key] = v
    elseif type(v) ~= type(d) then
      problems[#problems + 1] = ("%s: expected %s, got %s (using default)"):format(key_path, type(d), type(v))
    elseif type(v) == "table" and not vim.islist(d) and not open_tables[key_path] then
      out[key] = M.validate(v, d, key_path, problems)
    else
      out[key] = v
    end
  end
  return out
end

--- Split a user file that mixes list entries with named keys.
---@param t table
---@return table list, table named
local function split(t)
  local list, named = {}, {}
  for k, v in pairs(t) do
    if type(k) == "number" then
      list[k] = v
    else
      named[k] = v
    end
  end
  return list, named
end

--- Normalise languages.lua: allow `go = false` shorthand and custom profiles.
---@param user table
---@param defaults table
---@param problems string[]
---@return table
local function normalize_languages(user, defaults, problems)
  local registry = require("wraithvim.languages.registry")
  local out = vim.deepcopy(defaults)
  for name, v in pairs(user) do
    if type(v) == "boolean" then
      v = { enabled = v }
    end
    if type(name) ~= "string" or type(v) ~= "table" then
      problems[#problems + 1] = ("languages.%s: expected a table or boolean"):format(tostring(name))
    else
      if v.enabled ~= nil and type(v.enabled) ~= "boolean" then
        problems[#problems + 1] = ("languages.%s.enabled: expected boolean"):format(name)
        v.enabled = nil
      end
      -- Enabled unknown names are reported when the profile is resolved; a
      -- disabled one would otherwise be a silent typo (`pyhton = false`).
      if v.enabled == false and v.filetypes == nil and not registry.is_builtin(registry.canonical(name)) then
        problems[#problems + 1] = ("languages.%s: unknown language"):format(name)
      end
      out[name] = utils.merge(out[name] or { enabled = true }, v)
    end
  end
  return out
end

---@param name string
---@return table
local function load_preset(name, problems)
  local ok, preset = pcall(require, "wraithvim.ui.presets." .. name)
  if ok and type(preset) == "table" then
    return preset
  end
  problems[#problems + 1] = ("ui.preset: unknown preset %q (using default)"):format(name)
  return require("wraithvim.ui.presets.default")
end

--- Build the effective configuration. `overrides` (used by tests and
--- `require("wraithvim").setup()`) take precedence over user files.
---@param overrides? table
---@return table
function M.setup(overrides)
  overrides = overrides or {}
  local defaults = require("wraithvim.config.defaults")
  local problems = {}
  local user = {}

  for _, name in ipairs(M.files) do
    local value, err = M.load_file(name)
    if err then
      problems[#problems + 1] = err
      value = {}
    end
    user[name] = utils.merge(value, overrides[name])
  end

  local cfg = {}

  cfg.options = utils.merge(defaults.options, M.validate(user.options, defaults.options, "options", problems))

  local ui_user = user.ui
  local preset_name = type(ui_user.preset) == "string" and ui_user.preset or defaults.ui.preset
  local preset = load_preset(preset_name, problems)
  local ui_base = utils.merge(defaults.ui, preset)
  cfg.ui = utils.merge(ui_base, M.validate(ui_user, ui_base, "ui", problems))

  cfg.languages = normalize_languages(user.languages, defaults.languages, problems)

  local plugin_specs, plugin_named = split(user.plugins)
  cfg.plugins = utils.merge(defaults.plugins, M.validate(plugin_named, defaults.plugins, "plugins", problems))
  cfg.plugins.specs = plugin_specs

  cfg.keymaps = vim.deepcopy(defaults.keymaps)
  cfg.keymaps.entries = {}
  M.overrides = overrides

  M.values = cfg
  M.problems = problems
  M.report(problems)
  return cfg
end

---@param problems string[]
function M.report(problems)
  if #problems > 0 then
    local msg = "WraithVim configuration problems:\n- " .. table.concat(problems, "\n- ")
    logger.notify(vim.log.levels.WARN, msg)
  end
end

--- Load keymaps.lua into `values.keymaps`. Called after default mappings are set.
---@return table keymaps { disable = string[]|table[], entries = table[] }
function M.load_keymaps()
  local cfg = M.get()
  local defaults = require("wraithvim.config.defaults")
  local problems = {}
  local value, err = M.load_file("keymaps")
  if err then
    problems[#problems + 1] = err
    value = {}
  end
  value = utils.merge(value, (M.overrides or {}).keymaps)
  local list, named = split(value)
  cfg.keymaps = utils.merge(defaults.keymaps, M.validate(named, defaults.keymaps, "keymaps", problems))
  cfg.keymaps.entries = list
  vim.list_extend(M.problems, problems)
  M.report(problems)
  return cfg.keymaps
end

--- Effective configuration (builds defaults on first access).
---@return table
function M.get()
  return M.values or M.setup()
end

return M
