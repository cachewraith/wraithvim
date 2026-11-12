local env = require("tests.helpers.env")

describe("config.commands", function()
  local commands = require("wraithvim.config.commands")

  it("creates every WraithVim command", function()
    commands.setup()
    local existing = vim.api.nvim_get_commands({})
    for name in pairs(commands.definitions()) do
      assert.is_truthy(existing[name], name .. " was not created")
      assert.matches("^%u%w*$", name) -- user commands must start with an uppercase letter
    end
  end)

  it("completes only arguments that start with what was typed", function()
    commands.setup()
    assert.same({ "float" }, vim.fn.getcompletion("Terminal fl", "cmdline"))
    assert.same({ "theirs" }, vim.fn.getcompletion("ConflictChoose th", "cmdline"))
    assert.same({ "graph" }, vim.fn.getcompletion("SidePanel gr", "cmdline"))
  end)

  it("documents every command in the README", function()
    local readme = env.read(env.root .. "/README.md")
    for name in pairs(commands.definitions()) do
      assert.is_truthy(readme:find(":" .. name, 1, true), name .. " missing from README.md")
    end
  end)
end)
