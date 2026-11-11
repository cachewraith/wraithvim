describe("ui.notifications", function()
  local notifications

  before_each(function()
    package.loaded["wraithvim.ui.notifications"] = nil
    notifications = require("wraithvim.ui.notifications")
  end)

  it("wraps long lines and truncates very long messages", function()
    local lines = notifications.wrap(string.rep("x", 25), 10)
    assert.same({ "xxxxxxxxxx", "xxxxxxxxxx", "xxxxx" }, lines)
    local many = notifications.wrap(string.rep("line\n", 20), 60)
    assert.equals(11, #many)
    assert.matches("WraithNotifications", many[11])
  end)

  it("records history and falls back to the original notify without a UI", function()
    local received = {}
    vim.notify = function(msg, level)
      received[#received + 1] = { msg, level }
    end
    notifications.setup({ timeout = 100, max_width = 40, level = vim.log.levels.INFO })
    vim.notify("hello", vim.log.levels.WARN, { title = "T" })
    vim.notify("debug noise", vim.log.levels.DEBUG)
    assert.equals(2, #notifications.history)
    assert.equals("T", notifications.history[1].title)
    -- Headless: shown through the original function; DEBUG is below the threshold.
    assert.same({ { "hello", vim.log.levels.WARN } }, received)
  end)

  it("caps history at 100 entries", function()
    vim.notify = function() end
    notifications.setup({ timeout = 100, max_width = 40, level = vim.log.levels.ERROR })
    for i = 1, 120 do
      vim.notify("n" .. i)
    end
    assert.equals(100, #notifications.history)
    assert.equals("n21", notifications.history[1].msg)
  end)

  it("shows history in a scratch buffer", function()
    vim.notify = function() end
    notifications.setup({ timeout = 100, max_width = 40, level = vim.log.levels.INFO })
    vim.notify("remember me")
    notifications.show_history()
    assert.equals("wraithnotifications", vim.bo.filetype)
    assert.matches("remember me", table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"))
  end)
end)
