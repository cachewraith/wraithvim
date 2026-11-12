-- bufferline configuration: clickable buffer tabs plus a right-hand header
-- showing the project name and Git branch.

local M = {}

--- Header segments shown on the right of the tabline. Called on every tabline
--- redraw, so it only reads cached values.
---@return table[]
function M.header()
  local ic = require("wraithvim.ui.icons").get()
  -- Folder and branch names may contain "%", which the tabline would read as
  -- an item ("100%d" is an error).
  local function esc(s)
    return (s:gsub("%%", "%%%%"))
  end
  local project = esc(vim.fs.basename(vim.fn.getcwd()))
  local head = vim.b.gitsigns_head
  if not head or head == "" then
    head = vim.g.gitsigns_head
  end
  head = head and esc(head)
  local items = { { text = " " .. project .. " ", link = "Title" } }
  if head and head ~= "" then
    local prefix = ic.git.branch ~= "" and (ic.git.branch .. " ") or "git:"
    items[#items + 1] = { text = " " .. prefix .. head .. " ", link = "Special" }
  end
  return items
end

---@return table bufferline options
function M.opts()
  local config = require("wraithvim.core.config").get()
  local ui = config.ui
  local tl = ui.tabline
  local nerd = ui.icons.nerd_font
  local ic = require("wraithvim.ui.icons").get()
  local buffers = require("wraithvim.features.buffers")

  local function close(n)
    buffers.delete(n)
  end

  if tl.header then
    -- Branch changes are reported by gitsigns; redraw the header then.
    vim.api.nvim_create_autocmd("User", {
      group = require("wraithvim.core.utils").augroup("tabline_header"),
      pattern = "GitSignsUpdate",
      callback = function()
        vim.cmd.redrawtabline()
      end,
    })
  end

  return {
    options = {
      mode = "buffers",
      close_command = close,
      middle_mouse_command = close,
      right_mouse_command = function() end,
      left_mouse_command = "buffer %d",
      buffer_close_icon = ic.close,
      close_icon = ic.close,
      modified_icon = ic.modified,
      left_trunc_marker = ic.trunc_left,
      right_trunc_marker = ic.trunc_right,
      show_buffer_icons = nerd,
      show_buffer_close_icons = tl.close_icons,
      show_close_icon = false,
      diagnostics = tl.diagnostics and "nvim_lsp" or false,
      always_show_bufferline = tl.always_show,
      separator_style = "thin",
      hover = { enabled = false },
      offsets = {
        {
          filetype = "neo-tree",
          text = "WraithVim",
          highlight = "Directory",
          text_align = "left",
          separator = true,
        },
      },
      custom_areas = tl.header and { right = M.header } or nil,
    },
  }
end

return M
