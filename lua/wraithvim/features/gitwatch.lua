-- Keep the Git graph and the changed files up to date as things happen: a
-- commit, checkout, stash or fetch from a shell, a file created, deleted or
-- renamed anywhere in the repository (by Neovim, a shell, an AI CLI, …).
--
-- Watching starts when a graph or changes view is open in any tab and stops
-- when the last one closes. It uses OS file events (inotify on Linux, via
-- vim.uv.new_fs_event), never polling:
--   * the Git directory and its refs folders: commits, branches, HEAD, index
--   * every folder holding tracked or not-ignored files: the working tree
-- Linux watches are not recursive, so each folder gets its own (ignored
-- folders such as node_modules or target are skipped). Bursts of events are
-- coalesced into one refresh.

local M = {}

local DEBOUNCE_MS = 150
-- inotify watches are a per-user resource; very large repositories only get
-- the Git directory watched (commits still show up, new files on refocus).
M.max_dirs = 5000

---@type { root: string, git_dirs: string[], handles: table<string, uv.uv_fs_event_t> }?
local watching = nil
local pending = { git = false, tree = false, rescan = false }
local timer = nil

local function stop_handle(handle)
  handle:stop()
  if not handle:is_closing() then
    handle:close()
  end
end

--- Number of folders being watched (tests, health).
---@return integer
function M.count()
  return watching and vim.tbl_count(watching.handles) or 0
end

---@return string? root repository being watched
function M.root()
  return watching and watching.root
end

---@param root string
---@return string? git_dir, string? common_dir
local function git_dirs(root)
  local res = require("wraithvim.features.git").git(
    { "rev-parse", "--path-format=absolute", "--git-dir", "--git-common-dir" },
    root
  )
  local lines = vim.split(vim.trim(res.stdout or ""), "\n", { trimempty = true })
  if res.code ~= 0 or #lines < 2 then
    return nil
  end
  return vim.fs.normalize(lines[1]), vim.fs.normalize(lines[2])
end

