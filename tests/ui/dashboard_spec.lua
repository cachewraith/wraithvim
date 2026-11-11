describe("ui.dashboard", function()
  local dashboard = require("wraithvim.ui.dashboard")

  before_each(function()
    vim.notify = function() end
    require("wraithvim.core.config").setup()
    vim.cmd("silent! %bwipeout!")
  end)

  it("opens on an empty start and renders every item", function()
    assert.is_true(dashboard.should_open())
    dashboard.open()
    assert.equals(dashboard.filetype, vim.bo.filetype)
    assert.equals("nofile", vim.bo.buftype)
    assert.is_false(vim.bo.modifiable)
    local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    for _, item in ipairs(dashboard.items()) do
      assert.is_truthy(text:find(item.label, 1, true), item.label)
      assert.is_not.equal("", vim.fn.maparg(item.key, "n"))
    end
    assert.is_not.equal("", vim.fn.maparg("<LeftRelease>", "n"))
  end)

  it("runs the item under the cursor with <CR> semantics", function()
    dashboard.open()
    local row
    for i, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
      if line:find("New file", 1, true) then
        row = i
      end
    end
    vim.api.nvim_win_set_cursor(0, { row, 0 })
    dashboard.activate(false)
    assert.equals("", vim.bo.buftype) -- :enew replaced the dashboard
    assert.is_not.equal(dashboard.filetype, vim.bo.filetype)
  end)

  it("does not open when the buffer has content", function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "text" })
    assert.is_false(dashboard.should_open())
  end)
end)
