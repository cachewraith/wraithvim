-- Git graph (vim-flog) made readable: one commit per line as
-- "hash (branches) message  author  2 days ago", colored branches, a header
-- listing the keys, and short one-key actions on the commit under the cursor.

local M = {}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Git graph" })
end

--- Options passed to every :Flog (vim-flog reads them when it loads).
function M.globals()
  -- Required for a custom format to keep hash/author/date colors.
  vim.g.flog_enable_dynamic_commit_hl = true
  vim.g.flog_default_opts = {
    format = "%h%d %s  %an  %ad",
    date = "relative",
    max_count = 2000,
  }
end

--- Keys shown in the header, in order.
M.keys = {
  { "Enter", "open" },
  { "d", "diff" },
  { "c", "checkout" },
  { "y", "copy hash" },
  { "a", "all branches" },
  { "u", "refresh" },
  { "?", "all keys" },
  { "q", "close" },
}

---@return string winbar
function M.winbar()
  local parts = { "%#WraithGraphTitle#  Git graph %*" }
  for _, k in ipairs(M.keys) do
    parts[#parts + 1] = ("%%#WraithGraphKey# %s %%#WraithGraphHint#%s%%*"):format(k[1], k[2])
  end
  -- %< at the end: a narrow window cuts the least important keys first.
  return table.concat(parts, " ") .. "%<"
end

---@return { hash: string, refs: string }?
function M.commit()
  local ok, commit = pcall(vim.fn["flog#floggraph#commit#GetAtLine"], ".")
  if not ok or type(commit) ~= "table" or not commit.hash then
    notify("Move the cursor to a commit line first.", vim.log.levels.WARN)
    return nil
  end
  return commit
end

---@return string?
local function root()
  local ok, dir = pcall(vim.fn.FugitiveWorkTree)
  if ok and dir ~= "" then
    return dir
  end
  return require("wraithvim.features.git").root(vim.fn.getcwd())
end

local function refresh()
  pcall(vim.fn["flog#floggraph#buf#Update"])
end

function M.diff()
  local commit = M.commit()
  if commit then
    vim.cmd("DiffviewOpen " .. commit.hash .. "^!")
  end
end

function M.copy_hash()
  local commit = M.commit()
  if commit then
    vim.fn.setreg("+", commit.hash)
    vim.fn.setreg('"', commit.hash)
    notify("Copied " .. commit.hash)
  end
end

--- Local branches pointing at `hash`.
---@param dir string
---@param hash string
---@return string[]
function M.branches_at(dir, hash)
  local res = require("wraithvim.features.git").git({ "branch", "--format=%(refname:short)", "--points-at", hash }, dir)
  if res.code ~= 0 then
    return {}
  end
  return vim.split(vim.trim(res.stdout or ""), "\n", { trimempty = true })
end

---@param dir string
---@param target string branch name or commit hash
local function checkout(dir, target)
  local res = require("wraithvim.features.git").git({ "checkout", target }, dir)
  if res.code ~= 0 then
    notify("git checkout failed:\n" .. vim.trim(res.stderr or ""), vim.log.levels.ERROR)
    return
  end
  notify("Checked out " .. target)
  pcall(vim.cmd.checktime)
  refresh()
end

--- Check out the commit under the cursor: its branch when it has one,
--- otherwise the commit itself (after confirmation, since that detaches HEAD).
function M.checkout()
  local commit = M.commit()
  local dir = commit and root()
  if not commit or not dir then
    return
  end
  local branches = M.branches_at(dir, commit.hash)
  if #branches == 1 then
    if vim.fn.confirm("Check out branch " .. branches[1] .. "?", "&Yes\n&No", 1) == 1 then
      checkout(dir, branches[1])
    end
  elseif #branches > 1 then
    vim.ui.select(branches, { prompt = "Check out branch" }, function(choice)
      if choice then
        checkout(dir, choice)
      end
    end)
  else
    local msg = ("Commit %s has no branch. Check it out anyway (detached HEAD)?"):format(commit.hash)
    if vim.fn.confirm(msg, "&Yes\n&No", 2) == 1 then
      checkout(dir, commit.hash)
    end
  end
end

---@param buf integer floggraph buffer
function M.setup_buffer(buf)
  local function map(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { buffer = buf, nowait = true, silent = true, desc = desc })
  end
  map("q", "<Plug>(FlogQuit)", "Close the graph")
  map("?", "<Plug>(FlogHelp)", "All graph keys")
  map("d", M.diff, "Diff of this commit")
  map("c", M.checkout, "Check out this commit")
  map("y", M.copy_hash, "Copy commit hash")
  vim.wo[0][0].winbar = M.winbar()
  vim.wo[0][0].cursorline = true
  vim.wo[0][0].number = false
  vim.wo[0][0].signcolumn = "no"
end

--- Branch colors and commit fields on top of the colorscheme. Not `default`:
--- vim-flog defines its own defaults and these must win.
function M.highlights()
  local ok, colors = pcall(function()
    return require("tokyonight.colors").setup()
  end)
  local c = ok and colors
    or {
      green = "#9ece6a",
      yellow = "#e0af68",
      orange = "#ff9e64",
      red = "#f7768e",
      magenta = "#bb9af7",
      purple = "#9d7cd8",
      blue = "#7aa2f7",
      cyan = "#7dcfff",
      comment = "#565f89",
      fg_dark = "#a9b1d6",
      teal = "#1abc9c",
      bg_highlight = "#292e42",
    }
  local set = vim.api.nvim_set_hl
  local branch = { c.blue, c.green, c.magenta, c.orange, c.cyan, c.yellow, c.red, c.teal }
  for i, color in ipairs(branch) do
    set(0, "flogBranch" .. i, { fg = color })
  end
  set(0, "flogHash", { fg = c.yellow })
  set(0, "flogAuthor", { fg = c.fg_dark })
  set(0, "flogDate", { fg = c.comment, italic = true })
  set(0, "flogRef", { fg = c.cyan, bold = true })
  set(0, "flogRefHead", { fg = c.green, bold = true })
  set(0, "flogRefHeadArrow", { fg = c.green })
  set(0, "flogRefHeadBranch", { fg = c.green, bold = true })
  set(0, "flogRefRemote", { fg = c.purple })
  set(0, "flogRefTag", { fg = c.orange, bold = true })
  set(0, "WraithGraphTitle", { fg = c.blue, bold = true })
  set(0, "WraithGraphKey", { fg = c.yellow, bg = c.bg_highlight, bold = true })
  set(0, "WraithGraphHint", { fg = c.comment })
end

function M.setup()
  M.globals()
  local group = require("wraithvim.core.utils").augroup("graph")
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "floggraph",
    callback = function(args)
      M.used = true
      M.highlights()
      M.setup_buffer(args.buf)
    end,
  })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      if M.used then
        M.highlights()
      end
    end,
  })
end

return M
