local mason = require("wraithvim.integrations.mason")
local utils = require("wraithvim.core.utils")

describe("integrations.mason", function()
  local saved_path = vim.env.PATH

  after_each(function()
    vim.env.PATH = saved_path
    utils.reset_executable_cache()
  end)

  it("appends Mason's bin directory once, after system paths", function()
    vim.env.PATH = "/usr/bin:/bin"
    mason.add_to_path()
    mason.add_to_path()
    assert.equals("/usr/bin:/bin:" .. mason.bin_dir(), vim.env.PATH)
  end)

  it("lists missing tools of enabled languages with their Mason package", function()
    vim.notify = function() end
    package.loaded["wraithvim.core.config"] = nil
    require("wraithvim.languages").reset()
    require("wraithvim.core.config").setup({
      languages = {
        bash = false,
        cpp = false,
        go = false,
        java = false,
        php = false,
        python = false,
        sql = false,
        typescript = false,
        yaml = false,
      },
    })
    vim.env.PATH = vim.fn.tempname() -- nothing is installed
    utils.reset_executable_cache()
    local names = vim.tbl_map(function(t)
      return t.mason .. ":" .. t.kind
    end, mason.missing_tools())
    table.sort(names)
    assert.same({ "lua-language-server:LSP", "stylua:formatter" }, names)
  end)

  it("refuses to install anything while Mason is disabled", function()
    local msgs = {}
    vim.notify = function(m)
      msgs[#msgs + 1] = m
    end
    package.loaded["wraithvim.core.config"] = nil
    require("wraithvim.core.config").setup()
    mason.install_missing()
    assert.matches("Mason is disabled", msgs[1])
    assert.is_nil(package.loaded["mason-registry"])
  end)
end)
