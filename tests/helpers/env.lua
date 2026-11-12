-- Test environment helpers: sandboxed XDG directories and child Neovim processes.

local M = {}

M.root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
M.sandbox = vim.env.WRAITHVIM_TEST_HOME or (M.root .. "/.tests")

--- Environment for child processes: isolated XDG dirs sharing installed plugins.
---@param extra? table<string, string>
---@return table<string, string>
function M.env(extra)
  local env = {
    XDG_CONFIG_HOME = M.sandbox .. "/config",
    XDG_DATA_HOME = M.sandbox .. "/data",
    XDG_STATE_HOME = M.sandbox .. "/state",
    XDG_CACHE_HOME = M.sandbox .. "/cache",
    WRAITHVIM_CONFIG_DIR = M.root .. "/tests/fixtures/config",
  }
  return vim.tbl_extend("force", env, extra or {})
end

--- Fresh temporary directory (removed by caller via vim.fn.delete(dir, "rf")).
---@param prefix? string
---@return string
function M.tmpdir(prefix)
  local dir = vim.fn.tempname() .. "-" .. (prefix or "wv")
  vim.fn.mkdir(dir, "p")
  return vim.uv.fs_realpath(dir) or dir
end

---@param path string
---@param content string
function M.write(path, content)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local fd = assert(io.open(path, "w"))
  fd:write(content)
  fd:close()
end

---@param path string
---@return string?
function M.read(path)
  local fd = io.open(path, "r")
  if not fd then
    return nil
  end
  local s = fd:read("*a")
  fd:close()
  return s
end

--- Run headless WraithVim with a Lua snippet; the snippet's return value is
--- JSON-encoded to stdout. Returns the decoded value (or nil, stderr).
---@param code string Lua code executed after startup (and after `wait_ms`)
---@param opts? { env?: table, args?: string[], wait_ms?: integer, timeout?: integer, cwd?: string }
---@return any result, string? err
function M.headless(code, opts)
  opts = opts or {}
  local script = vim.fn.tempname() .. ".lua"
  M.write(
    script,
    ([[
local ok, res = pcall(function() %s end)
local out = vim.json.encode({ ok = ok, res = res, messages = vim.api.nvim_exec2("messages", { output = true }).output })
io.stdout:write("@@RESULT@@" .. out .. "@@END@@\n")
vim.cmd("qa!")
]]):format(code)
  )
  local cmd = { "nvim", "--headless", "-u", M.root .. "/init.lua" }
  vim.list_extend(cmd, opts.args or {})
  vim.list_extend(cmd, {
    "-c",
    ("lua vim.defer_fn(function() dofile(%q) end, %d)"):format(script, opts.wait_ms or 100),
  })
  local r =
    vim.system(cmd, { env = M.env(opts.env), text = true, cwd = opts.cwd or M.root }):wait(opts.timeout or 60000)
  os.remove(script)
  local json = (r.stdout or ""):match("@@RESULT@@(.-)@@END@@")
  if not json then
    return nil, ("no result (code %s)\nstdout: %s\nstderr: %s"):format(r.code, r.stdout, r.stderr)
  end
  local decoded = vim.json.decode(json, { luanil = { object = true, array = true } })
  if not decoded.ok then
    return nil, tostring(decoded.res) .. "\n" .. tostring(decoded.messages)
  end
  return decoded.res, decoded.messages
end

return M
