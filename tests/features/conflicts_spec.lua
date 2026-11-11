local env = require("tests.helpers.env")
local gh = require("tests.helpers.git")
local conflicts = require("wraithvim.features.conflicts")

-- Scripted answers for vim.fn.confirm (the real one would wait for input).
local answers, prompts = {}, {}
vim.fn.confirm = function(msg)
  prompts[#prompts + 1] = msg
  return table.remove(answers, 1) or 1
end
vim.notify = function() end

describe("conflicts: marker parsing", function()
  local lines = {
    "keep",
    "<<<<<<< HEAD",
    "ours 1",
    "ours 2",
    "||||||| base",
    "base",
    "=======",
    "theirs",
    ">>>>>>> feature",
    "tail",
    "<<<<<<< HEAD",
    "o",
    "=======",
    "t",
    ">>>>>>> feature",
  }

  it("finds merge and diff3 style regions", function()
    local regions = conflicts.find_conflicts(lines)
    assert.equals(2, #regions)
    assert.same({ start = 2, base = 5, sep = 7, finish = 9 }, regions[1])
    assert.same({ start = 11, sep = 13, finish = 15 }, regions[2])
  end)

  it("resolves a region with each choice", function()
    local r = conflicts.find_conflicts(lines)[1]
    assert.same({ "ours 1", "ours 2" }, conflicts.resolve_region(lines, r, "ours"))
    assert.same({ "theirs" }, conflicts.resolve_region(lines, r, "theirs"))
    assert.same({ "ours 1", "ours 2", "theirs" }, conflicts.resolve_region(lines, r, "both"))
    assert.same({ "base" }, conflicts.resolve_region(lines, r, "base"))
    assert.same({}, conflicts.resolve_region(lines, r, "none"))
  end)

  it("ignores unterminated markers and separators outside conflicts", function()
    assert.same({}, conflicts.find_conflicts({ "=======", "<<<<<<< a", "x" }))
  end)

  it("edits only the region under the cursor, and all regions with `all`", function()
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, { 3, 0 })
    assert.equals(1, conflicts.choose("theirs"))
    assert.equals(1, #conflicts.find_conflicts(vim.api.nvim_buf_get_lines(buf, 0, -1, false)))
    assert.equals(1, conflicts.choose("ours", { all = true }))
    assert.same({ "keep", "theirs", "tail", "o" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    assert.equals(0, conflicts.choose("ours"))
  end)

  it("derives git-status style kinds from stages", function()
    assert.equals("both modified", conflicts.kind({ "a", "b", "c" }))
    assert.equals("both added", conflicts.kind({ [2] = "b", [3] = "c" }))
    assert.equals("deleted by us", conflicts.kind({ [1] = "a", [3] = "c" }))
    assert.equals("deleted by them", conflicts.kind({ [1] = "a", [2] = "b" }))
  end)

  it("parses NUL-separated `git ls-files -u` output with odd filenames", function()
    local out = table.concat({
      "100644 aaa 1\tmy file (1).txt",
      "100644 bbb 2\tmy file (1).txt",
      "100644 ccc 3\tmy file (1).txt",
      "",
    }, "\0")
    local entries = conflicts.parse_unmerged(out)
    assert.equals(1, #entries)
    assert.equals("my file (1).txt", entries[1].path)
    assert.equals("both modified", entries[1].kind)
  end)
end)

describe("conflicts: Git workflow", function()
  local dir

  before_each(function()
    package.loaded["wraithvim.core.config"] = nil
    require("wraithvim.core.config").setup()
    dir = gh.conflict_repo()
    vim.cmd.cd(dir)
    answers, prompts = {}, {}
  end)

  after_each(function()
    vim.cmd("silent! tabonly! | silent! %bwipeout!")
    vim.cmd.cd(env.root)
    vim.fn.delete(dir, "rf")
  end)

  it("lists conflicted files with their kind", function()
    local entries = conflicts.list(dir)
    assert.equals(2, #entries)
    assert.equals("gone.txt", entries[1].path)
    assert.equals("deleted by them", entries[1].kind)
    assert.equals("my file (1).txt", entries[2].path)
    assert.equals("both modified", entries[2].kind)
  end)

  it("reads base, ours and theirs from the index", function()
    local rel = "my file (1).txt"
    assert.same({ "alpha", "beta", "gamma" }, conflicts.read_stage(dir, rel, 1))
    assert.same({ "alpha", "beta from ours", "gamma" }, conflicts.read_stage(dir, rel, 2))
    assert.same({ "alpha", "beta from theirs", "gamma" }, conflicts.read_stage(dir, rel, 3))
    assert.equals("merge", conflicts.operation(dir))
  end)

  it("opens a four-pane view, resolves, saves and stages", function()
    conflicts.open(dir .. "/my file (1).txt")
    local session = conflicts.current_session()
    assert.is_not_nil(session)
    assert.equals("my file (1).txt", session.rel)
    local wins = vim.api.nvim_tabpage_list_wins(0)
    assert.equals(4, #wins)
    for _, win in ipairs(wins) do
      assert.is_true(vim.wo[win].diff, "window not in diff mode")
    end
    -- Stage panes are read-only scratch buffers.
    local ours = session.wins.OURS
    assert.is_false(vim.bo[vim.api.nvim_win_get_buf(ours)].modifiable)
    -- Cursor starts on the first conflict in RESULT.
    assert.equals(session.result_buf, vim.api.nvim_get_current_buf())
    assert.matches("^<<<<<<<", vim.api.nvim_get_current_line())

    conflicts.choose("both")
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.same({ "alpha", "beta from ours", "beta from theirs", "gamma" }, lines)

    answers = { 1, 2 } -- "Save before staging?" -> Save; "Open the next conflicted file?" -> No
    assert.is_true(conflicts.resolve())
    assert.equals("alpha\nbeta from ours\nbeta from theirs\ngamma\n", env.read(dir .. "/my file (1).txt"))
    assert.equals("", vim.trim(gh.git(dir, "ls-files", "-u", "--", "my file (1).txt").stdout))
    assert.equals(1, #conflicts.list(dir))
    assert.is_nil(conflicts.current_session())
  end)

  it("refuses to stage a file that still has markers unless confirmed", function()
    conflicts.open(dir .. "/my file (1).txt")
    answers = { 1 } -- "Stage it anyway?" -> No
    assert.is_false(conflicts.resolve())
    assert.matches("still contains 1 conflict", prompts[1])
    assert.equals(2, #conflicts.list(dir))
  end)

  it("resolves a modify/delete conflict by deleting the file after confirmation", function()
    conflicts.open(dir .. "/gone.txt")
    local session = conflicts.current_session()
    assert.equals("deleted by them", session.kind)
    -- THEIRS pane explains that the file was deleted.
    local theirs = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(session.wins.THEIRS), 0, -1, false)
    assert.matches("deleted in THEIRS", theirs[1])

    answers = { 1 } -- "Delete the file and stage the deletion?" -> No
    assert.is_false(conflicts.choose_file("theirs"))
    assert.is_not_nil(vim.uv.fs_stat(dir .. "/gone.txt"))

    answers = { 2, 2 } -- Yes, then "Open the next conflicted file?" -> No
    assert.is_true(conflicts.choose_file("theirs"))
    assert.is_nil(vim.uv.fs_stat(dir .. "/gone.txt"))
    assert.equals(1, #conflicts.list(dir))
  end)

  it("replaces RESULT with a whole side only after confirmation (undoable, unsaved)", function()
    conflicts.open(dir .. "/my file (1).txt")
    answers = { 2 }
    assert.is_true(conflicts.choose_file("ours"))
    assert.same({ "alpha", "beta from ours", "gamma" }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
    assert.is_true(vim.bo.modified)
    -- Nothing was written to disk.
    assert.matches("<<<<<<<", env.read(dir .. "/my file (1).txt"))
  end)

  it("fills the quickfix list with conflicted files", function()
    assert.equals(2, conflicts.quickfix())
    local qf = vim.fn.getqflist()
    assert.equals(2, #qf)
    assert.equals(2, qf[2].lnum) -- first marker line in "my file (1).txt"
    vim.cmd("cclose")
  end)
end)
