-- Version checks and lazy.nvim bootstrap.

local M = {}

M.min_version = { 0, 12, 0 }
M.lazy_repo = "https://github.com/folke/lazy.nvim.git"

---@return boolean ok, string? message
function M.check_version()
  -- has() is a cheap builtin; vim.version is only loaded to report a failure.
  if vim.fn.has(("nvim-%d.%d.%d"):format(unpack(M.min_version))) == 1 then
    return true
  end
  return false,
    ("WraithVim requires Neovim >= %s (found %s). Plugins were not loaded."):format(
      table.concat(M.min_version, "."),
      tostring(vim.version())
    )
end

--- Directory holding WraithVim-managed plugins. Kept separate from any
--- pre-existing `stdpath("data")/lazy` so another configuration is not affected.
---@return string
function M.plugin_root()
  return vim.fs.joinpath(vim.fn.stdpath("data"), "wraithvim", "plugins")
end

---@return string
function M.lazy_path()
  return vim.fs.joinpath(vim.fn.stdpath("data"), "wraithvim", "lazy.nvim")
end

--- Ensure lazy.nvim exists, cloning it on first start.
---@return string? path, string? err
function M.ensure_lazy()
  local path = M.lazy_path()
  if vim.uv.fs_stat(vim.fs.joinpath(path, "lua", "lazy", "init.lua")) then
    return path
  end
  if vim.fn.executable("git") ~= 1 then
    return nil, "git is not installed; cannot install lazy.nvim. Install git and restart Neovim."
  end
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  -- A partially cloned directory from an interrupted attempt would make git fail.
  if vim.uv.fs_stat(path) then
    vim.fn.delete(path, "rf")
  end
  vim.api.nvim_echo({ { "WraithVim: installing lazy.nvim...", "MoreMsg" } }, false, {})
  local result = vim
    .system({ "git", "clone", "--filter=blob:none", "--branch=stable", M.lazy_repo, path }, { text = true })
    :wait()
  if result.code ~= 0 then
    vim.fn.delete(path, "rf")
    local err = ("Failed to clone lazy.nvim (exit %d). Check your network connection.\n%s"):format(
      result.code,
      vim.trim(result.stderr or "")
    )
    return nil, err
  end
  return path
end

return M
