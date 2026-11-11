-- Small shared helpers. Keep this module dependency-free and cheap to require.

local M = {}

--- Deep merge where lists are replaced rather than concatenated.
--- Later tables win. Inputs are not mutated.
---@param ... table
---@return table
function M.merge(...)
  local result = {}
  for i = 1, select("#", ...) do
    local t = select(i, ...)
    if t ~= nil then
      for k, v in pairs(t) do
        local into_map = type(result[k]) == "table" and not vim.islist(result[k])
        -- An empty table is ambiguous (vim.islist({}) is true); merging it
        -- into a map must keep the map's keys.
        if type(v) == "table" and into_map and (next(v) == nil or not vim.islist(v)) then
          result[k] = M.merge(result[k], v)
        elseif type(v) == "table" then
          result[k] = vim.deepcopy(v)
        else
          result[k] = v
        end
      end
    end
  end
  return result
end

local exe_cache = {}

--- Cached `vim.fn.executable`. PATH lookups hit the filesystem, so cache them.
---@param name string
---@return boolean
function M.executable(name)
  local hit = exe_cache[name]
  if hit == nil then
    hit = vim.fn.executable(name) == 1
    exe_cache[name] = hit
  end
  return hit
end

--- Forget cached executable lookups (e.g. after Mason installs a tool).
function M.reset_executable_cache()
  exe_cache = {}
end

--- Create (or clear) a namespaced augroup.
---@param name string
---@return integer
function M.augroup(name)
  return vim.api.nvim_create_augroup("wraithvim_" .. name, { clear = true })
end

--- True when the buffer's file is larger than `limit` bytes.
---@param buf integer
---@param limit integer
---@return boolean
function M.is_large_file(buf, limit)
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then
    return false
  end
  local stat = vim.uv.fs_stat(name)
  return stat ~= nil and stat.size > limit
end

--- Run a command without a shell. `cmd` must be a list so arguments (including
--- filenames with spaces or shell metacharacters) are passed verbatim.
---@param cmd string[]
---@param opts? vim.SystemOpts
---@return vim.SystemCompleted
function M.run(cmd, opts)
  assert(type(cmd) == "table", "utils.run expects an argument list")
  local ok, proc = pcall(vim.system, cmd, vim.tbl_extend("keep", opts or {}, { text = true }))
  if not ok then
    return { code = -1, signal = 0, stdout = "", stderr = tostring(proc) }
  end
  return proc:wait()
end

--- Trim trailing whitespace/newlines.
---@param s string?
---@return string
function M.trim(s)
  return (s or ""):gsub("%s+$", "")
end

--- Split command output into non-empty lines.
---@param s string?
---@return string[]
function M.lines(s)
  local out = {}
  for line in (s or ""):gmatch("[^\n]+") do
    out[#out + 1] = line
  end
  return out
end

--- True when Neovim is running with at least one attached UI.
---@return boolean
function M.has_ui()
  return #vim.api.nvim_list_uis() > 0
end

return M
