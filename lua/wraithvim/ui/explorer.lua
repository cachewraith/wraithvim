-- neo-tree configuration.

local M = {}

--- Single-click handler: open files / toggle directories, but only when the
--- click landed on a line of the tree itself. Releasing the mouse after
--- dragging a window separator must not open anything.
---@param state table neo-tree state
function M.click(state)
  local pos = vim.fn.getmousepos()
  if pos.winid ~= vim.api.nvim_get_current_win() or pos.line == 0 or pos.column == 0 then
    return
  end
  if pos.line ~= vim.api.nvim_win_get_cursor(0)[1] then
    return
  end
  state.commands.open(state)
end

---@return table neo-tree options
function M.opts()
  local config = require("wraithvim.core.config").get()
  local ui = config.ui
  local ex = ui.explorer
  local nerd = ui.icons.nerd_font
  local ic = require("wraithvim.ui.icons").get()

  local mappings = {
    ["l"] = "open",
    ["h"] = "close_node",
    -- Keep <Space> free for the leader key inside the tree.
    ["<space>"] = "none",
  }
  if ex.single_click then
    mappings["<LeftRelease>"] = M.click
    -- A double click would otherwise toggle a directory twice.
    mappings["<2-LeftMouse>"] = "none"
  end

  local git_symbols = nil
  if not nerd then
    git_symbols = {
      added = ic.git.added,
      modified = ic.git.modified,
      deleted = ic.git.removed,
      renamed = ic.git.renamed,
      untracked = ic.git.untracked,
      ignored = ic.git.ignored,
      unstaged = ic.git.unstaged,
      staged = ic.git.staged,
      conflict = ic.git.conflict,
    }
  end

  return {
    close_if_last_window = true,
    popup_border_style = ui.border == "none" and "single" or ui.border,
    enable_git_status = ex.git_status,
    enable_diagnostics = ex.diagnostics,
    sources = { "filesystem", "buffers", "git_status" },
    default_component_configs = {
      indent = { with_markers = true, with_expanders = nerd },
      icon = {
        folder_closed = ic.folder.closed,
        folder_open = ic.folder.open,
        folder_empty = ic.folder.empty,
        folder_empty_open = ic.folder.empty_open,
        default = ic.file,
      },
      modified = { symbol = nerd and "●" or "[+]" },
      git_status = git_symbols and { symbols = git_symbols } or nil,
    },
    window = {
      position = ex.position,
      width = ex.width,
      mappings = mappings,
    },
    filesystem = {
      filtered_items = {
        visible = false,
        hide_dotfiles = not ex.show_hidden,
        hide_gitignored = true,
        hide_by_name = ex.hide,
      },
      follow_current_file = { enabled = true },
      -- No filesystem watchers: the tree refreshes on writes and focus.
      use_libuv_file_watcher = false,
      hijack_netrw_behavior = "open_current",
    },
  }
end

return M
