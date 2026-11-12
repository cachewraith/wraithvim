-- Native terminal integration, styled after VS Code's terminal panel.
--
-- One "panel" terminal is reused: toggling hides its window but keeps the
-- shell running. Extra terminals open beside it or in splits. Every terminal
-- buffer is wiped when its process exits, so dead terminals do not pile up.
--
-- Terminal windows get a header (winbar) with the shell, its folder and
-- clickable New / Hide / Kill buttons. Entering a terminal window or clicking
-- inside it switches straight to typing (see config/autocmds.lua).

local M = {}

M.filetype = "wraithterm"

---@type { buf: integer?, win: integer? }
M.panel = { buf = nil, win = nil }

---@return table ui.terminal
local function settings()
  return require("wraithvim.core.config").get().ui.terminal
end

--- Shell command as an argument list (no extra `sh -c` wrapper process).
---@return string[]
function M.shell_cmd()
  local shell = settings().shell
  if shell == nil or shell == "" then
    shell = vim.o.shell
  end
  return vim.split(shell, "%s+", { trimempty = true })
end

--- Open a window for `buf` according to `position`.
---@param buf integer
---@param position string
---@param anchor? integer split this window instead of the whole editor
---@return integer win
local function open_window(buf, position, anchor)
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
    win = anchor or -1,
    height = (not vertical and not anchor) and t.height or nil,
    width = (vertical and not anchor) and t.width or nil,
  })
  vim.wo[win].winfixheight = not vertical
  vim.wo[win].winfixwidth = vertical and not anchor
  return win
end

--- Track the shell's folder from OSC 7 (`printf '\e]7;file://host/path\a'`),
--- which fish and many prompts emit after `cd`. Event-driven, no polling.
---@param buf integer
local function track_cwd(buf)
  vim.api.nvim_create_autocmd("TermRequest", {
    buffer = buf,
    callback = function(args)
      local seq = type(args.data) == "table" and args.data.sequence or args.data
      local path = type(seq) == "string" and seq:match("^\27%]7;file://[^/]*(/[^\a\27]*)")
      if path then
        vim.b[buf].wraith_term_cwd = vim.uri_decode(path)
        vim.cmd.redrawstatus({ bang = true }) -- the header (winbar)
        -- lualine keeps its last rendered text; ask it to rebuild.
        require("wraithvim.ui.statusline").request_refresh()
      end
    end,
  })
end

--- Configure a fresh terminal buffer and start the shell in it.
---@param buf integer
local function start_shell(buf)
  local cmd = M.shell_cmd()
  local cwd = vim.fn.getcwd()
  vim.api.nvim_buf_call(buf, function()
    vim.fn.jobstart(cmd, { term = true, cwd = cwd })
  end)
  vim.b[buf].wraith_term_shell = vim.fs.basename(cmd[1] or "shell")
  vim.b[buf].wraith_term_cwd = cwd
  vim.bo[buf].buflisted = false
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].filetype = M.filetype
  track_cwd(buf)

  -- In terminal-normal mode (after Esc Esc or scrolling) a plain click goes
  -- back to typing. Clicks on separators/headers and drag-selections do not.
  vim.keymap.set("n", "<LeftRelease>", function()
    local pos = vim.fn.getmousepos()
    if pos.winid == vim.api.nvim_get_current_win() and pos.line > 0 and pos.column > 0 then
      vim.cmd.startinsert()
    end
  end, { buffer = buf, desc = "Click to type in the terminal" })

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
  wo.foldcolumn = "0"
  if settings().winbar and vim.api.nvim_win_get_config(win).relative == "" then
    wo.winbar = "%{%v:lua.require'wraithvim.features.terminal'.winbar()%}"
  end
end

