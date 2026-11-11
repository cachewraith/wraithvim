-- Minimal file logger.
--
-- Messages are appended to `stdpath("state")/wraithvim/wraithvim.log`. Only
-- WARN and above are written by default so normal editing never touches disk.
-- Never log on redraw paths.

local M = {}

local levels = vim.log.levels
local names = {
  [levels.TRACE] = "TRACE",
  [levels.DEBUG] = "DEBUG",
  [levels.INFO] = "INFO",
  [levels.WARN] = "WARN",
  [levels.ERROR] = "ERROR",
}

local MAX_SIZE = 1024 * 1024 -- rotate after 1 MiB

M.level = levels.WARN

---@return string
function M.path()
  return vim.fs.joinpath(vim.fn.stdpath("state"), "wraithvim", "wraithvim.log")
end

local rotated = false

---@param path string
local function prepare(path)
  if rotated then
    return
  end
  rotated = true
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local stat = vim.uv.fs_stat(path)
  if stat and stat.size > MAX_SIZE then
    os.rename(path, path .. ".1")
  end
end

-- Strip anything that looks like a secret assignment before it reaches disk.
---@param msg string
---@return string
local function redact(msg)
  return (
    msg
      :gsub("([%w_]*[Tt][Oo][Kk][Ee][Nn][%w_]*%s*[=:]%s*)%S+", "%1<redacted>")
      :gsub("([%w_]*[Pp][Aa][Ss][Ss][%w_]*%s*[=:]%s*)%S+", "%1<redacted>")
  )
end

---@param level integer
---@param msg string
---@param ... any format arguments
function M.log(level, msg, ...)
  if level < M.level then
    return
  end
  if select("#", ...) > 0 then
    msg = msg:format(...)
  end
  local path = M.path()
  prepare(path)
  local fd = io.open(path, "a")
  if not fd then
    return
  end
  fd:write(("%s [%s] %s\n"):format(os.date("%Y-%m-%d %H:%M:%S"), names[level] or "?", redact(msg)))
  fd:close()
end

function M.debug(msg, ...)
  M.log(levels.DEBUG, msg, ...)
end
function M.info(msg, ...)
  M.log(levels.INFO, msg, ...)
end
function M.warn(msg, ...)
  M.log(levels.WARN, msg, ...)
end
function M.error(msg, ...)
  M.log(levels.ERROR, msg, ...)
end

--- Log and notify the user. Safe to call from fast (libuv) contexts.
---@param level integer
---@param msg string
function M.notify(level, msg)
  M.log(level, msg)
  vim.schedule(function()
    vim.notify(msg, level, { title = "WraithVim" })
  end)
end

--- Open the log file in a split.
function M.open()
  local path = M.path()
  if not vim.uv.fs_stat(path) then
    vim.notify("WraithVim log is empty: " .. path, levels.INFO, { title = "WraithVim" })
    return
  end
  vim.cmd("botright split " .. vim.fn.fnameescape(path))
  vim.bo.readonly = true
  vim.bo.bufhidden = "wipe"
  vim.cmd("normal! G")
end

return M
