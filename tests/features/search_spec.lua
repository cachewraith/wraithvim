local env = require("tests.helpers.env")
local gh = require("tests.helpers.git")

local function setup_config(overrides)
  vim.notify = function() end
  package.loaded["wraithvim.core.config"] = nil
  return require("wraithvim.core.config").setup(overrides)
end

--- Files listed by `cmd` run in `dir`, sorted, with "./" stripped.
local function list(cmd, dir)
  local res = vim.system(cmd, { cwd = dir, text = true }):wait()
  local out = {}
  for _, l in ipairs(vim.split(res.stdout or "", "\n", { trimempty = true })) do
    out[#out + 1] = (l:gsub("^%./", ""))
  end
  table.sort(out)
  return out
end

describe("features.search", function()
  local search = require("wraithvim.features.search")
  local dir

  before_each(function()
    dir = gh.repo()
    env.write(dir .. "/.gitignore", "dist/\n.env\n")
    env.write(dir .. "/app.lua", "needle in app\n")
    env.write(dir .. "/.env", "needle in env\n")
    env.write(dir .. "/dist/out.js", "needle in dist\n")
    env.write(dir .. "/node_modules/pkg/index.js", "needle in deps\n")
    gh.commit_all(dir, "init")
  end)

  after_each(function()
    vim.fn.delete(dir, "rf")
  end)

  it("searches everything the explorer shows except .git and node_modules", function()
    setup_config()
    local scope = search.scope()
    assert.is_true(scope.hidden)
    assert.is_true(scope.ignored)
    assert.same({ ".git", "node_modules" }, scope.exclude)
    local expected = { ".env", ".gitignore", "app.lua", "dist/out.js" }
    if vim.fn.executable("fd") == 1 or vim.fn.executable("fdfind") == 1 or vim.fn.executable("rg") == 1 then
      assert.same(expected, list(search.find_command(), dir))
    end
    if vim.fn.executable("rg") == 1 then
      local cmd = vim.list_extend(search.grep_command(), { "needle" })
      local files = {}
      for _, l in ipairs(list(cmd, dir)) do
        files[#files + 1] = l:match("^([^:]+)")
      end
      assert.same({ ".env", "app.lua", "dist/out.js" }, files)
    end
  end)

  it("follows the explorer settings and the exclude list", function()
    setup_config({
      ui = { explorer = { show_gitignored = false, show_hidden = false } },
      options = { search = { exclude = { ".git" } } },
    })
    local scope = search.scope()
    assert.is_false(scope.ignored)
    local cmd = search.find_command()
    assert.is_false(vim.tbl_contains(cmd, "--no-ignore-vcs"))
    assert.is_false(vim.tbl_contains(cmd, "--hidden"))
    if vim.fn.executable("fd") == 1 or vim.fn.executable("rg") == 1 then
      assert.same({ "app.lua", "node_modules/pkg/index.js" }, list(cmd, dir))
    end
  end)
end)
