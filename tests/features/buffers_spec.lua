local buffers = require("wraithvim.features.buffers")

vim.notify = function() end

local answer = 3
vim.fn.confirm = function()
  return answer
end

local function listed()
  return vim.tbl_filter(function(b)
    return vim.bo[b].buflisted
  end, vim.api.nvim_list_bufs())
end

describe("features.buffers", function()
  before_each(function()
    vim.cmd("silent! only | silent! %bwipeout!")
  end)

  it("deletes a buffer while keeping the window layout", function()
    vim.cmd("edit one | edit two | vsplit")
    local two = vim.api.nvim_get_current_buf()
    assert.equals(2, #vim.api.nvim_tabpage_list_wins(0))
    assert.is_true(buffers.delete(two))
    assert.equals(2, #vim.api.nvim_tabpage_list_wins(0))
    assert.is_false(vim.api.nvim_buf_is_valid(two))
    assert.equals("one", vim.fn.expand("%:t"))
  end)

  it("asks before discarding changes", function()
    vim.cmd("edit modified")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "changed" })
    local buf = vim.api.nvim_get_current_buf()
    answer = 3 -- Cancel
    assert.is_false(buffers.delete(buf))
    assert.is_true(vim.api.nvim_buf_is_valid(buf))
    answer = 2 -- Discard
    assert.is_true(buffers.delete(buf))
    assert.is_false(vim.api.nvim_buf_is_valid(buf))
  end)

  it("cleans up hidden, unmodified buffers only", function()
    vim.cmd("edit a | edit b | edit c")
    vim.cmd("edit d")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "dirty" })
    vim.cmd("hide edit e")
    -- a, b, c hidden & clean; d hidden & modified; e visible
    assert.equals(3, buffers.cleanup())
    local names = vim.tbl_map(function(b)
      return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(b), ":t")
    end, listed())
    table.sort(names)
    assert.same({ "d", "e" }, names)
  end)

  it("closes other unmodified buffers", function()
    vim.cmd("edit a | edit b | edit c")
    assert.equals(2, buffers.close_others())
    assert.equals(1, #listed())
  end)
end)
