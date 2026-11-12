-- Creating files and folders the VS Code way: header buttons and a
-- right-click menu in the explorer, `a` / `A` on a tree item, and `Space n`
-- anywhere. The prompt starts with the target folder ("src/components/"), so
-- you see where the file goes and only type its name. Nested paths
-- ("api/v2/routes.lua") create the missing folders. A new file opens right
-- away. Existing files are opened, never overwritten.

local M = {}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Files" })
end

--- Path shown in prompts: relative to the working directory, with a trailing
--- slash, or "" for the working directory itself.
---@param dir string
---@return string
function M.display_dir(dir)
  local cwd = vim.fs.normalize(vim.fn.getcwd())
  dir = vim.fs.normalize(dir)
  if dir == cwd then
    return ""
  end
  local rel = vim.fs.relpath(cwd, dir)
  return (rel or vim.fn.fnamemodify(dir, ":~")) .. "/"
end

--- Create a file or (with a trailing "/" or `folder`) a folder.
---@param input string path typed by the user, relative to the working directory
---@param folder? boolean
---@return string? path, string? err, boolean? existed
function M.create(input, folder)
  input = vim.trim(input or "")
  if input == "" or input:match("^/*$") then
    return nil, "empty name"
  end
  folder = folder or input:sub(-1) == "/"
  -- Only "~" is expanded: "%" or "*" in a name are literal characters.
  input = input:gsub("^~/", vim.env.HOME .. "/")
  local path = vim.fs.normalize(vim.fn.fnamemodify(input, ":p"))
  path = path:gsub("/+$", "")
  local stat = vim.uv.fs_stat(path)
  if stat then
    local is_dir = stat.type == "directory"
    if is_dir ~= folder then
      return nil, ("%s already exists as a %s"):format(vim.fn.fnamemodify(path, ":~:."), is_dir and "folder" or "file")
    end
    return path, nil, true
  end
  local parent = folder and path or vim.fs.dirname(path)
  if vim.fn.mkdir(parent, "p") == 0 and not vim.uv.fs_stat(parent) then
    return nil, "cannot create folder " .. parent
  end
  if not folder then
    -- "wx": fail instead of truncating if the file appeared meanwhile.
    local fd, err = vim.uv.fs_open(path, "wx", 420) -- 0644
    if not fd then
      return nil, err
    end
    vim.uv.fs_close(fd)
  end
  return path
end

--- Window to open files in: the last editor window, never the explorer.
---@return integer
local function editor_win()
  local function usable(win)
    if not win or win == 0 or not vim.api.nvim_win_is_valid(win) then
      return false
    end
    local buf = vim.api.nvim_win_get_buf(win)
    return vim.api.nvim_win_get_config(win).relative == ""
      and vim.bo[buf].buftype == ""
      and vim.bo[buf].filetype ~= "neo-tree"
  end
  local cur = vim.api.nvim_get_current_win()
  if usable(cur) then
    return cur
  end
  local prev = vim.fn.win_getid(vim.fn.winnr("#"))
  if usable(prev) then
    return prev
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if usable(win) then
      return win
    end
  end
  -- Only the explorer (and maybe a terminal) is open: make room beside it.
  vim.cmd("rightbelow vnew")
  return vim.api.nvim_get_current_win()
end

local function refresh_tree(reveal)
  if not package.loaded["neo-tree"] then
    return
  end
  pcall(function()
    require("neo-tree.sources.manager").refresh("filesystem")
    if reveal then
      require("wraithvim.features.explorer").show_path(reveal)
    end
  end)
end

