local panels = require("wraithvim.features.panels")
local terminal = require("wraithvim.features.terminal")

vim.notify = function() end

describe("features.panels", function()
  before_each(function()
    package.loaded["wraithvim.core.config"] = nil
    require("wraithvim.core.config").setup()
    require("wraithvim.config.autocmds").setup(require("wraithvim.core.config").get())
    vim.o.shell = "sh"
    panels.state = {}
  end)

  after_each(function()
    terminal.close()
    vim.cmd("stopinsert | silent! only!")
  end)

  it("shows the terminal in the side panel, on the right by default", function()
    panels.open("terminal")
    local v = assert(panels.visible())
    assert.equals("terminal", v.view)
    assert.equals("right", terminal.panel.position)
    assert.equals(vim.o.columns, vim.fn.win_screenpos(v.win)[2] + vim.api.nvim_win_get_width(v.win) - 1)
    assert.is_true(vim.api.nvim_win_get_width(v.win) <= math.floor(vim.o.columns * 0.45))
  end)

  it("hides and brings back the last view, keeping the shell", function()
    panels.open("terminal")
    local buf = terminal.panel.buf
    panels.toggle()
    assert.is_nil(panels.visible())
    assert.is_true(vim.api.nvim_buf_is_valid(buf))
    panels.toggle()
    assert.equals("terminal", panels.visible().view)
    assert.equals(buf, terminal.panel.buf)
  end)

  it("moves to the other side", function()
    panels.open("terminal")
    panels.move()
    assert.equals("left", terminal.panel.position)
    assert.equals(1, vim.fn.win_screenpos(panels.visible().win)[2])
    panels.move()
    assert.equals("right", terminal.panel.position)
  end)

  it("does not count the bottom terminal as a side panel", function()
    terminal.open("bottom")
    assert.is_nil(panels.visible())
  end)

  it("goes back to the last code window, from a terminal too", function()
    vim.cmd("vsplit")
    local code = vim.api.nvim_get_current_win()
    vim.cmd("wincmd p")
    vim.cmd("wincmd p") -- `code` is now the last code window entered
    panels.focus_terminal()
    assert.equals("terminal", vim.bo.buftype)
    panels.focus_code()
    assert.equals(code, vim.api.nvim_get_current_win())
  end)

  it("focuses a visible side panel and opens a hidden one", function()
    panels.focus_side() -- nothing shown yet: "changes", which needs neo-tree (not set up here)
    assert.is_nil(panels.visible())
    panels.open("terminal")
    panels.focus_code()
    panels.focus_side()
    assert.equals(terminal.panel.win, vim.api.nvim_get_current_win())
  end)
end)
