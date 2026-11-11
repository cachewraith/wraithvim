-- Temporary Git repositories for tests.

local env = require("tests.helpers.env")

local M = {}

---@param dir string
---@return vim.SystemCompleted
function M.git(dir, ...)
  return vim.system({ "git", "-C", dir, ... }, { text = true }):wait()
end

---@return string dir
function M.repo()
  local dir = env.tmpdir("repo")
  M.git(dir, "init", "-q", "-b", "main")
  M.git(dir, "config", "user.email", "test@example.invalid")
  M.git(dir, "config", "user.name", "WraithVim Test")
  M.git(dir, "config", "commit.gpgsign", "false")
  return dir
end

---@param dir string
---@param msg string
function M.commit_all(dir, msg)
  M.git(dir, "add", "-A")
  local r = M.git(dir, "commit", "-q", "-m", msg)
  assert(r.code == 0, r.stderr)
end

--- Repository in the middle of a merge with two conflicts:
---   "my file (1).txt" - both modified
---   "gone.txt"        - modified by us, deleted by them
---@return string dir
function M.conflict_repo()
  local dir = M.repo()
  env.write(dir .. "/my file (1).txt", "alpha\nbeta\ngamma\n")
  env.write(dir .. "/gone.txt", "keep me\n")
  M.commit_all(dir, "base")
  M.git(dir, "checkout", "-q", "-b", "feature")
  env.write(dir .. "/my file (1).txt", "alpha\nbeta from theirs\ngamma\n")
  os.remove(dir .. "/gone.txt")
  M.commit_all(dir, "theirs")
  M.git(dir, "checkout", "-q", "main")
  env.write(dir .. "/my file (1).txt", "alpha\nbeta from ours\ngamma\n")
  env.write(dir .. "/gone.txt", "keep me, changed\n")
  M.commit_all(dir, "ours")
  local r = M.git(dir, "merge", "feature")
  assert(r.code ~= 0, "expected a conflicting merge")
  return dir
end

return M
