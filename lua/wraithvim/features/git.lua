-- Git workflow helpers.
--
-- Every git invocation goes through `M.git()` which passes an argument list to
-- vim.system (no shell), so filenames with spaces or metacharacters are safe.
-- Porcelain UIs are delegated to fugitive (status/commit/push/pull) and
-- diffview (diffs/history).

local utils = require("wraithvim.core.utils")

local M = {}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Git" })
end

--- Repository root for a path (pure filesystem lookup, no process).
---@param path? string file or directory; defaults to current buffer / cwd
---@return string?
function M.root(path)
  path = path or vim.api.nvim_buf_get_name(0)
  if path == "" or not vim.uv.fs_stat(path) then
    path = vim.fn.getcwd()
  end
  return vim.fs.root(path, ".git")
end

--- Run git synchronously in `cwd`.
---@param args string[]
---@param cwd string
---@return vim.SystemCompleted
function M.git(args, cwd)
  -- Paths are always exact file names: without this, `[id].tsx` is a glob that
  -- also matches `i.tsx` and `d.tsx`, so `git rm` would delete those too.
  local cmd = { "git", "-C", cwd, "--literal-pathspecs" }
  vim.list_extend(cmd, args)
  return utils.run(cmd)
end

--- Current buffer's file as (absolute path, repo root, path relative to root).
---@return string? abs, string? root, string? rel
function M.current_file()
  local abs = vim.api.nvim_buf_get_name(0)
  if abs == "" or vim.bo.buftype ~= "" then
    notify("Current buffer is not a file.", vim.log.levels.WARN)
    return nil
  end
  abs = vim.fs.normalize(vim.fn.fnamemodify(abs, ":p"))
  -- Not M.root(): a new file that is not on disk yet must still resolve to its
  -- own repository, not the one the cwd happens to be in.
  local root = vim.fs.root(abs, ".git")
  if not root then
    notify("File is not inside a Git repository.", vim.log.levels.WARN)
    return nil
  end
  root = vim.fs.normalize(vim.uv.fs_realpath(root) or root)
  local real = vim.uv.fs_realpath(abs) or abs
  local rel = vim.fs.relpath(root, real) or vim.fs.relpath(root, abs)
  return abs, root, rel
end

---@return string?
local function require_repo()
  local root = M.root()
  if not root then
    notify("Not inside a Git repository.", vim.log.levels.WARN)
  end
  return root
end

local function refresh_signs()
  if package.loaded["gitsigns"] then
    pcall(require("gitsigns").refresh)
  end
end

--- Stage the current file (`git add -- <file>`).
---@return boolean
function M.stage_file()
  local abs, root, rel = M.current_file()
  if not abs then
    return false
  end
  if vim.bo.modified then
    vim.cmd.write()
  end
  local r = M.git({ "add", "--", rel }, root)
  if r.code ~= 0 then
    notify("git add failed: " .. utils.trim(r.stderr), vim.log.levels.ERROR)
    return false
  end
  refresh_signs()
  notify("Staged " .. rel)
  return true
end

--- Unstage the current file, keeping working tree changes.
---@return boolean
function M.unstage_file()
  local abs, root, rel = M.current_file()
  if not abs then
    return false
  end
  local r = M.git({ "restore", "--staged", "--", rel }, root)
  if r.code ~= 0 then
    -- Repositories without commits have no HEAD to restore from.
    r = M.git({ "rm", "--cached", "--quiet", "--", rel }, root)
  end
  if r.code ~= 0 then
    notify("Unstage failed: " .. utils.trim(r.stderr), vim.log.levels.ERROR)
    return false
  end
  refresh_signs()
  notify("Unstaged " .. rel)
  return true
end

function M.status()
  if require_repo() then
    vim.cmd("Git")
  end
end

---@param amend? boolean
function M.commit(amend)
  if require_repo() then
    vim.cmd(amend and "Git commit --amend" or "Git commit")
  end
end

function M.push()
  if require_repo() then
    vim.cmd("Git push")
  end
end

function M.pull()
  if require_repo() then
    vim.cmd("Git pull")
  end
end

function M.branches()
  if require_repo() then
    require("telescope.builtin").git_branches()
  end
end

--- Commit graph (vim-flog) of the current branch, or of every branch with
--- `all`. Keys are listed in the graph's header (wraithvim.features.graph).
---@param all? boolean
function M.graph(all)
  if require_repo() then
    vim.cmd(all and "Flog -all" or "Flog")
  end
end

function M.diff()
  if require_repo() then
    vim.cmd("DiffviewOpen")
  end
end

function M.diff_close()
  vim.cmd("DiffviewClose")
end

function M.history()
  if require_repo() then
    vim.cmd("DiffviewFileHistory")
  end
end

function M.file_history()
  if M.current_file() then
    vim.cmd("DiffviewFileHistory %")
  end
end

---@return table gitsigns setup options
function M.gitsigns_opts()
  local ic = require("wraithvim.ui.icons").get()
  local s = ic.signs
  return {
    signs = {
      add = { text = s.add },
      change = { text = s.change },
      delete = { text = s.delete },
      topdelete = { text = s.topdelete },
      changedelete = { text = s.changedelete },
      untracked = { text = s.untracked },
    },
    signs_staged = {
      add = { text = s.add },
      change = { text = s.change },
      delete = { text = s.delete },
      topdelete = { text = s.topdelete },
      changedelete = { text = s.changedelete },
    },
    attach_to_untracked = true,
    -- Event-driven (inotify) watcher on .git for external changes; no polling loop.
    watch_gitdir = { follow_files = true },
    update_debounce = 200,
    max_file_length = 40000,
    -- Who changed the current line, when, and why, at its end (like GitLens).
    -- Updated on cursor moves only; nothing runs while idle.
    current_line_blame = require("wraithvim.core.config").get().ui.line_blame,
    current_line_blame_opts = { virt_text_pos = "eol", delay = 400 },
    current_line_blame_formatter = "     <author>, <author_time:%R> • <summary>",
    current_line_blame_formatter_nc = "     You • Uncommitted changes",
    preview_config = { border = require("wraithvim.core.config").get().ui.border },
  }
end

return M
