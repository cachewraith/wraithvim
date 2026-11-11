local env = require("tests.helpers.env")

describe("config.commands", function()
  local commands = require("wraithvim.config.commands")

  it("creates every :Wraith command", function()
    commands.setup()
    local existing = vim.api.nvim_get_commands({})
    for name in pairs(commands.definitions()) do
      assert.is_truthy(existing[name], name .. " was not created")
      assert.matches("^Wraith", name)
    end
  end)

  it("documents every command in the README", function()
    local readme = env.read(env.root .. "/README.md")
    for name in pairs(commands.definitions()) do
      assert.is_truthy(readme:find(":" .. name, 1, true), name .. " missing from README.md")
    end
  end)
end)
