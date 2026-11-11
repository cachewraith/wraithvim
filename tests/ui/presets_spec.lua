describe("ui presets", function()
  local defaults = require("wraithvim.config.defaults")
  local config = require("wraithvim.core.config")

  for _, name in ipairs({ "default", "compact", "minimal" }) do
    it(name .. " only uses known UI options with the right types", function()
      local preset = require("wraithvim.ui.presets." .. name)
      local problems = {}
      config.validate(preset, defaults.ui, "ui", problems)
      assert.same({}, problems)
    end)
  end

  it("minimal turns optional panels off but keeps them available", function()
    vim.notify = function() end
    local cfg = config.setup({ ui = { preset = "minimal" } })
    assert.is_false(cfg.ui.tabline.enabled)
    assert.is_false(cfg.ui.dashboard.enabled)
    assert.is_true(cfg.ui.explorer.enabled)
    assert.is_true(cfg.ui.terminal.enabled)
  end)
end)
