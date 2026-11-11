local terminal = require("wraithvim.features.terminal")

vim.notify = function() end

local function job_running(buf)
  local job = vim.b[buf].terminal_job_id
  return job ~= nil and vim.fn.jobwait({ job }, 0)[1] == -1
end

describe("features.terminal", function()
  before_each(function()
    package.loaded["wraithvim.core.config"] = nil
    require("wraithvim.core.config").setup()
    vim.o.shell = "sh"
  end)

  after_each(function()
    terminal.close()
    vim.cmd("stopinsert | silent! only!")
  end)

  it("toggles one reusable panel terminal without restarting the shell", function()
    terminal.toggle()
    local buf = terminal.panel.buf
    assert.is_not_nil(buf)
    assert.equals("terminal", vim.bo[buf].buftype)
    assert.is_false(vim.bo[buf].buflisted)
    assert.is_true(job_running(buf))
    assert.equals(12, vim.api.nvim_win_get_height(terminal.panel.win))

    terminal.toggle() -- hide
    assert.equals(-1, vim.fn.bufwinid(buf))
    assert.is_true(vim.api.nvim_buf_is_valid(buf))
    assert.is_true(job_running(buf))

    terminal.toggle() -- show again: same buffer, same process
    assert.equals(buf, terminal.panel.buf)
    assert.is_not.equal(-1, vim.fn.bufwinid(buf))
  end)

  it("open() puts the terminal back when its window shows another buffer", function()
    terminal.open()
    local buf, win = terminal.panel.buf, terminal.panel.win
    vim.cmd("stopinsert")
    vim.api.nvim_win_set_buf(win, vim.api.nvim_create_buf(true, false))
    terminal.open("bottom")
    assert.equals(win, terminal.panel.win)
    assert.equals(buf, vim.api.nvim_win_get_buf(win))
    assert.equals(win, vim.api.nvim_get_current_win())
  end)

  it("starts in the current working directory", function()
    local dir = vim.fn.tempname()
    vim.fn.mkdir(dir, "p")
    vim.cmd.cd(dir)
    terminal.open()
    local job = vim.b[terminal.panel.buf].terminal_job_id
    local pid = vim.fn.jobpid(job)
    vim.wait(1000, function()
      return vim.uv.fs_readlink("/proc/" .. pid .. "/cwd") ~= nil
    end)
    assert.equals(vim.uv.fs_realpath(dir), vim.uv.fs_readlink("/proc/" .. pid .. "/cwd"))
    vim.cmd.cd("-")
  end)

  it("opens independent split terminals", function()
    terminal.open()
    local panel = terminal.panel.buf
    local split = terminal.split("vertical")
    assert.is_not.equal(panel, split)
    assert.is_true(job_running(split))
    vim.fn.jobstop(vim.b[split].terminal_job_id)
  end)

  it("close stops the shell and removes the buffer", function()
    terminal.open()
    local buf = terminal.panel.buf
    terminal.close()
    assert.is_false(vim.api.nvim_buf_is_valid(buf))
    assert.is_nil(terminal.panel.buf)
  end)

  it("wipes the buffer when the shell exits", function()
    terminal.open()
    local buf = terminal.panel.buf
    vim.fn.chansend(vim.b[buf].terminal_job_id, "exit\n")
    assert.is_true(vim.wait(3000, function()
      return not vim.api.nvim_buf_is_valid(buf)
    end))
    assert.is_nil(terminal.panel.buf)
  end)
end)
