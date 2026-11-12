-- Side panel and moving between panels.
--
-- The side panel is one column on the right (or left) of the editor, like
-- VS Code's secondary side bar. It shows one view at a time:
--   graph     the commit graph (vim-flog)
--   changes   the changed files (neo-tree's git_status; Enter opens, d diffs)
--   terminal  the panel terminal, moved to the side (the shell keeps running)
--
-- Alt+0/1/2/3 put the cursor in the explorer, the code, the side panel or the
-- terminal from any mode, including from inside a terminal.

local M = {}

M.views = { "graph", "changes", "terminal" }

--- Session state: where the side panel is and which view it showed last.
---@type { position: string?, last: string? }
M.state = {}

---@type integer? last window that showed code (see config/autocmds.lua)
M.last_code_win = nil

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Side panel" })
end

---@return table ui.side_panel
local function settings()
  return require("wraithvim.core.config").get().ui.side_panel
end

---@return "left"|"right"
function M.position()
  local pos = M.state.position or settings().position
  return pos == "left" and "left" or "right"
end

local function terminal()
  return require("wraithvim.features.terminal")
end

--- Whether `win` shows `view` (any view when nil) as the side panel.
---@param win integer
---@param view? string
---@return string? view
local function side_view(win, view)
  if vim.api.nvim_win_get_config(win).relative ~= "" then
    return nil
  end
  local buf = vim.api.nvim_win_get_buf(win)
  local found
  if vim.w[win].wraith_side == "graph" and vim.bo[buf].filetype == "floggraph" then
    found = "graph"
  elseif vim.b[buf].neo_tree_source == "git_status" then
    found = "changes"
  elseif
    buf == terminal().panel.buf and (terminal().panel.position == "left" or terminal().panel.position == "right")
  then
    found = "terminal"
  end
  if found and (view == nil or view == found) then
    return found
  end
end

--- The side panel shown in the current tab, if any.
---@return { view: string, win: integer }?
function M.visible()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local view = side_view(win)
    if view then
      return { view = view, win = win }
    end
  end
end

---@param win integer
---@return boolean
function M.is_code_win(win)
  if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_win_get_config(win).relative ~= "" then
    return false
  end
  local buf = vim.api.nvim_win_get_buf(win)
  local bt = vim.bo[buf].buftype
  return bt == "" or bt == "acwrite" or vim.bo[buf].filetype == require("wraithvim.ui.dashboard").filetype
end

--- Whether a git view can open here: inside a repository, with `plugin`.
---@param plugin string
---@param what string
---@return boolean
local function can_show(plugin, what)
  if not require("wraithvim.core.plugin_manager").has(plugin) then
    notify(("%s needs %s, which is turned off or not installed."):format(what, plugin), vim.log.levels.WARN)
    return false
  end
  if not require("wraithvim.features.git").root() then
    notify("Not inside a Git repository.", vim.log.levels.WARN)
    return false
  end
  return true
end

-- Each opener shows its view at `position` and returns the window, or nil
-- when it could not (no repository, ...). Changes are drawn asynchronously by
-- neo-tree, so that window is looked up when needed instead.
local openers = {
  graph = function(position)
    if not can_show("vim-flog", "The Git graph") then
      return nil
    end
    vim.cmd((position == "left" and "topleft" or "botright") .. " vertical Flogsplit")
    local win = vim.api.nvim_get_current_win()
    vim.w[win].wraith_side = "graph"
    return win
  end,
  changes = function(position)
    if not can_show("neo-tree.nvim", "The changed files view") then
      return nil
    end
    -- The header shares the graph's colors (kept across colorscheme changes).
    local graph = require("wraithvim.features.graph")
    graph.used = true
    graph.highlights()
    require("neo-tree.command").execute({
      action = "focus",
      source = "git_status",
      position = position,
      dir = vim.fn.getcwd(),
    })
    return vim.bo.filetype == "neo-tree" and vim.api.nvim_get_current_win() or nil
  end,
  terminal = function(position)
    terminal().open(position)
    return terminal().panel.win
  end,
}

---@param view string
---@param win integer
local function close_view(view, win)
  if view == "changes" then
    require("neo-tree.command").execute({ action = "close", source = "git_status" })
  elseif view == "terminal" then
    terminal().hide()
  elseif #vim.api.nvim_tabpage_list_wins(0) > 1 then
    local buf = vim.api.nvim_win_get_buf(win)
    pcall(vim.api.nvim_win_close, win, true)
    if vim.api.nvim_buf_is_valid(buf) and #vim.fn.win_findbuf(buf) == 0 then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end
end

--- Show `view` in the side panel (replacing the view there) and focus it.
---@param view? string graph | changes | terminal (default: the last one)
---@param position? string left | right (default: where the panel is)
function M.open(view, position)
  view = view or M.state.last or "changes"
  if not openers[view] then
    notify(("Unknown view %q (use %s)."):format(view, table.concat(M.views, ", ")), vim.log.levels.WARN)
    return
  end
  position = position == "left" and "left" or position == "right" and "right" or M.position()
  local current = M.visible()
  if current and current.view == view and position == M.position() then
    vim.api.nvim_set_current_win(current.win)
    return
  end
  if current then
    close_view(current.view, current.win)
  end
  M.state.position = position
  M.state.last = view
  local win = openers[view](position)
  if win and vim.api.nvim_win_is_valid(win) then
    -- Leave the code at least half of a small screen.
    vim.api.nvim_win_set_width(win, math.min(settings().width, math.floor(vim.o.columns * 0.45)))
  end
end

--- Hide the side panel. The terminal keeps running; the graph is reloaded
--- when shown again.
function M.close()
  local current = M.visible()
  if current then
    close_view(current.view, current.win)
  end
end

--- Hide the side panel, or bring back the view it showed last.
function M.toggle()
  if M.visible() then
    M.close()
  else
    M.open()
  end
end

--- Move the side panel to the other side of the editor.
function M.move()
  local other = M.position() == "right" and "left" or "right"
  local current = M.visible()
  if current then
    M.open(current.view, other)
  else
    M.state.position = other
    notify("The side panel opens on the " .. other .. " now.")
  end
end

--- Side-by-side diff of one changed file (Diffview, in its own tab).
---@param path string
function M.diff_file(path)
  local root = require("wraithvim.features.git").root(path)
  local rel = root and vim.fs.relpath(root, path) or path
  vim.cmd("DiffviewOpen -- " .. vim.fn.fnameescape(rel))
end

--- Header of the changes view: what the keys do.
---@return string winbar
function M.changes_header()
  local keys = { { "Enter", "open" }, { "d", "diff" }, { "ga", "stage" }, { "gu", "unstage" }, { "gc", "commit" } }
  local parts = { "%#WraithGraphTitle#  Changes %*" }
  for _, k in ipairs(keys) do
    parts[#parts + 1] = ("%%#WraithGraphKey# %s %%#WraithGraphHint#%s%%*"):format(k[1], k[2])
  end
  return table.concat(parts, " ") .. "%<"
end

-- Moving between panels -------------------------------------------------------

---@param win integer
local function go(win)
  -- Insert mode would carry over into the panel; terminal mode ends by itself.
  if vim.api.nvim_get_mode().mode:sub(1, 1) == "i" then
    vim.cmd.stopinsert()
  end
  vim.api.nvim_set_current_win(win)
end

--- Put the cursor in the code: the window last used for code, else any.
function M.focus_code()
  local last = M.last_code_win
  if last and M.is_code_win(last) and vim.api.nvim_win_get_tabpage(last) == vim.api.nvim_get_current_tabpage() then
    return go(last)
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if M.is_code_win(win) then
      return go(win)
    end
  end
  notify("No code window in this tab.", vim.log.levels.WARN)
end

--- Put the cursor in the side panel, opening it when hidden.
function M.focus_side()
  local current = M.visible()
  if current then
    go(current.win)
  else
    M.open()
  end
end

--- Put the cursor in the terminal panel (wherever it is), opening it when hidden.
function M.focus_terminal()
  local p = terminal().panel
  if p.win and vim.api.nvim_win_is_valid(p.win) and vim.api.nvim_win_get_buf(p.win) == p.buf then
    go(p.win) -- entering a terminal window starts typing (config/autocmds.lua)
  else
    terminal().open()
  end
end

--- Put the cursor in the file explorer, opening it when hidden.
function M.focus_explorer()
  if vim.api.nvim_get_mode().mode:sub(1, 1) == "i" then
    vim.cmd.stopinsert()
  end
  require("wraithvim.features.explorer").focus()
end

return M
