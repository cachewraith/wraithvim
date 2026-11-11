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

  it("refuses to stage non-file buffers", function()
    vim.cmd.enew()
    vim.bo.buftype = "nofile"
    assert.is_false(git.stage_file())
  end)
end)
