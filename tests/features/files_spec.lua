local env = require("tests.helpers.env")
local files = require("wraithvim.features.files")

vim.notify = function() end

describe("features.files", function()
  local dir, cwd

  before_each(function()
    cwd = vim.fn.getcwd()
    dir = vim.fs.normalize(vim.uv.fs_realpath(env.tmpdir("files")))
    vim.cmd.cd(vim.fn.fnameescape(dir))
    vim.cmd("silent! only | silent! %bwipeout!")
  end)

  after_each(function()
    vim.cmd.cd(vim.fn.fnameescape(cwd))
    vim.fn.delete(dir, "rf")
  end)

  it("creates files with missing parent folders, and folders with a trailing slash", function()
    local path = assert(files.create("src/api/routes.lua"))
    assert.equals(dir .. "/src/api/routes.lua", path)
    assert.equals("file", vim.uv.fs_stat(path).type)
    assert.equals("directory", vim.uv.fs_stat(assert(files.create("assets/img/"))).type)
    assert.equals("directory", vim.uv.fs_stat(assert(files.create("docs", true))).type)
  end)

  it("never overwrites an existing file and keeps special characters literal", function()
    env.write(dir .. "/keep.txt", "data\n")
    local path, err, existed = files.create("keep.txt")
    assert.is_nil(err)
    assert.is_true(existed)
    assert.equals("data\n", env.read(path))
    assert.is_nil((files.create("keep.txt/")))
    assert.equals("file", vim.uv.fs_stat(assert(files.create("100% * done.md"))).type)
    assert.is_nil((files.create("   ")))
  end)

  it("prompts with the current file's folder and opens the new file", function()
    env.write(dir .. "/lib/a.lua", "return 1\n")
    vim.cmd.edit("lib/a.lua")
    local default
    local real = vim.ui.input
    vim.ui.input = function(opts, cb)
      default = opts.default
      cb(opts.default .. "b.lua")
    end
    files.new_file()
    vim.ui.input = real
    assert.equals("lib/", default)
    assert.equals(dir .. "/lib/b.lua", vim.fs.normalize(vim.api.nvim_buf_get_name(0)))
    assert.equals("", files.display_dir(dir))
  end)
end)
