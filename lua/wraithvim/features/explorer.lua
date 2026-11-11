-- Explorer commands on top of neo-tree.

local M = {}

---@param args table neo-tree command arguments
local function execute(args)
  local ui = require("wraithvim.core.config").get().ui
  args.position = args.position or ui.explorer.position
  args.dir = args.dir or vim.fn.getcwd()
  require("neo-tree.command").execute(args)
end

function M.toggle()
  execute({ toggle = true, source = "filesystem" })
end

function M.focus()
  execute({ action = "focus", source = "filesystem" })
end

--- Reveal the current file in the tree.
function M.reveal()
  execute({ action = "focus", source = "filesystem", reveal = true })
end

function M.git_status()
  execute({ action = "focus", source = "git_status" })
end

function M.buffers()
  execute({ action = "focus", source = "buffers" })
end

--- Resize the explorer window by `delta` columns (keyboard alternative to
--- dragging the separator).
---@param delta integer
function M.resize(delta)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "neo-tree" then
      vim.api.nvim_win_set_width(win, math.max(10, vim.api.nvim_win_get_width(win) + delta))
      return
    end
  end
end

--- Show the explorer without taking focus.
---
--- neo-tree's "show" scans the directory asynchronously, then hops back to
--- the window that was current when it *started*. If the user moved meanwhile
--- (e.g. opened the terminal right after startup), that hop would pull them
--- out. neo-tree fires "after_render" just before the hop, while focus is
--- still where the user put it: remember that window and restore it after.
function M.show_keeping_focus()
  require("neo-tree.events").subscribe({
    event = "after_render",
    id = "wraithvim_keep_focus",
    once = true,
    handler = function()
      local win = vim.api.nvim_get_current_win()
      local terminal_mode = vim.api.nvim_get_mode().mode == "t"
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) and vim.api.nvim_get_current_win() ~= win then
          vim.api.nvim_set_current_win(win)
        end
        if terminal_mode and vim.bo.buftype == "terminal" then
          vim.cmd.startinsert()
        end
      end)
    end,
  })
  execute({ action = "show", source = "filesystem" })
end

--- Show the explorer (without focusing it) after startup when files or a
--- directory were given on the command line.
function M.setup_auto_open()
  vim.api.nvim_create_autocmd("User", {
    group = require("wraithvim.core.utils").augroup("explorer_auto_open"),
    pattern = "VeryLazy",
    once = true,
    callback = function()
      if vim.fn.argc(-1) == 0 or vim.g.wraithvim_stdin then
        return
      end
      -- A directory argument is already handled by neo-tree's netrw hijack.
      if vim.bo.filetype == "neo-tree" then
        return
      end
      -- Skip tiny terminals where a side panel would crowd the editor.
      if vim.o.columns < 100 then
        return
      end
      M.show_keeping_focus()
    end,
  })
end

return M
