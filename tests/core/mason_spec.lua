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
    local langs = {}
    for _, name in ipairs(require("wraithvim.languages.registry").builtin) do
      langs[name] = name == "lua"
    end
    require("wraithvim.core.config").setup({ languages = langs })
    vim.env.PATH = vim.fn.tempname() -- nothing is installed
    utils.reset_executable_cache()
    local names = vim.tbl_map(function(t)
      return t.mason .. ":" .. t.kind
    end, mason.missing_tools())
    table.sort(names)
    assert.same({ "lua-language-server:language server", "stylua:formatter" }, names)
  end)

  it("refuses to install anything while Mason is disabled", function()
    local msgs = {}
    vim.notify = function(m)
      msgs[#msgs + 1] = m
    end
    package.loaded["wraithvim.core.config"] = nil
    require("wraithvim.core.config").setup({ options = { mason = { enabled = false } } })
    mason.install_missing()
    assert.matches("Mason is disabled", msgs[1])
    assert.is_nil(package.loaded["mason-registry"])
  end)

  it("knows which program each kind of Mason package needs", function()
    vim.env.PATH = vim.fn.tempname()
    utils.reset_executable_cache()
    assert.equals("Go", mason.missing_requirement("pkg:golang/golang.org/x/tools/gopls@v0.16"))
    assert.equals("Node.js (npm)", mason.missing_requirement("pkg:npm/vtsls@0.2"))
    assert.is_nil(mason.missing_requirement("pkg:github/LuaLS/lua-language-server@3"))
  end)

  describe("offer", function()
    local real_confirm, real_install, real_parsers, state_home
    local saved_state = vim.env.XDG_STATE_HOME
    local profile = {
      name = "go",
      description = "Go",
      filetypes = { "go" },
      parsers = {},
      servers = { gopls = { cmd = "gopls", mason = "gopls" } },
      formatters = {},
    }

    before_each(function()
      vim.notify = function() end
      package.loaded["wraithvim.core.config"] = nil
      require("wraithvim.core.config").setup()
      package.loaded["mason-registry"] = {
        has_package = function()
          return false
        end,
      }
      state_home = vim.fn.tempname()
      vim.env.XDG_STATE_HOME = state_home
      vim.env.PATH = vim.fn.tempname()
      utils.reset_executable_cache()
      real_confirm, real_install, real_parsers = vim.fn.confirm, mason.install, mason.missing_parsers
      mason.missing_parsers = function()
        return {}
      end
    end)

    after_each(function()
      vim.fn.confirm, mason.install, mason.missing_parsers = real_confirm, real_install, real_parsers
      package.loaded["mason-registry"] = nil
      package.loaded["wraithvim.languages"] = nil
      vim.fn.delete(state_home, "rf")
      vim.env.XDG_STATE_HOME = saved_state
    end)

    it("asks once, installs on yes and remembers never", function()
      local asked, installed = 0, nil
      vim.fn.confirm = function()
        asked = asked + 1
        return 1
      end
      mason.install = function(tools)
        installed = tools
      end
      mason.offer(profile, "ask")
      mason.offer(profile, "ask")
      assert.equals(1, asked)
      assert.equals("gopls", installed[1].mason)
      assert.equals("language server", installed[1].kind)

      local other = vim.tbl_extend("force", profile, { name = "go2" })
      vim.fn.confirm = function()
        return 3 -- Never
      end
      mason.offer(other, "ask")
      assert.is_true(mason.read_state().never.go2)
    end)
  end)
end)
