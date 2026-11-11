-- Lightweight vim.notify replacement: stacked floating windows in the top
-- right corner. Each notification owns a single one-shot timer that closes
-- it; nothing runs while no notification is visible. Without an attached UI
-- (headless) messages go to the original vim.notify.

local M = {}

local MAX_HISTORY = 100
local MAX_LINES = 10

---@type { msg: string, level: integer, title: string?, time: string }[]
M.history = {}

---@type { win: integer, buf: integer, height: integer }[]
local active = {}
local pending = {}
local original_notify = vim.notify
local opts_cfg = { timeout = 3000, max_width = 60, level = vim.log.levels.INFO }

local level_hl = {
  [vim.log.levels.ERROR] = "DiagnosticError",
  [vim.log.levels.WARN] = "DiagnosticWarn",
  [vim.log.levels.INFO] = "DiagnosticInfo",
  [vim.log.levels.DEBUG] = "Comment",
  [vim.log.levels.TRACE] = "Comment",
}

local level_name = {
  [vim.log.levels.ERROR] = "ERROR",
  [vim.log.levels.WARN] = "WARN",
  [vim.log.levels.INFO] = "INFO",
  [vim.log.levels.DEBUG] = "DEBUG",
  [vim.log.levels.TRACE] = "TRACE",
}

--- Wrap message text to the configured width.
---@param msg string
---@param width integer
---@return string[]
function M.wrap(msg, width)
  local out = {}
  for _, line in ipairs(vim.split(msg, "\n", { plain = true })) do
    while vim.fn.strdisplaywidth(line) > width do
      local cut = vim.fn.byteidx(line, width)
      if cut <= 0 then
        break
      end
      out[#out + 1] = line:sub(1, cut)
      line = line:sub(cut + 1)
    end
    out[#out + 1] = line
  end
  if #out > MAX_LINES then
    out = vim.list_slice(out, 1, MAX_LINES)
    out[#out + 1] = "... (:WraithNotifications for full text)"
  end
  return out
end

local function restack()
  local row = vim.o.showtabline > 0 and 1 or 0
  for _, n in ipairs(active) do
    if vim.api.nvim_win_is_valid(n.win) then
      vim.api.nvim_win_set_config(n.win, { relative = "editor", anchor = "NE", row = row, col = vim.o.columns })
      row = row + n.height + 2
    end
  end
end

local function close(entry)
  for i, n in ipairs(active) do
    if n == entry then
      table.remove(active, i)
      break
    end
  end
  if vim.api.nvim_win_is_valid(entry.win) then
    vim.api.nvim_win_close(entry.win, true)
  end
  if vim.api.nvim_buf_is_valid(entry.buf) then
    vim.api.nvim_buf_delete(entry.buf, { force = true })
  end
  restack()
end

---@param msg string
---@param level integer
---@param title string?
local function show(msg, level, title)
  local lines = M.wrap(msg, opts_cfg.max_width)
  local width = 1
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  if title then
    width = math.max(width, vim.fn.strdisplaywidth(title) + 2)
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].bufhidden = "wipe"
  local border = vim.o.winborder ~= "" and vim.o.winborder ~= "none" and vim.o.winborder or "rounded"
  local ok, win = pcall(vim.api.nvim_open_win, buf, false, {
    relative = "editor",
    anchor = "NE",
    row = 0,
    col = vim.o.columns,
    width = width,
    height = #lines,
    style = "minimal",
    border = border,
    title = title and (" " .. title .. " ") or nil,
    title_pos = title and "left" or nil,
    focusable = false,
    noautocmd = true,
    zindex = 150,
  })
  if not ok then
    vim.api.nvim_buf_delete(buf, { force = true })
    original_notify(msg, level)
    return
  end
  local hl = level_hl[level] or "Normal"
  vim.wo[win].winhighlight = "Normal:NormalFloat,FloatBorder:" .. hl .. ",FloatTitle:" .. hl
  vim.wo[win].wrap = false
  local entry = { win = win, buf = buf, height = #lines }
  table.insert(active, 1, entry)
  restack()
  local timeout = level >= vim.log.levels.ERROR and opts_cfg.timeout * 2 or opts_cfg.timeout
  vim.defer_fn(function()
    close(entry)
  end, timeout)
end

--- vim.notify replacement.
---@param msg any
---@param level? integer
---@param opts? table
function M.notify(msg, level, opts)
  msg = type(msg) == "string" and msg or vim.inspect(msg)
  level = level or vim.log.levels.INFO
  local title = opts and opts.title or nil
  table.insert(M.history, { msg = msg, level = level, title = title, time = os.date("%H:%M:%S") })
  if #M.history > MAX_HISTORY then
    table.remove(M.history, 1)
  end
  if level < opts_cfg.level then
    return
  end
  if vim.in_fast_event() then
    return vim.schedule(function()
      M.notify_ui(msg, level, title)
    end)
  end
  M.notify_ui(msg, level, title)
end

---@param msg string
---@param level integer
---@param title string?
function M.notify_ui(msg, level, title)
  if not require("wraithvim.core.utils").has_ui() then
    original_notify(msg, level, { title = title })
    return
  end
  -- The TUI attaches before startup finishes; hold messages until VimEnter
  -- so windows are not opened mid-initialisation.
  if vim.v.vim_did_enter == 0 then
    pending[#pending + 1] = { msg, level, title }
    return
  end
  show(msg, level, title)
end

--- Show notification history in a scratch buffer.
function M.show_history()
  local lines = {}
  for _, n in ipairs(M.history) do
    local head = ("%s [%s]%s"):format(n.time, level_name[n.level] or "?", n.title and (" " .. n.title) or "")
    lines[#lines + 1] = head
    for _, l in ipairs(vim.split(n.msg, "\n", { plain = true })) do
      lines[#lines + 1] = "  " .. l
    end
  end
  if #lines == 0 then
    lines = { "No notifications." }
  end
  vim.cmd("botright new")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "wraithnotifications"
end

--- Close all visible notifications.
function M.dismiss()
  for i = #active, 1, -1 do
    close(active[i])
  end
end

---@param cfg table ui.notifications
function M.setup(cfg)
  opts_cfg = cfg
  original_notify = vim.notify
  vim.notify = M.notify
  vim.api.nvim_create_autocmd("VimEnter", {
    group = require("wraithvim.core.utils").augroup("notifications"),
    once = true,
    callback = function()
      vim.schedule(function()
        for _, p in ipairs(pending) do
          M.notify_ui(p[1], p[2], p[3])
        end
        pending = {}
      end)
    end,
  })
end

return M
