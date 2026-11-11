-- Drive a real Neovim TUI inside a pseudo-terminal. Input (keys and SGR mouse
-- sequences) goes through the terminal like a user's would; state is
-- inspected over the child's --listen socket.

local env = require("tests.helpers.env")

local M = {}
M.__index = M

---@param opts? { args?: string[], env?: table, width?: integer, height?: integer, cwd?: string, installed?: boolean }
---  installed = true runs the user's installed WraithVim (no -u, real XDG dirs)
---  instead of this checkout inside the .tests sandbox.
function M.spawn(opts)
  opts = opts or {}
  local self = setmetatable({}, M)
  self.sock = vim.fn.tempname() .. ".sock"
  self.width = opts.width or 140
  self.height = opts.height or 40
  local cmd = { "nvim", "--listen", self.sock }
  if not opts.installed then
    vim.list_extend(cmd, { "-u", env.root .. "/init.lua" })
  end
  vim.list_extend(cmd, opts.args or {})
  local child_env = opts.installed and (opts.env or {}) or env.env(opts.env)
  self.job = vim.fn.jobstart(cmd, {
    pty = true,
    width = self.width,
    height = self.height,
    cwd = opts.cwd or env.root,
    env = vim.tbl_extend("force", child_env, { TERM = "xterm-256color" }),
    on_stdout = function() end,
  })
  assert(self.job > 0, "failed to start nvim")
  local ok = vim.wait(10000, function()
    return vim.uv.fs_stat(self.sock) ~= nil
  end, 20)
  assert(ok, "nvim did not create its socket")
  self.chan = vim.fn.sockconnect("pipe", self.sock, { rpc = true })
  self:wait_for("vim.v.vim_did_enter == 1", 10000)
  return self
end

---@param code string Lua code, `return`ing a value
function M:lua(code, ...)
  return vim.rpcrequest(self.chan, "nvim_exec_lua", code, { ... })
end

---@param expr string Lua expression evaluated in the child
---@param timeout? integer
---@return boolean
function M:wait_for(expr, timeout)
  return vim.wait(timeout or 5000, function()
    local ok, v = pcall(self.lua, self, "return " .. expr)
    return ok and v == true
  end, 50)
end

--- Send raw bytes to the terminal (as typed keys).
---@param bytes string
function M:send(bytes)
  vim.fn.chansend(self.job, bytes)
end

--- Send keys using Neovim key notation through the terminal.
---@param keys string e.g. "<leader>ee"
function M:keys(keys)
  local bytes = vim.api.nvim_replace_termcodes(keys, true, false, true)
  self:send(bytes)
  if bytes:sub(-1) == "\27" then
    -- A lone Esc is only recognised after 'ttimeoutlen'; otherwise the next
    -- input (e.g. a mouse event) would be read as Alt+<input>.
    vim.wait(150)
  end
end

--- Mouse click at 0-based screen (row, col) using SGR encoding.
---@param row integer
---@param col integer
---@param button? "left"|"middle"|"right"
function M:click(row, col, button)
  local b = ({ left = 0, middle = 1, right = 2 })[button or "left"]
  self:send(("\27[<%d;%d;%dM"):format(b, col + 1, row + 1))
  vim.wait(30)
  self:send(("\27[<%d;%d;%dm"):format(b, col + 1, row + 1))
  vim.wait(100) -- let the click be processed before further input
end

--- Drag with the left button from (row1, col1) to (row2, col2), paced like a
--- human so the terminal input parser sees separate events.
function M:drag(row1, col1, row2, col2)
  self:send(("\27[<0;%d;%dM"):format(col1 + 1, row1 + 1))
  vim.wait(40)
  local steps = 3
  for i = 1, steps do
    local r = row1 + math.floor((row2 - row1) * i / steps)
    local c = col1 + math.floor((col2 - col1) * i / steps)
    self:send(("\27[<32;%d;%dM"):format(c + 1, r + 1))
    vim.wait(40)
  end
  self:send(("\27[<0;%d;%dm"):format(col2 + 1, row2 + 1))
  vim.wait(40)
end

--- Scroll wheel at (row, col).
---@param row integer
---@param col integer
---@param direction "up"|"down"
function M:scroll(row, col, direction)
  local b = direction == "up" and 64 or 65
  self:send(("\27[<%d;%d;%dM"):format(b, col + 1, row + 1))
end

function M.sleep(_, ms)
  vim.wait(ms, function()
    return false
  end)
end

function M:close()
  -- Quit cleanly so no swap files are left behind for the next run.
  pcall(vim.rpcnotify, self.chan, "nvim_command", "qa!")
  vim.wait(2000, function()
    return vim.fn.jobwait({ self.job }, 0)[1] ~= -1
  end, 20)
  pcall(vim.fn.chanclose, self.chan)
  pcall(vim.fn.jobstop, self.job)
  os.remove(self.sock)
end

return M