--- Header text for the terminal window being drawn. Evaluated by Neovim on
--- redraw; only reads buffer variables.
---@return string
function M.winbar()
  local win = vim.g.statusline_winid or vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  local ic = require("wraithvim.ui.icons").get()
  local nerd = require("wraithvim.core.config").get().ui.icons.nerd_font
  local function esc(s)
    return (tostring(s):gsub("%%", "%%%%"))
  end
  local shell = vim.b[buf].wraith_term_shell or "shell"
  local cwd = vim.fn.fnamemodify(vim.b[buf].wraith_term_cwd or vim.fn.getcwd(), ":~")
  local function button(fn, label)
    return ("%%@v:lua.require'wraithvim.features.terminal'.%s@ %s %%X"):format(fn, label)
  end
  local b = nerd and { new = ic.term_new .. " New", hide = ic.term_hide .. " Hide", kill = ic.term_kill .. " Kill" }
    or { new = "[+] New", hide = "[_] Hide", kill = "[x] Kill" }
  return table.concat({
    "%#WraithTermTitle# ",
    nerd and (ic.terminal .. " ") or "",
    "TERMINAL %*",
    "%#WraithTermInfo# ",
    esc(shell),
    "  ",
    nerd and (ic.folder.open .. " ") or "",
    "%<",
    esc(cwd),
    " %*%=",
    "%#WraithTermButton#",
    button("on_new", b.new),
    buf == M.panel.buf and button("on_hide", b.hide) or "",
    button("on_kill", b.kill),
    "%*",
  })
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

--- Whether `win` is the only window in its own tab page (which need not be
--- the current one).
---@param win integer
---@return boolean
local function alone_in_tab(win)
  return #vim.api.nvim_tabpage_list_wins(vim.api.nvim_win_get_tabpage(win)) == 1
end

--- Hide the panel terminal window; the shell keeps running.
function M.hide()
  local p = M.panel
  if p.win and vim.api.nvim_win_is_valid(p.win) then
    if alone_in_tab(p.win) then
      vim.api.nvim_win_call(p.win, vim.cmd.enew)
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

--- Another terminal next to the panel (VS Code's "+"), or the panel itself
--- when it is not visible.
---@return integer buf
function M.new()
  local p = M.panel
  if not (p.win and vim.api.nvim_win_is_valid(p.win)) then
    M.open()
    return M.panel.buf --[[@as integer]]
  end
  if vim.api.nvim_win_get_config(p.win).relative ~= "" then
    -- A floating panel cannot be split; open the new terminal at the bottom.
    M.hide()
    return M.split()
  end
  local buf = vim.api.nvim_create_buf(false, true)
  local win = open_window(buf, "right", p.win)
  style_window(win)
  start_shell(buf)
  vim.cmd.startinsert()
  return buf
end

--- Stop the shell of a terminal buffer; its buffer and window go away with it.
---@param buf integer
function M.kill(buf)
  if buf == M.panel.buf then
    M.close()
    return
  end
  local job = vim.b[buf].terminal_job_id
  if job then
    pcall(vim.fn.jobstop, job)
  end
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if not alone_in_tab(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end

--- Stop the panel terminal's shell and remove its buffer.
function M.close()
  local p = M.panel
  if p.buf and vim.api.nvim_buf_is_valid(p.buf) then
    local job = vim.b[p.buf].terminal_job_id
    if job then
      pcall(vim.fn.jobstop, job)
    end
    if p.win and vim.api.nvim_win_is_valid(p.win) and not alone_in_tab(p.win) then
      vim.api.nvim_win_close(p.win, true)
    end
    if vim.api.nvim_buf_is_valid(p.buf) then
      vim.api.nvim_buf_delete(p.buf, { force = true })
    end
  end
  M.panel = { buf = nil, win = nil }
end

-- Header button handlers (called through %@v:lua...@ click labels).

--- Buffer of the window whose header was clicked.
---@return integer
local function clicked_buf()
  local win = vim.fn.getmousepos().winid
  if win == 0 or not vim.api.nvim_win_is_valid(win) then
    win = vim.api.nvim_get_current_win()
  end
  return vim.api.nvim_win_get_buf(win)
end

function M.on_new()
  M.new()
end

function M.on_hide()
  M.hide()
end

function M.on_kill()
  M.kill(clicked_buf())
end

return M
