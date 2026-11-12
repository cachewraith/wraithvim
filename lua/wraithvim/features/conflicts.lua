-- Three-way merge conflict resolution built on Git's index stages.
--
--   stage 1 = BASE (common ancestor), stage 2 = OURS, stage 3 = THEIRS,
--   working tree file = RESULT (the only editable pane).
--
-- All edits happen inside the RESULT buffer, so they are undoable and nothing
-- is written until the user saves. Marking a file resolved asks for
-- confirmation when the buffer is unsaved or still contains conflict markers.

local git = require("wraithvim.features.git")
local utils = require("wraithvim.core.utils")

local M = {}

local STAGE_NAMES = { [1] = "BASE", [2] = "OURS", [3] = "THEIRS" }

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Conflicts" })
end

---------------------------------------------------------------------------
-- Index inspection
---------------------------------------------------------------------------

--- Describe which stages exist the way `git status` does.
---@param stages table<integer, string>
---@return string
function M.kind(stages)
  local b, o, t = stages[1] ~= nil, stages[2] ~= nil, stages[3] ~= nil
  if b and o and t then
    return "both modified"
  elseif o and t then
    return "both added"
  elseif b and t then
    return "deleted by us"
  elseif b and o then
    return "deleted by them"
  elseif o then
    return "added by us"
  elseif t then
    return "added by them"
  end
  return "both deleted"
end

