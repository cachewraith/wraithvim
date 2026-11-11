-- Native terminal integration.
--
-- One "panel" terminal is reused: toggling hides its window but keeps the
-- shell running. Split terminals are independent. Every terminal buffer is
-- wiped when its process exits, so dead terminals do not accumulate.

local M = {}

---@type { buf: integer?, win: integer? }
M.panel = { buf = nil, win = nil }

---@return string
local function project_dir()
  return vim.fn.getcwd()
end

---@return table ui.terminal
local function settings()
  return require("wraithvim.core.config").get().ui.terminal
end

--- Open a window for `buf` according to `position`.
---@param buf integer
---@param position string
---@return integer win
local function open_window(buf, position)
  local t = settings()
  if position == "float" then
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.7)
    return vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = width,
      height = height,
      row = math.floor((vim.o.lines - height) / 2) - 1,
      col = math.floor((vim.o.columns - width) / 2),
      style = "minimal",
      title = " Terminal ",
      title_pos = "center",
    })
  end
  local split = ({ bottom = "below", top = "above", left = "left", right = "right" })[position] or "below"
  local vertical = split == "left" or split == "right"
  local win = vim.api.nvim_open_win(buf, true, {
    split = split,
    win = -1,
    height = not vertical and t.height or nil,
    width = vertical and t.width or nil,
  })
  vim.wo[win].winfixheight = not vertical
  vim.wo[win].winfixwidth = vertical
  return win
end

--- Configure a fresh terminal buffer and start the shell in it.
---@param buf integer
local function start_shell(buf)
  vim.api.nvim_buf_call(buf, function()
    vim.fn.jobstart(vim.o.shell, { term = true, cwd = project_dir() })
  end)
  vim.bo[buf].buflisted = false
  vim.bo[buf].bufhidden = "hide"
  vim.api.nvim_create_autocmd("TermClose", {
    buffer = buf,
    once = true,
    callback = function()
      vim.schedule(function()
        if M.panel.buf == buf then
          M.panel = { buf = nil, win = nil }
        end
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
      end)
    end,
  })
end

---@param win integer
local function style_window(win)
  local wo = vim.wo[win]
  wo.number = false
  wo.relativenumber = false
  wo.signcolumn = "no"
  wo.cursorline = false
end

--- Open the panel terminal, creating it on first use.
---@param position? string
function M.open(position)
  local t = settings()
  position = position or t.position
  local p = M.panel
  if p.win and vim.api.nvim_win_is_valid(p.win) then
    -- The panel window may have been switched to another buffer meanwhile.
    if p.buf and vim.api.nvim_buf_is_valid(p.buf) and vim.api.nvim_win_get_buf(p.win) ~= p.buf then
      vim.api.nvim_win_set_buf(p.win, p.buf)
    end
    vim.api.nvim_set_current_win(p.win)
  else
    local fresh = not (p.buf and vim.api.nvim_buf_is_valid(p.buf))
    local buf = fresh and vim.api.nvim_create_buf(false, true) or p.buf
    ---@cast buf integer
    local win = open_window(buf, position)
    style_window(win)
    if fresh then
      start_shell(buf)
    end
    M.panel = { buf = buf, win = win }
  end
  vim.cmd.startinsert()
end

--- Hide the panel terminal window; the shell keeps running.
function M.hide()
  local p = M.panel
  if p.win and vim.api.nvim_win_is_valid(p.win) then
    if #vim.api.nvim_tabpage_list_wins(0) == 1 then
      vim.cmd.enew()
    else
      vim.api.nvim_win_close(p.win, false)
    end
  end
  M.panel.win = nil
end

function M.toggle()
  local p = M.panel
  if p.win and vim.api.nvim_win_is_valid(p.win) and vim.api.nvim_win_get_buf(p.win) == p.buf then
    M.hide()
  else
    M.open()
  end
end

--- Open an independent terminal in a new split.
---@param direction? "horizontal"|"vertical"
---@return integer buf
function M.split(direction)
  local position = direction == "vertical" and "right" or "bottom"
  local buf = vim.api.nvim_create_buf(false, true)
  local win = open_window(buf, position)
  style_window(win)
  start_shell(buf)
  vim.cmd.startinsert()
  return buf
end

--- Stop the panel terminal's shell and remove its buffer.
function M.close()
  local p = M.panel
  if p.buf and vim.api.nvim_buf_is_valid(p.buf) then
    local job = vim.b[p.buf].terminal_job_id
    if job then
      pcall(vim.fn.jobstop, job)
    end
    if p.win and vim.api.nvim_win_is_valid(p.win) and #vim.api.nvim_tabpage_list_wins(0) > 1 then
      vim.api.nvim_win_close(p.win, true)
    end
    if vim.api.nvim_buf_is_valid(p.buf) then
      vim.api.nvim_buf_delete(p.buf, { force = true })
    end
  end
  M.panel = { buf = nil, win = nil }
end

--- Buffer-local settings for any terminal buffer.
function M.setup()
  vim.api.nvim_create_autocmd("TermOpen", {
    group = require("wraithvim.core.utils").augroup("terminal"),
    callback = function(args)
      vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], { buffer = args.buf, desc = "Terminal normal mode" })
    end,
  })
end

return M