--- Folders to watch for a repository: the Git directory, its refs folders
--- (branch names with "/" are subfolders) and the working tree's folders.
---@param root string
---@return { git: string[], tree: string[] }?
function M.folders(root)
  local git_dir, common = git_dirs(root)
  if not git_dir then
    return nil
  end
  local git = { git_dir }
  if common ~= git_dir then
    git[#git + 1] = common
  end
  local refs = common .. "/refs"
  if vim.uv.fs_stat(refs) then
    git[#git + 1] = refs
    for name, kind in vim.fs.dir(refs, { depth = 20 }) do
      if kind == "directory" then
        git[#git + 1] = refs .. "/" .. name
      end
    end
  end

  local git_cmd = require("wraithvim.features.git").git
  local res = git_cmd({ "ls-files", "-z", "-co", "--exclude-standard" }, root)
  if res.code ~= 0 then
    return { git = git, tree = { root } }
  end
  local seen = { [root] = true }
  local tree = { root }
  local function add(rel)
    local dir = rel
    while dir ~= "." and dir ~= "" and not seen[dir] do
      seen[dir] = true
      tree[#tree + 1] = root .. "/" .. dir
      dir = vim.fs.dirname(dir)
    end
  end
  for file in (res.stdout or ""):gmatch("[^%z]+") do
    add(vim.fs.dirname(file))
  end

  -- Git lists files, never empty folders: new folders (a file is often
  -- created in them right after) are found by walking the untracked ones.
  local untracked = git_cmd({ "ls-files", "-z", "-o", "--exclude-standard", "--directory" }, root)
  local candidates = {}
  for entry in (untracked.stdout or ""):gmatch("[^%z]+") do
    if entry:sub(-1) == "/" and #tree + #candidates <= M.max_dirs then
      local dir = entry:sub(1, -2)
      add(dir)
      for name, kind in vim.fs.dir(root .. "/" .. dir, { depth = 50 }) do
        if kind == "directory" then
          candidates[#candidates + 1] = dir .. "/" .. name
        end
      end
    end
  end
  if #candidates > 0 then
    local ignored = {}
    local check = require("wraithvim.core.utils").run(
      { "git", "-C", root, "check-ignore", "-z", "--stdin" },
      { stdin = table.concat(candidates, "\0") }
    )
    for path in (check.stdout or ""):gmatch("[^%z]+") do
      ignored[path] = true
    end
    for _, dir in ipairs(candidates) do
      if not ignored[dir] then
        add(dir)
      end
    end
  end
  return { git = git, tree = tree }
end

--- Whether a graph or changes view is open in any tab.
---@return boolean
function M.wanted()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "floggraph" or vim.b[buf].neo_tree_source == "git_status" then
      return true
    end
  end
  return false
end

--- Redraw what changed: the graph after Git changes, the changed files (and
--- the explorer's colors) after any change.
local function flush()
  local git, rescan = pending.git, pending.rescan
  pending.git, pending.tree, pending.rescan = false, false, false
  if rescan and watching then
    M.start(watching.root, true)
  end
  if package.loaded["neo-tree"] then
    pcall(function()
      require("neo-tree.events").fire_event(require("neo-tree.events").GIT_EVENT)
    end)
  end
  if git then
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == "floggraph" then
        vim.api.nvim_win_call(win, function()
          pcall(vim.fn["flog#floggraph#buf#Update"])
        end)
      end
    end
  end
end

---@param kind "git"|"tree"
---@param dir string
---@param name? string
local function on_event(kind, dir, name)
  if not watching then
    return
  end
  if kind == "git" then
    -- Lock files come and go around every write; the rename onto the real
    -- file is reported under its own name.
    if name and (name:sub(-5) == ".lock" or name == "objects" or name == "logs") then
      return
    end
    -- Staging only changes the changed files; anything else (refs, HEAD,
    -- packed-refs, FETCH_HEAD) may change the graph.
    if name ~= "index" and name ~= "COMMIT_EDITMSG" then
      pending.git = true
    end
    -- A new branch folder (feature/…) needs its own watch.
    if name and not watching.handles[dir .. "/" .. name] then
      local stat = vim.uv.fs_stat(dir .. "/" .. name)
      if stat and stat.type == "directory" and dir:find("/refs", 1, true) then
        pending.rescan = true
      end
    end
  else
    if name == ".git" then
      return
    end
    pending.tree = true
    -- A folder appeared or went away: watch the new set of folders.
    if name then
      local path = dir .. "/" .. name
      local stat = vim.uv.fs_stat(path)
      if (stat and stat.type == "directory") ~= (watching.handles[path] ~= nil) then
        pending.rescan = true
      end
    end
  end
  timer = timer or vim.uv.new_timer()
  timer:stop()
  timer:start(DEBOUNCE_MS, 0, vim.schedule_wrap(flush))
end

---@param kind "git"|"tree"
---@param dir string
---@return uv.uv_fs_event_t?
local function watch(kind, dir)
  local handle = vim.uv.new_fs_event()
  if not handle then
    return nil
  end
  local ok = handle:start(dir, {}, function(err, name)
    if not err then
      vim.schedule(function()
        on_event(kind, dir, name)
      end)
    end
  end)
  if ok ~= 0 then
    stop_handle(handle)
    return nil
  end
  return handle
end

--- Watch the repository at `root`. With `resync`, keep the watches of
--- folders that still exist and add or drop the rest.
---@param root string
---@param resync? boolean
function M.start(root, resync)
  if watching and watching.root == root and not resync then
    return
  end
  if watching and watching.root ~= root then
    M.stop()
  end
  local folders = M.folders(root)
  if not folders then
    M.stop()
    return
  end
  local want = {}
  for _, dir in ipairs(folders.git) do
    want[dir] = "git"
  end
  if #folders.tree <= M.max_dirs then
    for _, dir in ipairs(folders.tree) do
      want[dir] = want[dir] or "tree"
    end
  end
  local handles = watching and watching.handles or {}
  for dir, handle in pairs(handles) do
    if not want[dir] then
      stop_handle(handle)
      handles[dir] = nil
    end
  end
  for dir, kind in pairs(want) do
    if not handles[dir] then
      handles[dir] = watch(kind, dir)
    end
  end
  watching = { root = root, git_dirs = folders.git, handles = handles }
end

function M.stop()
  if not watching then
    return
  end
  for _, handle in pairs(watching.handles) do
    stop_handle(handle)
  end
  watching = nil
  if timer then
    timer:stop()
  end
  pending.git, pending.tree, pending.rescan = false, false, false
end

--- Start or stop watching to match the views open right now.
function M.sync()
  local root = M.wanted() and require("wraithvim.features.git").root(vim.fn.getcwd())
  if root then
    M.start(vim.fs.normalize(root))
  else
    M.stop()
  end
end

---@param cfg table effective configuration
function M.setup(cfg)
  if not cfg.ui.side_panel.watch then
    return
  end
  local group = require("wraithvim.core.utils").augroup("gitwatch")
  local scheduled = false
  -- The views open asynchronously (neo-tree) or from :Flog: look once the
  -- event loop settles.
  vim.api.nvim_create_autocmd({ "BufWinEnter", "WinClosed", "TabClosed", "DirChanged", "FileType" }, {
    group = group,
    callback = function()
      if scheduled then
        return
      end
      scheduled = true
      vim.schedule(function()
        scheduled = false
        M.sync()
      end)
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", { group = group, callback = M.stop })
end

return M