--- Parse `git ls-files -u -z` output.
---@param out string
---@return table[] entries sorted by path: { path, stages = { [n] = sha }, kind }
function M.parse_unmerged(out)
  local by_path, order = {}, {}
  for record in out:gmatch("[^%z]+") do
    local _, sha, stage, path = record:match("^(%d+) (%x+) (%d)\t(.+)$")
    if path then
      if not by_path[path] then
        by_path[path] = { path = path, stages = {} }
        order[#order + 1] = path
      end
      by_path[path].stages[tonumber(stage)] = sha
    end
  end
  table.sort(order)
  local entries = {}
  for _, path in ipairs(order) do
    local e = by_path[path]
    e.kind = M.kind(e.stages)
    entries[#entries + 1] = e
  end
  return entries
end

--- Conflicted files in the repository at `root`.
---@param root string
---@return table[]? entries, string? err
function M.list(root)
  local r = git.git({ "ls-files", "-u", "-z" }, root)
  if r.code ~= 0 then
    return nil, utils.trim(r.stderr)
  end
  return M.parse_unmerged(r.stdout or "")
end

--- Content of an index stage.
---@param root string
---@param rel string path relative to root
---@param stage integer 1..3
---@return string[]? lines, string? err  err is "binary" for binary blobs
function M.read_stage(root, rel, stage)
  local r = git.git({ "show", (":%d:%s"):format(stage, rel) }, root)
  if r.code ~= 0 then
    return nil, utils.trim(r.stderr)
  end
  local out = r.stdout or ""
  if out:find("%z") then
    return nil, "binary"
  end
  if out:sub(-1) == "\n" then
    out = out:sub(1, -2)
  end
  return vim.split(out, "\n", { plain = true })
end

--- Which operation produced the conflict, for labelling.
---@param root string
---@return string
function M.operation(root)
  local r = git.git({ "rev-parse", "--git-dir" }, root)
  if r.code ~= 0 then
    return "merge"
  end
  local gitdir = utils.trim(r.stdout)
  if not gitdir:match("^/") then
    gitdir = vim.fs.joinpath(root, gitdir)
  end
  local function exists(name)
    return vim.uv.fs_stat(vim.fs.joinpath(gitdir, name)) ~= nil
  end
  if exists("rebase-merge") or exists("rebase-apply") then
    return "rebase"
  elseif exists("CHERRY_PICK_HEAD") then
    return "cherry-pick"
  elseif exists("REVERT_HEAD") then
    return "revert"
  end
  return "merge"
end

---------------------------------------------------------------------------
-- Conflict markers in the RESULT buffer
---------------------------------------------------------------------------

--- Locate conflict regions. Supports merge and diff3/zdiff3 styles.
---@param lines string[]
---@return { start: integer, base: integer?, sep: integer, finish: integer }[] 1-based line numbers
function M.find_conflicts(lines)
  local regions = {}
  local cur
  -- Markers are exactly seven characters, followed by a label or end of line
  -- (with an optional \r in CRLF files). Longer runs such as a `========`
  -- Markdown underline are content, not markers.
  for i, line in ipairs(lines) do
    if line:match("^<<<<<<<[ \r]") or line == "<<<<<<<" then
      cur = { start = i }
    elseif cur and not cur.sep and (line:match("^|||||||[ \r]") or line == "|||||||") then
      cur.base = i
    elseif cur and not cur.sep and line:match("^=======\r?$") then
      cur.sep = i
    elseif cur and cur.sep and (line:match("^>>>>>>>[ \r]") or line == ">>>>>>>") then
      cur.finish = i
      regions[#regions + 1] = cur
      cur = nil
    end
  end
  return regions
end

--- Replacement lines for a region.
---@param lines string[]
---@param region table
---@param choice "ours"|"theirs"|"both"|"base"|"none"
---@return string[]
function M.resolve_region(lines, region, choice)
  local ours = vim.list_slice(lines, region.start + 1, (region.base or region.sep) - 1)
  local base = region.base and vim.list_slice(lines, region.base + 1, region.sep - 1) or {}
  local theirs = vim.list_slice(lines, region.sep + 1, region.finish - 1)
  if choice == "ours" then
    return ours
  elseif choice == "theirs" then
    return theirs
  elseif choice == "both" then
    return vim.list_extend(ours, theirs)
  elseif choice == "base" then
    return base
  elseif choice == "none" then
    return {}
  end
  error("invalid choice: " .. tostring(choice))
end

M.choices = { "ours", "theirs", "both", "base", "none" }

--- Resolve the conflict under the cursor (or every conflict with `all`).
---@param choice string
---@param opts? { buf?: integer, all?: boolean, line?: integer }
---@return integer resolved number of regions changed
function M.choose(choice, opts)
  opts = opts or {}
  if not vim.tbl_contains(M.choices, choice) then
    notify(
      "Unknown choice " .. tostring(choice) .. " (use " .. table.concat(M.choices, ", ") .. ")",
      vim.log.levels.ERROR
    )
    return 0
  end
  local buf = opts.buf or vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local regions = M.find_conflicts(lines)
  local targets = {}
  if opts.all then
    targets = regions
  else
    local line = opts.line or vim.api.nvim_win_get_cursor(0)[1]
    for _, r in ipairs(regions) do
      if line >= r.start and line <= r.finish then
        targets = { r }
        break
      end
    end
    if #targets == 0 then
      notify("Cursor is not inside a conflict region. Use ]x / [x to jump to one.", vim.log.levels.WARN)
      return 0
    end
  end
  -- Bottom-up so earlier line numbers stay valid.
  for i = #targets, 1, -1 do
    local r = targets[i]
    vim.api.nvim_buf_set_lines(buf, r.start - 1, r.finish, false, M.resolve_region(lines, r, choice))
  end
  return #targets
end

--- Jump to the next/previous conflict marker.
---@param direction 1|-1
function M.jump(direction)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local regions = M.find_conflicts(lines)
  if #regions == 0 then
    notify("No conflict markers in this buffer.")
    return
  end
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local target
  if direction > 0 then
    for _, r in ipairs(regions) do
      if r.start > cur then
        target = r.start
        break
      end
    end
    target = target or regions[1].start
  else
    for i = #regions, 1, -1 do
      if regions[i].start < cur then
        target = regions[i].start
        break
      end
    end
    target = target or regions[#regions].start
  end
  vim.api.nvim_win_set_cursor(0, { target, 0 })
  vim.cmd("normal! zz")
end

---------------------------------------------------------------------------
-- Session (tab) management
---------------------------------------------------------------------------

---@type table<integer, table> tabpage -> session
M.sessions = {}

--- Session of the current tab, if its RESULT buffer is still shown there.
---@return table? session
function M.current_session()
  local tab = vim.api.nvim_get_current_tabpage()
  local session = M.sessions[tab]
  if not session then
    return nil
  end
  local buf = session.result_buf
  if vim.api.nvim_buf_is_valid(buf) then
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      if vim.api.nvim_win_get_buf(win) == buf then
        return session
      end
    end
  end
  M.sessions[tab] = nil
  return nil
end

--- Resolve a path argument to (root, rel). Defaults to the current buffer.
---@param path? string
---@return string? root, string? rel
local function locate(path)
  if path and path ~= "" then
    local abs = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
    local root = git.root(abs)
    if not root then
      return nil
    end
    root = vim.uv.fs_realpath(root) or root
    local dir = vim.uv.fs_realpath(vim.fs.dirname(abs)) or vim.fs.dirname(abs)
    local real = vim.fs.joinpath(dir, vim.fs.basename(abs))
    return root, vim.fs.relpath(root, real)
  end
  local session = M.current_session()
  if session then
    return session.root, session.rel
  end
  local name = vim.api.nvim_buf_get_name(0)
  if name ~= "" and vim.bo.buftype == "" then
    return locate(name)
  end
  local root = git.root()
  return root and (vim.uv.fs_realpath(root) or root) or nil, nil
end

---@param name string
---@param lines string[]
---@param ft string
---@return integer buf
local function scratch(name, lines, ft)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true
  pcall(vim.api.nvim_buf_set_name, buf, name)
  if ft ~= "" then
    vim.bo[buf].filetype = ft
  end
  return buf
end

---@param session table
local function set_result_keymaps(session)
  local buf = session.result_buf
  local function map(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = buf, desc = desc })
  end
  for key, choice in pairs({ o = "ours", t = "theirs", b = "both", ["0"] = "base", n = "none" }) do
    map("<leader>c" .. key, function()
      M.choose(choice)
    end, "Conflict: take " .. choice)
  end
  map("]x", function()
    M.jump(1)
  end, "Next conflict")
  map("[x", function()
    M.jump(-1)
  end, "Previous conflict")
  map("<leader>cr", function()
    M.resolve()
  end, "Conflict: mark resolved")
  map("<leader>cq", function()
    M.close()
  end, "Conflict: close view")
end

--- Open the three-way view for a conflicted file.
---@param path? string defaults to the current file, or prompts when several conflicts exist
function M.open(path)
  local root, rel = locate(path)
  if not root then
    notify("Not inside a Git repository.", vim.log.levels.WARN)
    return
  end
  local entries, err = M.list(root)
  if not entries then
    notify("git ls-files failed: " .. tostring(err), vim.log.levels.ERROR)
    return
  end
  if #entries == 0 then
    notify("No merge conflicts in " .. vim.fn.fnamemodify(root, ":~"))
    return
  end

  local entry
  for _, e in ipairs(entries) do
    if e.path == rel then
      entry = e
    end
  end
  if not entry then
    if #entries == 1 then
      entry = entries[1]
    else
      vim.ui.select(entries, {
        prompt = "Conflicted files",
        format_item = function(e)
          return ("%s  (%s)"):format(e.path, e.kind)
        end,
      }, function(choice)
        if choice then
          M.open(vim.fs.joinpath(root, choice.path))
        end
      end)
      return
    end
  end

  M.open_entry(root, entry)
end

local cleanup_registered = false

--- Forget sessions whose tab was closed. Registered on first use only.
local function register_cleanup()
  if cleanup_registered then
    return
  end
  cleanup_registered = true
  vim.api.nvim_create_autocmd("TabClosed", {
    group = utils.augroup("conflicts"),
    callback = function()
      local valid = {}
      for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
        valid[tab] = true
      end
      for tab in pairs(M.sessions) do
        if not valid[tab] then
          M.sessions[tab] = nil
        end
      end
    end,
  })
end

--- Build the layout:  OURS | BASE | THEIRS  over a full-width RESULT pane.
---@param root string
---@param entry table
function M.open_entry(root, entry)
  local rel = entry.path
  local abs = vim.fs.joinpath(root, rel)
  local exists = vim.uv.fs_stat(abs) ~= nil

  if not exists then
    notify(
      ("%s: %s. The working tree file is gone; resolve with :ConflictChoose! <side> or `git rm`."):format(
        rel,
        entry.kind
      ),
      vim.log.levels.WARN
    )
  end

  register_cleanup()
  local op = M.operation(root)
  vim.cmd.tabnew()
  local tab = vim.api.nvim_get_current_tabpage()
  vim.cmd.tcd(vim.fn.fnameescape(root))
  if exists then
    vim.cmd.edit(vim.fn.fnameescape(abs))
  else
    vim.cmd.enew()
  end
  local result_win = vim.api.nvim_get_current_win()
  local result_buf = vim.api.nvim_get_current_buf()
  local ft = vim.bo[result_buf].filetype
  if ft == "" then
    ft = vim.filetype.match({ filename = abs }) or ""
  end

  local session = { root = root, rel = rel, kind = entry.kind, op = op, result_buf = result_buf, wins = {} }
  local panes = {}
  for _, stage in ipairs({ 2, 1, 3 }) do
    local lines, read_err
    local diffable = false
    if entry.stages[stage] then
      lines, read_err = M.read_stage(root, rel, stage)
      if lines then
        diffable = true
      elseif read_err == "binary" then
        lines = { ("(%s is a binary file; choose a whole side with :ConflictChoose!)"):format(STAGE_NAMES[stage]) }
      else
        lines = { ("(could not read %s: %s)"):format(STAGE_NAMES[stage], read_err) }
      end
    else
      local why = stage == 1 and "no common ancestor: added on both sides" or ("deleted in " .. STAGE_NAMES[stage])
      lines = { ("(%s does not exist: %s)"):format(STAGE_NAMES[stage], why) }
    end
    local name = ("wraithconflict://%s/%s"):format(STAGE_NAMES[stage], rel)
    panes[#panes + 1] = { stage = stage, buf = scratch(name, lines, diffable and ft or ""), diffable = diffable }
  end

  local top_height = math.max(5, math.floor(vim.o.lines * 0.4))
  local prev
  for i, pane in ipairs(panes) do
    local win
    if i == 1 then
      win = vim.api.nvim_open_win(pane.buf, false, { split = "above", win = result_win, height = top_height })
    else
      win = vim.api.nvim_open_win(pane.buf, false, { split = "right", win = prev })
    end
    pane.win = win
    prev = win
    local label = STAGE_NAMES[pane.stage]
    if op == "rebase" and pane.stage ~= 1 then
      label = label .. (pane.stage == 2 and " (upstream)" or " (your commit)")
    end
    vim.wo[win].winbar = "%#Title# " .. label .. " %*"
    session.wins[label] = win
  end
  -- Equal widths for the three top panes.
  local width = math.floor(vim.o.columns / 3)
  for i = 1, 2 do
    vim.api.nvim_win_set_width(panes[i].win, width)
  end

  vim.wo[result_win].winbar = ("%%#DiffChange# RESULT %%* %s  (%s, %s)  <leader>co/ct/cb/c0/cn  ]x [x  <leader>cr resolve"):format(
    rel:gsub("%%", "%%%%"),
    entry.kind,
    op
  )

  local diff_wins = {}
  for _, pane in ipairs(panes) do
    if pane.diffable then
      diff_wins[#diff_wins + 1] = pane.win
      -- `dp` in a stage pane puts the hunk into RESULT.
      vim.keymap.set("n", "dp", function()
        vim.cmd.diffput(result_buf)
      end, { buffer = pane.buf, desc = "Put hunk into RESULT" })
    end
  end
  if exists then
    diff_wins[#diff_wins + 1] = result_win
  end
  if #diff_wins >= 2 then
    for _, win in ipairs(diff_wins) do
      vim.api.nvim_win_call(win, function()
        vim.cmd.diffthis()
      end)
    end
  end

  M.sessions[tab] = session
  set_result_keymaps(session)
  vim.api.nvim_set_current_win(result_win)
  if exists then
    local regions = M.find_conflicts(vim.api.nvim_buf_get_lines(result_buf, 0, -1, false))
    if regions[1] then
      vim.api.nvim_win_set_cursor(result_win, { regions[1].start, 0 })
    end
  end
end

--- Close the conflict view in the current tab.
function M.close()
  local tab = vim.api.nvim_get_current_tabpage()
  if not M.sessions[tab] then
    return
  end
  M.sessions[tab] = nil
  if #vim.api.nvim_list_tabpages() > 1 then
    vim.cmd.tabclose()
  end
end

---@param root string
local function report_remaining(root)
  local entries = M.list(root) or {}
  if #entries == 0 then
    notify("All conflicts resolved. Review with :GitStatus, then commit (or continue the rebase).")
    return
  end
  notify(("%d conflicted file(s) remaining: %s"):format(#entries, entries[1].path))
  local choice = vim.fn.confirm("Open the next conflicted file?", "&Yes\n&No", 1)
  if choice == 1 then
    M.open_entry(root, entries[1])
  end
end

--- Mark the file resolved: save check, marker check, then `git add`.
---@param path? string
---@return boolean staged
function M.resolve(path)
  local root, rel = locate(path)
  if not root or not rel then
    notify("No conflicted file to resolve here.", vim.log.levels.WARN)
    return false
  end
  local abs = vim.fs.joinpath(root, rel)
  local buf = vim.fn.bufnr(abs)
  if buf > 0 and vim.bo[buf].modified then
    local choice = vim.fn.confirm(rel .. " has unsaved changes. Save before staging?", "&Save\n&Cancel", 1)
    if choice ~= 1 then
      return false
    end
    vim.api.nvim_buf_call(buf, function()
      vim.cmd.write()
    end)
  end

  if not vim.uv.fs_stat(abs) then
    notify(rel .. " does not exist in the working tree. Use :ConflictChoose! to pick a side.", vim.log.levels.WARN)
    return false
  end

  local fd = io.open(abs, "rb")
  local content = fd and fd:read("*a") or ""
  if fd then
    fd:close()
  end
  local remaining = #M.find_conflicts(vim.split(content, "\n", { plain = true }))
  if remaining > 0 then
    local choice = vim.fn.confirm(
      ("%s still contains %d conflict region(s). Stage it anyway?"):format(rel, remaining),
      "&No\n&Yes",
      1
    )
    if choice ~= 2 then
      return false
    end
  end

  local r = git.git({ "add", "--", rel }, root)
  if r.code ~= 0 then
    notify("git add failed: " .. utils.trim(r.stderr), vim.log.levels.ERROR)
    return false
  end
  local still = git.git({ "ls-files", "-u", "--", rel }, root)
  if utils.trim(still.stdout) ~= "" then
    notify(rel .. " is still unmerged after git add.", vim.log.levels.ERROR)
    return false
  end
  notify("Resolved and staged " .. rel)
  if package.loaded["gitsigns"] then
    pcall(require("gitsigns").refresh)
  end

  local session = M.current_session()
  if session and session.rel == rel then
    M.close()
  end
  report_remaining(root)
  return true
end

--- Replace RESULT with a whole side, or delete the file when that side
--- deleted it. Always asks first; the buffer change is undoable.
---@param side "ours"|"theirs"|"base"
---@param path? string
---@return boolean
function M.choose_file(side, path)
  local stage = ({ base = 1, ours = 2, theirs = 3 })[side]
  if not stage then
    notify("Choose one of: ours, theirs, base", vim.log.levels.ERROR)
    return false
  end
  local root, rel = locate(path)
  if not root or not rel then
    notify("No conflicted file here.", vim.log.levels.WARN)
    return false
  end
  local entries = M.list(root) or {}
  local entry
  for _, e in ipairs(entries) do
    if e.path == rel then
      entry = e
    end
  end
  if not entry then
    notify(rel .. " is not conflicted.", vim.log.levels.WARN)
    return false
  end

  if not entry.stages[stage] then
    local choice = vim.fn.confirm(
      ("%s does not exist in %s. Delete the file and stage the deletion?"):format(rel, side:upper()),
      "&No\n&Yes",
      1
    )
    if choice ~= 2 then
      return false
    end
    local r = git.git({ "rm", "--quiet", "--force", "--", rel }, root)
    if r.code ~= 0 then
      notify("git rm failed: " .. utils.trim(r.stderr), vim.log.levels.ERROR)
      return false
    end
    notify("Deleted " .. rel .. " and staged the deletion.")
    local session = M.current_session()
    if session and session.rel == rel then
      M.close()
    end
    report_remaining(root)
    return true
  end

  local lines, err = M.read_stage(root, rel, stage)
  if not lines then
    if err == "binary" then
      if side == "base" then
        notify("Binary BASE versions cannot be checked out directly; choose ours or theirs.", vim.log.levels.WARN)
        return false
      end
      local choice =
        vim.fn.confirm(("Check out the binary %s version of %s?"):format(side:upper(), rel), "&No\n&Yes", 1)
      if choice ~= 2 then
        return false
      end
      local flag = side == "ours" and "--ours" or "--theirs"
      local r = git.git({ "checkout", flag, "--", rel }, root)
      if r.code ~= 0 then
        notify("git checkout failed: " .. utils.trim(r.stderr), vim.log.levels.ERROR)
        return false
      end
      vim.cmd.checktime()
      notify(("Checked out %s version of %s. Run :ConflictResolve to stage it."):format(side, rel))
      return true
    end
    notify("Could not read stage: " .. tostring(err), vim.log.levels.ERROR)
    return false
  end

  local abs = vim.fs.joinpath(root, rel)
  local buf = vim.fn.bufnr(abs)
  if buf <= 0 then
    vim.cmd.edit(vim.fn.fnameescape(abs))
    buf = vim.api.nvim_get_current_buf()
  end
  local choice = vim.fn.confirm(
    ("Replace the RESULT buffer of %s with the full %s version? (undo with u)"):format(rel, side:upper()),
    "&No\n&Yes",
    1
  )
  if choice ~= 2 then
    return false
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  notify(("RESULT now contains %s. Save, then :ConflictResolve."):format(side:upper()))
  return true
end

--- Fill the quickfix list with conflicted files (first marker line when present).
---@return integer count
function M.quickfix()
  local root = locate()
  if not root then
    notify("Not inside a Git repository.", vim.log.levels.WARN)
    return 0
  end
  local entries = M.list(root) or {}
  local items = {}
  for _, e in ipairs(entries) do
    local abs = vim.fs.joinpath(root, e.path)
    local lnum = 1
    local fd = io.open(abs, "rb")
    if fd then
      local regions = M.find_conflicts(vim.split(fd:read("*a"), "\n", { plain = true }))
      fd:close()
      lnum = regions[1] and regions[1].start or 1
    end
    items[#items + 1] = { filename = abs, lnum = lnum, text = e.kind }
  end
  vim.fn.setqflist({}, " ", { title = "Git conflicts", items = items })
  if #items == 0 then
    notify("No merge conflicts.")
  else
    vim.cmd("botright copen")
  end
  return #items
end

function M.setup()
  vim.api.nvim_create_autocmd("TabClosed", {
    group = utils.augroup("conflicts"),
    callback = function()
      local valid = {}
      for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
        valid[tab] = true
      end
      for tab in pairs(M.sessions) do
        if not valid[tab] then
          M.sessions[tab] = nil
        end
      end
    end,
  })
end

return M
