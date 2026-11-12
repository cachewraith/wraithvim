-- Reload buffers as soon as their file changes on disk (an AI CLI, a
-- formatter, `git checkout`, …).
--
-- One OS file watcher (inotify on Linux, via vim.uv.new_fs_event) per
-- directory that contains a loaded file buffer. Watching the directory rather
-- than the file also catches tools that write a temp file and rename it over
-- the original. Events are debounced and handed to `:checktime`, so Neovim's
-- own logic decides whether the buffer really changed. Nothing runs while no
-- file changes: no polling, no timers.
--
-- Buffers with unsaved edits are never reloaded automatically; the user is
-- told and can compare with :DiffDisk. The explorer has its own watcher
-- (ui.explorer.watch).

local M = {}

local DEBOUNCE_MS = 120

---@type table<string, { handle: uv.uv_fs_event_t, bufs: table<integer, string> }>
local dirs = {}
---@type table<integer, string> buffer -> watched directory
local buf_dir = {}
local pending = {}
local reloaded = {}
local notify_scheduled = false

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Files" })
end

--- Number of active directory watchers (tests, health).
---@return integer
function M.count()
  local n = 0
  for _ in pairs(dirs) do
    n = n + 1
  end
  return n
end

---@param buf integer
---@return string? path absolute, resolved path of a real file buffer
local function file_of(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
    return nil
  end
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" or name:match("^%a[%w+.-]*://") then
    return nil
  end
  return vim.uv.fs_realpath(name) or vim.fs.normalize(vim.fn.fnamemodify(name, ":p"))
end

---@param buf integer
local function schedule_check(buf)
  if pending[buf] then
    return
  end
  pending[buf] = true
  vim.defer_fn(function()
    pending[buf] = nil
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
      -- :checktime compares the file's mtime/size with what the buffer was
      -- loaded from; our own :write updates those, so saving never loops.
      pcall(vim.cmd.checktime, buf)
    end
  end, DEBOUNCE_MS)
end

---@param dir string
---@param filename string?
local function on_event(dir, filename)
  local entry = dirs[dir]
  if not entry then
    return
  end
  for buf, base in pairs(entry.bufs) do
    if filename == nil or filename == base then
      schedule_check(buf)
    end
  end
end

---@param buf integer
function M.unwatch(buf)
  local dir = buf_dir[buf]
  buf_dir[buf] = nil
  local entry = dir and dirs[dir]
  if not entry then
    return
  end
  entry.bufs[buf] = nil
  if next(entry.bufs) == nil then
    entry.handle:stop()
    if not entry.handle:is_closing() then
      entry.handle:close()
    end
    dirs[dir] = nil
  end
end

---@param buf integer
function M.watch(buf)
  local path = file_of(buf)
  if not path then
    M.unwatch(buf)
    return
  end
  local dir, base = vim.fs.dirname(path), vim.fs.basename(path)
  if buf_dir[buf] == dir and dirs[dir] and dirs[dir].bufs[buf] == base then
    return
  end
  M.unwatch(buf)
  if not vim.uv.fs_stat(dir) then
    return
  end
  local entry = dirs[dir]
  if not entry then
    local handle = vim.uv.new_fs_event()
    if not handle then
      return
    end
    local ok = handle:start(dir, {}, function(err, filename)
      if not err then
        vim.schedule(function()
          on_event(dir, filename)
        end)
      end
    end)
    if ok ~= 0 then
      handle:close()
      return
    end
    entry = { handle = handle, bufs = {} }
    dirs[dir] = entry
  end
  entry.bufs[buf] = base
  buf_dir[buf] = dir
end

--- Coalesce "reloaded" notices so a tool changing ten files shows one message.
local function report_reloaded()
  if notify_scheduled then
    return
  end
  notify_scheduled = true
  vim.defer_fn(function()
    notify_scheduled = false
    local names = vim.tbl_keys(reloaded)
    reloaded = {}
    if #names == 0 then
      return
    end
    table.sort(names)
    if #names == 1 then
      notify(names[1] .. " reloaded (changed on disk)")
    else
      notify(("Reloaded %d files changed on disk: %s"):format(#names, table.concat(names, ", ")))
    end
  end, 300)
end

--- Show the buffer and its on-disk version side by side.
---@param buf? integer
function M.diff_disk(buf)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  local path = vim.api.nvim_buf_get_name(buf)
  if path == "" or not vim.uv.fs_stat(path) then
    notify("This buffer has no file on disk to compare with.", vim.log.levels.WARN)
    return
  end
  local ft = vim.bo[buf].filetype
  vim.cmd("diffthis")
  vim.cmd("vertical rightbelow new")
  local disk = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(disk, 0, -1, false, vim.fn.readfile(path))
  vim.bo[disk].buftype = "nofile"
  vim.bo[disk].bufhidden = "wipe"
  vim.bo[disk].modifiable = false
  vim.bo[disk].filetype = ft
  pcall(vim.api.nvim_buf_set_name, disk, "disk://" .. vim.fn.fnamemodify(path, ":~:."))
  vim.wo.winbar = "%#DiffChange# ON DISK %* use :e! to load it, :w to keep yours"
  vim.cmd("diffthis")
end

---@param cfg table effective configuration
function M.setup(cfg)
  if not cfg.options.auto_reload then
    return
  end
  vim.o.autoread = true
  local group = require("wraithvim.core.utils").augroup("autoreload")

  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "BufFilePost" }, {
    group = group,
    callback = function(args)
      M.watch(args.buf)
    end,
  })
  vim.api.nvim_create_autocmd({ "BufUnload", "BufDelete", "BufWipeout" }, {
    group = group,
    callback = function(args)
      M.unwatch(args.buf)
      pending[args.buf] = nil
    end,
  })

  -- Only reached when the buffer has unsaved edits or the file was deleted
  -- (unmodified buffers are reloaded by 'autoread' without this event).
  vim.api.nvim_create_autocmd("FileChangedShell", {
    group = group,
    callback = function(args)
      local name = vim.fn.fnamemodify(args.file, ":~:.")
      local reason = vim.v.fcs_reason
      if reason == "deleted" then
        vim.v.fcs_choice = ""
        notify(name .. " was deleted on disk. Your buffer is kept; :w writes it back.", vim.log.levels.WARN)
      elseif vim.bo[args.buf].modified then
        vim.v.fcs_choice = ""
        notify(
          ("%s changed on disk, but you have unsaved edits — kept yours.\n:DiffDisk compares, :e! loads the disk version, :w keeps yours."):format(
            name
          ),
          vim.log.levels.WARN
        )
      else
        vim.v.fcs_choice = "reload"
      end
    end,
  })
  vim.api.nvim_create_autocmd("FileChangedShellPost", {
    group = group,
    callback = function(args)
      reloaded[vim.fn.fnamemodify(args.file, ":t")] = true
      report_reloaded()
    end,
  })

  -- Buffers loaded before this ran (files given on the command line).
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      M.watch(buf)
    end
  end
end

return M
