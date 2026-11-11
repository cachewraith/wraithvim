local env = require("tests.helpers.env")
local gh = require("tests.helpers.git")
local update = require("wraithvim.core.update")

local messages, answers = {}, {}
vim.notify = function(msg, level)
  messages[#messages + 1] = { msg = msg, level = level }
end
vim.fn.confirm = function()
  return table.remove(answers, 1) or 2
end

local function said(pattern)
  for _, m in ipairs(messages) do
    if m.msg:find(pattern) then
      return true
    end
  end
  return false
end

local function head(dir)
  return vim.trim(gh.git(dir, "rev-parse", "HEAD").stdout)
end

describe(":WraithUpdate", function()
  local upstream, checkout

  before_each(function()
    messages, answers = {}, {}
    upstream = gh.repo()
    env.write(upstream .. "/init.lua", "-- v1\n")
    env.write(upstream .. "/lazy-lock.json", "{}\n")
    gh.commit_all(upstream, "v1")
    checkout = env.tmpdir("checkout") .. "/wraithvim"
    assert.equals(0, vim.system({ "git", "clone", "-q", upstream, checkout }):wait().code)
    vim.g.wraithvim_root = checkout
    env.write(upstream .. "/init.lua", "-- v2\n")
    gh.commit_all(upstream, "v2")
  end)

  after_each(function()
    vim.g.wraithvim_root = env.root
    vim.fn.delete(upstream, "rf")
    vim.fn.delete(vim.fs.dirname(checkout), "rf")
  end)

  it("fast-forwards a clean checkout", function()
    update.run()
    assert.is_true(vim.wait(10000, function()
      return head(checkout) == head(upstream)
    end, 50))
    assert.equals("-- v2\n", env.read(checkout .. "/init.lua"))
    -- Wait for the async completion message so it cannot leak into the next test.
    assert.is_true(vim.wait(5000, function()
      return said("Restart Neovim")
    end, 20))
  end)

  it("refuses to update a checkout with local modifications", function()
    env.write(checkout .. "/init.lua", "-- my edit\n")
    local before = head(checkout)
    update.run()
    vim.wait(500)
    assert.equals(before, head(checkout))
    assert.equals("-- my edit\n", env.read(checkout .. "/init.lua"))
    assert.is_true(said("local modifications"), vim.inspect(messages))
    assert.is_false(said("Fetching"))
  end)

  it("offers to reset a lockfile changed by :Lazy update, and stops if declined", function()
    env.write(checkout .. "/lazy-lock.json", '{ "x": 1 }\n')
    local before = head(checkout)
    answers = { 2 } -- Cancel
    update.run()
    vim.wait(300)
    assert.equals(before, head(checkout))
    assert.equals('{ "x": 1 }\n', env.read(checkout .. "/lazy-lock.json"))

    answers = { 1 } -- Reset
    update.run()
    assert.is_true(vim.wait(10000, function()
      return head(checkout) == head(upstream)
    end, 50))
    assert.equals("{}\n", env.read(checkout .. "/lazy-lock.json"))
    assert.is_true(vim.wait(5000, function()
      return said("Restart Neovim")
    end, 20))
  end)

  it("does not try to update a checkout pinned to a release tag", function()
    gh.git(checkout, "tag", "v0.0.1")
    gh.git(checkout, "checkout", "-q", "v0.0.1")
    local before = head(checkout)
    update.run()
    vim.wait(300)
    assert.equals(before, head(checkout))
    assert.is_true(said("pinned to v0.0.1"), vim.inspect(messages))
    assert.is_false(said("Fetching"))
  end)

  it("explains when the installation is not a Git checkout", function()
    vim.g.wraithvim_root = env.tmpdir("plain")
    update.run()
    assert.is_true(said("not a Git checkout"))
  end)
end)
