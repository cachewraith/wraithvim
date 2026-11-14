local env = require("tests.helpers.env")
local gh = require("tests.helpers.git")
local gitwatch = require("wraithvim.features.gitwatch")

vim.notify = function() end

describe("features.gitwatch", function()
  local dir, fired

  before_each(function()
    dir = gh.repo()
    env.write(dir .. "/README", "x\n")
    env.write(dir .. "/src/app/main.lua", "x\n")
    env.write(dir .. "/.gitignore", "node_modules/\n")
    env.write(dir .. "/node_modules/pkg/index.js", "x\n")
    gh.commit_all(dir, "init")
    gh.git(dir, "branch", "feature/login")
    -- Stand-in for neo-tree: count the refreshes the watcher asks for.
    fired = 0
    package.loaded["neo-tree"] = {}
    package.loaded["neo-tree.events"] = {
      GIT_EVENT = "git_event",
      fire_event = function()
        fired = fired + 1
      end,
    }
  end)

  after_each(function()
    gitwatch.stop()
    package.loaded["neo-tree"] = nil
    package.loaded["neo-tree.events"] = nil
    vim.fn.delete(dir, "rf")
  end)

  it("watches the Git directory, its refs and the working tree, not ignored folders", function()
    local f = assert(gitwatch.folders(dir))
    assert.is_true(vim.tbl_contains(f.git, dir .. "/.git"))
    assert.is_true(vim.tbl_contains(f.git, dir .. "/.git/refs/heads"))
    assert.is_true(vim.tbl_contains(f.git, dir .. "/.git/refs/heads/feature"))
    assert.is_true(vim.tbl_contains(f.tree, dir))
    assert.is_true(vim.tbl_contains(f.tree, dir .. "/src"))
    assert.is_true(vim.tbl_contains(f.tree, dir .. "/src/app"))
    assert.is_false(vim.tbl_contains(f.tree, dir .. "/node_modules"))
    assert.is_false(vim.tbl_contains(f.tree, dir .. "/node_modules/pkg"))
  end)

  it("watches new empty folders but not ignored ones inside them", function()
    vim.fn.mkdir(dir .. "/new/empty/deep", "p")
    vim.fn.mkdir(dir .. "/new/node_modules/x", "p")
    local f = assert(gitwatch.folders(dir))
    assert.is_true(vim.tbl_contains(f.tree, dir .. "/new"))
    assert.is_true(vim.tbl_contains(f.tree, dir .. "/new/empty/deep"))
    assert.is_false(vim.tbl_contains(f.tree, dir .. "/new/node_modules"))
    assert.is_false(vim.tbl_contains(f.tree, dir .. "/new/node_modules/x"))
  end)

  it("refreshes once after files are deleted from a shell", function()
    gitwatch.start(dir)
    assert.is_true(gitwatch.count() > 0)
    os.remove(dir .. "/src/app/main.lua")
    os.remove(dir .. "/README")
    assert.is_true(vim.wait(2000, function()
      return fired > 0
    end))
    vim.wait(300)
    assert.equals(1, fired)
  end)

  it("refreshes after a commit and watches folders created later", function()
    gitwatch.start(dir)
    env.write(dir .. "/README", "changed\n")
    gh.commit_all(dir, "second")
    assert.is_true(vim.wait(2000, function()
      return fired > 0
    end))
    vim.wait(300)
    fired = 0
    vim.fn.mkdir(dir .. "/docs")
    assert.is_true(vim.wait(2000, function()
      return fired > 0
    end))
    fired = 0
    env.write(dir .. "/docs/guide.md", "x\n")
    assert.is_true(vim.wait(2000, function()
      return fired > 0
    end))
  end)

  it("stops when no graph or changes view is open", function()
    gitwatch.start(dir)
    gitwatch.sync()
    assert.equals(0, gitwatch.count())
    assert.is_nil(gitwatch.root())
  end)
end)
