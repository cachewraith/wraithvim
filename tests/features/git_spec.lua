local env = require("tests.helpers.env")
local gh = require("tests.helpers.git")
local git = require("wraithvim.features.git")

vim.notify = function() end

describe("features.git", function()
  local dir

  before_each(function()
    dir = gh.repo()
    env.write(dir .. "/README", "x\n")
    gh.commit_all(dir, "init")
  end)

  after_each(function()
    vim.cmd("silent! %bwipeout!")
    vim.fn.delete(dir, "rf")
  end)

  it("finds the repository root without spawning git", function()
    env.write(dir .. "/a/b/c.txt", "")
    assert.equals(dir, git.root(dir .. "/a/b/c.txt"))
  end)

  it("stages and unstages files whose names contain shell metacharacters", function()
    local name = "it's a $file; (1).txt"
    env.write(dir .. "/" .. name, "content\n")
    vim.cmd.edit(vim.fn.fnameescape(dir .. "/" .. name))
    assert.is_true(git.stage_file())
    assert.equals(name, vim.trim(gh.git(dir, "diff", "--cached", "--name-only", "-z").stdout:gsub("%z", "")))
    assert.is_true(git.unstage_file())
    assert.equals("", vim.trim(gh.git(dir, "diff", "--cached", "--name-only").stdout))
  end)

  it("treats file names as literal paths, not globs", function()
    -- "[id].tsx" as a pathspec also matches i.tsx and d.tsx.
    env.write(dir .. "/[id].tsx", "")
    env.write(dir .. "/i.tsx", "")
    env.write(dir .. "/d.tsx", "")
    vim.cmd.edit(vim.fn.fnameescape(dir .. "/[id].tsx"))
    assert.is_true(git.stage_file())
    assert.equals("[id].tsx", vim.trim(gh.git(dir, "diff", "--cached", "--name-only").stdout))
  end)

  it("stages a new, unsaved file in its own repository, not the cwd's", function()
    local other = gh.repo()
    env.write(other .. "/README", "x\n")
    gh.commit_all(other, "init")
    vim.cmd.cd(vim.fn.fnameescape(dir))
    vim.cmd.edit(vim.fn.fnameescape(other .. "/new.txt"))
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "new" })
    assert.is_true(git.stage_file())
    assert.equals("new.txt", vim.trim(gh.git(other, "diff", "--cached", "--name-only").stdout))
    vim.cmd.cd("-")
    vim.fn.delete(other, "rf")
  end)

  it("refuses to stage non-file buffers", function()
    vim.cmd.enew()
    vim.bo.buftype = "nofile"
    assert.is_false(git.stage_file())
  end)
end)
