-- Search on top of Telescope. Uses ripgrep and fd when available and falls
-- back to `git grep` / `find` with a one-time hint otherwise.

local utils = require("wraithvim.core.utils")

local M = {}

local warned = {}

---@param tool string
---@param purpose string
local function hint(tool, purpose)
  if warned[tool] then
    return
  end
  warned[tool] = true
  vim.notify(
    ("%s not found: %s is slower or limited. Install it (e.g. pacman -S %s, apt install %s, dnf install %s)."):format(
      tool,
      purpose,
      tool == "fd" and "fd" or "ripgrep",
      tool == "fd" and "fd-find" or "ripgrep",
      tool == "fd" and "fd-find" or "ripgrep"
    ),
    vim.log.levels.WARN,
    { title = "WraithVim" }
  )
end

--- What searches include. Search finds what the explorer shows: dotfiles
--- with `explorer.show_hidden`, .gitignore'd files with
--- `explorer.show_gitignored`; `options.search.exclude` and `explorer.hide`
--- are skipped.
---@return { hidden: boolean, ignored: boolean, exclude: string[] }
function M.scope()
  local cfg = require("wraithvim.core.config").get()
  local ex = cfg.ui.explorer
  local exclude = vim.deepcopy(cfg.options.search.exclude)
  for _, name in ipairs(ex.hide) do
    if not vim.tbl_contains(exclude, name) then
      exclude[#exclude + 1] = name
    end
  end
  return { hidden = ex.show_hidden, ignored = ex.show_gitignored, exclude = exclude }
end

--- fd / rg flags for a scope.
---@param tool "fd"|"rg"
---@param scope table
---@return string[]
local function scope_flags(tool, scope)
  local flags = {}
  if scope.hidden then
    flags[#flags + 1] = "--hidden"
  end
  if scope.ignored then
    -- Only .gitignore is dropped; .ignore / .fdignore / .rgignore still apply.
    flags[#flags + 1] = "--no-ignore-vcs"
  end
  for _, name in ipairs(scope.exclude) do
    vim.list_extend(flags, tool == "fd" and { "--exclude", name } or { "--glob", "!" .. name })
  end
  return flags
end

--- Command used to list files, by preference fd > rg > find.
---@param scope? table defaults to M.scope()
---@return string[]
function M.find_command(scope)
  scope = scope or M.scope()
  for _, fd in ipairs({ "fd", "fdfind" }) do
    if utils.executable(fd) then
      return vim.list_extend({ fd, "--type", "f", "--color", "never" }, scope_flags("fd", scope))
    end
  end
  if utils.executable("rg") then
    return vim.list_extend({ "rg", "--files", "--color", "never" }, scope_flags("rg", scope))
  end
  local cmd = { "find", ".", "-type", "f" }
  if not scope.hidden then
    vim.list_extend(cmd, { "-not", "-path", "*/.*" })
  end
  for _, name in ipairs(scope.exclude) do
    vim.list_extend(cmd, { "-not", "-path", "*/" .. name .. "/*" })
  end
  return cmd
end

--- Grep command in vimgrep format (file:line:col:text).
---@param scope? table defaults to M.scope()
---@return string[]? cmd, string? tool
function M.grep_command(scope)
  scope = scope or M.scope()
  if utils.executable("rg") then
    local cmd =
      { "rg", "--color=never", "--no-heading", "--with-filename", "--line-number", "--column", "--smart-case" }
    return vim.list_extend(cmd, scope_flags("rg", scope)), "rg"
  end
  if utils.executable("git") and vim.fs.root(0, ".git") then
    local cmd = { "git", "grep", "--no-color", "--line-number", "--column", "-I", "--untracked" }
    if scope.ignored then
      cmd[#cmd + 1] = "--no-exclude-standard"
    end
    return cmd, "git"
  end
  return nil
end

---@param cfg table effective configuration
---@return table telescope setup options
function M.telescope_opts(cfg)
  local ic = require("wraithvim.ui.icons").get()
  local actions = require("telescope.actions")
  local grep = M.grep_command()
  return {
    defaults = {
      prompt_prefix = ic.prompt,
      selection_caret = ic.caret,
      vimgrep_arguments = grep,
      sorting_strategy = "ascending",
      layout_strategy = "flex",
      layout_config = {
        prompt_position = "top",
        horizontal = { preview_width = 0.55 },
        flex = { flip_columns = 120 },
      },
      path_display = { "truncate" },
      disable_devicons = not cfg.ui.icons.nerd_font,
      preview = { filesize_limit = 1, timeout = 200 },
      mappings = {
        i = {
          ["<C-j>"] = actions.move_selection_next,
          ["<C-k>"] = actions.move_selection_previous,
          ["<Esc>"] = actions.close,
        },
      },
    },
    pickers = {
      find_files = { find_command = M.find_command() },
      buffers = {
        sort_mru = true,
        ignore_current_buffer = true,
        mappings = { i = { ["<C-d>"] = actions.delete_buffer } },
      },
      oldfiles = { only_cwd = true },
    },
  }
end

---@param name string telescope builtin picker
---@param opts? table
function M.pick(name, opts)
  require("telescope.builtin")[name](opts or {})
end

function M.find_files()
  if not (utils.executable("fd") or utils.executable("fdfind") or utils.executable("rg")) then
    hint("fd", "file search")
  end
  M.pick("find_files")
end

function M.live_grep()
  local cmd, tool = M.grep_command()
  if not cmd then
    vim.notify(
      "Text search needs ripgrep (or a Git repository for git grep). Install ripgrep.",
      vim.log.levels.ERROR,
      { title = "WraithVim" }
    )
    return
  end
  if tool ~= "rg" then
    hint("rg", "text search")
  end
  M.pick("live_grep")
end

function M.grep_word()
  local cmd = M.grep_command()
  if not cmd then
    vim.notify("Text search needs ripgrep. Install ripgrep.", vim.log.levels.ERROR, { title = "WraithVim" })
    return
  end
  M.pick("grep_string")
end

function M.git_files()
  if not vim.fs.root(0, ".git") then
    vim.notify("Not inside a Git repository.", vim.log.levels.WARN, { title = "WraithVim" })
    return
  end
  M.pick("git_files", { show_untracked = true })
end

return M