---@param dir? string folder to create in (default: current file's folder)
---@param folder? boolean
local function prompt(dir, folder)
  if not dir then
    local name = vim.api.nvim_buf_get_name(0)
    dir = (name ~= "" and vim.bo.buftype == "") and vim.fs.dirname(name) or vim.fn.getcwd()
  end
  local label = folder and "New folder: " or "New file (end with / for a folder): "
  vim.ui.input({ prompt = label, default = M.display_dir(dir), completion = "dir" }, function(input)
    if not input then
      return
    end
    local path, err, existed = M.create(input, folder)
    if not path then
      if err ~= "empty name" then
        notify(err, vim.log.levels.ERROR)
      end
      return
    end
    local is_dir = vim.fn.isdirectory(path) == 1
    if is_dir then
      notify((existed and "Folder already exists: " or "Created ") .. vim.fn.fnamemodify(path, ":~:."))
      refresh_tree(path)
    else
      refresh_tree()
      vim.api.nvim_set_current_win(editor_win())
      vim.cmd.edit(vim.fn.fnameescape(path))
    end
  end)
end

---@param dir? string
function M.new_file(dir)
  prompt(dir, false)
end

---@param dir? string
function M.new_folder(dir)
  prompt(dir, true)
end

-- Explorer integration -------------------------------------------------------

---@return table? state, integer? win
local function tree()
  if not package.loaded["neo-tree"] then
    return nil
  end
  local state = require("neo-tree.sources.manager").get_state("filesystem")
  if state and state.winid and vim.api.nvim_win_is_valid(state.winid) and state.tree then
    return state, state.winid
  end
end

--- Folder of the tree item under the cursor: the item itself when it is a
--- folder, otherwise the folder containing it.
---@param state table neo-tree state
---@param line? integer
---@return string
function M.folder_at(state, line)
  local node
  if state.tree and state.winid and vim.api.nvim_win_is_valid(state.winid) then
    line = line or vim.api.nvim_win_get_cursor(state.winid)[1]
    node = state.tree:get_node(line)
  end
  if not node then
    return state.path or vim.fn.getcwd()
  end
  if node.type == "directory" then
    return node.path
  end
  return vim.fs.dirname(node.path)
end

--- Run a neo-tree filesystem command in the tree window.
---@param name string
local function tree_command(name)
  local state, win = tree()
  if state then
    vim.api.nvim_win_call(win, function()
      require("neo-tree.sources.filesystem.commands")[name](state)
    end)
  end
end

local actions = {
  new_file = function(state)
    M.new_file(M.folder_at(state))
  end,
  new_folder = function(state)
    M.new_folder(M.folder_at(state))
  end,
  open_vsplit = function()
    tree_command("open_vsplit")
  end,
  rename = function()
    tree_command("rename")
  end,
  delete = function()
    tree_command("delete")
  end,
  copy_path = function(state)
    local node = state.tree:get_node(vim.api.nvim_win_get_cursor(state.winid)[1])
    if node then
      local rel = vim.fn.fnamemodify(node.path, ":.")
      vim.fn.setreg("+", rel)
      vim.fn.setreg('"', rel)
      notify("Copied " .. rel)
    end
  end,
  refresh = function()
    tree_command("refresh")
  end,
  collapse = function()
    tree_command("close_all_nodes")
  end,
}

--- Run an explorer action by name (header buttons, context menu, tests).
---@param name string
function M.action(name)
  local state = tree()
  if not state then
    -- No explorer: create relative to the current file.
    if name == "new_file" then
      M.new_file()
    elseif name == "new_folder" then
      M.new_folder()
    end
    return
  end
  actions[name](state)
end

-- Header (winbar of the explorer window).
function M.on_new_file()
  M.action("new_file")
end
function M.on_new_folder()
  M.action("new_folder")
end
function M.on_refresh()
  M.action("refresh")
end
function M.on_collapse()
  M.action("collapse")
end

---@return string winbar
function M.header()
  local nerd = require("wraithvim.core.config").get().ui.icons.nerd_font
  local function button(fn, label)
    return ("%%@v:lua.require'wraithvim.features.files'.%s@%s%%X"):format(fn, label)
  end
  -- md-file_plus, md-folder_plus, md-reload, md-arrow_collapse
  local l = nerd
      and { file = " \u{f0752} File ", folder = " \u{f0257} Folder ", refresh = " \u{f0453} ", collapse = " \u{f0615} " }
    or { file = " +File ", folder = " +Folder ", refresh = " R ", collapse = " - " }
  return table.concat({
    "%#WraithTreeButton#",
    button("on_new_file", l.file),
    " ",
    button("on_new_folder", l.folder),
    "%*%=%<%#WraithTreeIcon#",
    button("on_refresh", l.refresh),
    button("on_collapse", l.collapse),
    "%*",
  })
end

local menu_items = {
  { "New File", "new_file" },
  { "New Folder", "new_folder" },
  { "-1-" },
  { "Open to the Side", "open_vsplit" },
  { "-2-" },
  { "Rename", "rename" },
  { "Delete", "delete" },
  { "Copy Path", "copy_path" },
  { "-3-" },
  { "Refresh", "refresh" },
  { "Collapse All", "collapse" },
}

local menu_defined = false
local function define_menu()
  if menu_defined then
    return
  end
  menu_defined = true
  for i, item in ipairs(menu_items) do
    local name = item[1]:gsub(" ", "\\ ")
    if item[2] then
      vim.cmd(
        ("anoremenu <silent> %d ]WraithTree.%s <Cmd>lua require('wraithvim.features.files').action(%q)<CR>"):format(
          i * 10,
          name,
          item[2]
        )
      )
    else
      vim.cmd(("anoremenu %d ]WraithTree.%s <Nop>"):format(i * 10, name))
    end
  end
end

--- Right click: on the explorer, select the clicked item and show the file
--- menu; anywhere else, Neovim's own right-click behaviour.
---@return string keys for the expr mapping
function M.right_click()
  local pos = vim.fn.getmousepos()
  local win = pos.winid
  if win == 0 or not vim.api.nvim_win_is_valid(win) then
    return "<RightMouse>"
  end
  if vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "neo-tree" or pos.line == 0 then
    return "<RightMouse>"
  end
  vim.schedule(function()
    if not vim.api.nvim_win_is_valid(win) then
      return
    end
    vim.api.nvim_set_current_win(win)
    local last = vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(win))
    pcall(vim.api.nvim_win_set_cursor, win, { math.min(pos.line, last), 0 })
    define_menu()
    vim.cmd("popup ]WraithTree")
  end)
  return ""
end

function M.setup()
  vim.keymap.set("n", "<RightMouse>", M.right_click, { expr = true, desc = "File menu in the explorer" })
end

return M
