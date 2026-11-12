-- Start screen shown when Neovim starts without file arguments.
-- Plain buffer, no plugin, no timers. Items work with keys, <CR> or a mouse click.

local M = {}

M.filetype = "wraithdashboard"

local logo = {
  [[ __        __         _ _   _  __     ___           ]],
  [[ \ \      / / __ __ _(_) |_| |_\ \   / (_)_ __ ___  ]],
  [[  \ \ /\ / / '__/ _` | | __| '_ \ \ / /| | '_ ` _ \ ]],
  [[   \ V  V /| | | (_| | | |_| | | \ V / | | | | | | |]],
  [[    \_/\_/ |_|  \__,_|_|\__|_| |_|\_/  |_|_| |_| |_|]],
}

---@return table[] { key, label, icon, action }
function M.items()
  local ic = require("wraithvim.ui.icons").get().dashboard
  return {
    { key = "f", icon = ic.find, label = "Find file", action = "Telescope find_files" },
    { key = "r", icon = ic.recent, label = "Recent files", action = "Telescope oldfiles" },
    {
      key = "g",
      icon = ic.grep,
      label = "Search text",
      action = "lua require('wraithvim.features.search').live_grep()",
    },
    { key = "n", icon = ic.new, label = "New file", action = "enew" },
    {
      key = "e",
      icon = ic.explorer,
      label = "Explorer",
      action = "lua require('wraithvim.features.explorer').toggle()",
    },
    { key = "c", icon = ic.config, label = "Configuration", action = "Config" },
    { key = "p", icon = ic.plugins, label = "Plugins", action = "Lazy" },
    { key = "h", icon = ic.health, label = "Health check", action = "Health" },
    { key = "q", icon = ic.quit, label = "Quit", action = "qa" },
  }
end

---@type { buf: integer?, item_rows: table<integer, table>, footer: string }
local state = { buf = nil, item_rows = {}, footer = "" }

---@param text string
---@param width integer
---@return string
local function center(text, width)
  local pad = math.max(0, math.floor((width - vim.fn.strdisplaywidth(text)) / 2))
  return string.rep(" ", pad) .. text
end

--- Render the dashboard into its buffer for the given window size.
---@param buf integer
---@param width integer
---@param height integer
function M.render(buf, width, height)
  local items = M.items()
  local body = {}
  local hl = {}
  for _, line in ipairs(logo) do
    body[#body + 1] = { text = line, hl = "WraithDashboardHeader" }
  end
  body[#body + 1] = { text = "" }
  body[#body + 1] = { text = "lightweight Neovim for terminal developers", hl = "WraithDashboardFooter" }
  body[#body + 1] = { text = "" }
  local label_width = 0
  for _, item in ipairs(items) do
    label_width = math.max(label_width, vim.fn.strdisplaywidth(item.icon .. item.label))
  end
  for _, item in ipairs(items) do
    local text = item.icon .. item.label
    text = text .. string.rep(" ", label_width - vim.fn.strdisplaywidth(text) + 4) .. "[" .. item.key .. "]"
    body[#body + 1] = { text = text, hl = "WraithDashboardItem", item = item }
  end
  body[#body + 1] = { text = "" }
  body[#body + 1] = { text = state.footer, hl = "WraithDashboardFooter" }

  local top = math.max(0, math.floor((height - #body) / 2))
  local lines = {}
  for _ = 1, top do
    lines[#lines + 1] = ""
  end
  state.item_rows = {}
  -- Items share a left edge so the key column lines up.
  local item_pad = math.max(0, math.floor((width - (label_width + 7)) / 2))
  for _, entry in ipairs(body) do
    local text
    if entry.item then
      text = string.rep(" ", item_pad) .. entry.text
      state.item_rows[#lines + 1] = entry.item
    else
      text = center(entry.text, width)
    end
    lines[#lines + 1] = text
    if entry.hl then
      hl[#hl + 1] = { row = #lines - 1, group = entry.hl }
    end
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  local ns = vim.api.nvim_create_namespace("wraithvim_dashboard")
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, h in ipairs(hl) do
    vim.api.nvim_buf_set_extmark(buf, ns, h.row, 0, { line_hl_group = h.group })
  end
end

---@param item table
local function run(item)
  vim.cmd(item.action)
end

--- Run the item under the cursor (or the mouse, for clicks).
---@param from_mouse boolean
function M.activate(from_mouse)
  local row
  if from_mouse then
    local pos = vim.fn.getmousepos()
    if pos.winid ~= vim.api.nvim_get_current_win() or pos.line == 0 then
      return
    end
    row = pos.line
  else
    row = vim.api.nvim_win_get_cursor(0)[1]
  end
  local item = state.item_rows[row]
  if item then
    run(item)
  end
end

local function redraw()
  local buf = state.buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local win = vim.fn.bufwinid(buf)
  if win == -1 then
    return
  end
  M.render(buf, vim.api.nvim_win_get_width(win), vim.api.nvim_win_get_height(win))
end

--- True when Neovim was started without files and with an empty buffer.
---@return boolean
function M.should_open()
  if vim.fn.argc(-1) > 0 or vim.g.wraithvim_stdin then
    return false
  end
  local buf = vim.api.nvim_get_current_buf()
  if vim.api.nvim_buf_get_name(buf) ~= "" or vim.bo[buf].modified then
    return false
  end
  return vim.api.nvim_buf_line_count(buf) == 1 and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ""
end

function M.open()
  local buf = vim.api.nvim_get_current_buf()
  -- Reuse the initial empty buffer so no extra buffer is left behind.
  state.buf = buf
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].buflisted = false
  vim.bo[buf].filetype = M.filetype
  local wo = vim.wo[0][0]
  wo.number = false
  wo.relativenumber = false
  wo.signcolumn = "no"
  wo.cursorline = false
  wo.list = false
  wo.foldcolumn = "0"

  for _, item in ipairs(M.items()) do
    vim.keymap.set("n", item.key, function()
      run(item)
    end, { buffer = buf, nowait = true, desc = item.label })
  end
  vim.keymap.set("n", "<CR>", function()
    M.activate(false)
  end, { buffer = buf, desc = "Open item" })
  vim.keymap.set("n", "<LeftRelease>", function()
    M.activate(true)
  end, { buffer = buf, desc = "Open item" })

  local group = require("wraithvim.core.utils").augroup("dashboard")
  vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, { group = group, callback = redraw })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    buffer = buf,
    callback = function()
      state.buf = nil
      pcall(vim.api.nvim_del_augroup_by_id, group)
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "LazyVimStarted",
    once = true,
    callback = function()
      local ok, lazy = pcall(require, "lazy")
      if ok then
        local stats = lazy.stats()
        state.footer = ("%d/%d plugins loaded in %.1f ms"):format(stats.loaded, stats.count, stats.startuptime)
        redraw()
      end
    end,
  })
  redraw()
  -- Place the cursor on the first item.
  local first = math.huge
  for row in pairs(state.item_rows) do
    first = math.min(first, row)
  end
  if first ~= math.huge then
    vim.api.nvim_win_set_cursor(0, { first, 0 })
  end
end

function M.setup()
  local group = require("wraithvim.core.utils").augroup("dashboard_start")
  vim.api.nvim_create_autocmd("StdinReadPre", {
    group = group,
    callback = function()
      vim.g.wraithvim_stdin = true
    end,
  })
  vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    once = true,
    callback = function()
      if M.should_open() then
        M.open()
      end
    end,
  })
end

return M
