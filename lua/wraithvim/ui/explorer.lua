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

--- Move the cursor to the next (`dir` = 1) or previous (-1) folder line.
---@param state table neo-tree state
---@param dir integer
function M.jump_folder(state, dir)
  local win = vim.api.nvim_get_current_win()
  local last = vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(win))
  local line = vim.api.nvim_win_get_cursor(win)[1] + dir
  while line >= 1 and line <= last do
    local ok, node = pcall(state.tree.get_node, state.tree, line)
    if ok and node and node.type == "directory" then
      vim.api.nvim_win_set_cursor(win, { line, 0 })
      return
    end
    line = line + dir
  end
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
    -- New file / folder in the folder under the cursor; the prompt shows it.
    ["a"] = {
      function(state)
        local files = require("wraithvim.features.files")
        files.new_file(files.folder_at(state))
      end,
      desc = "New file",
    },
    ["A"] = {
      function(state)
        local files = require("wraithvim.features.files")
        files.new_folder(files.folder_at(state))
      end,
      desc = "New folder",
    },
    ["}"] = {
      function(state)
        M.jump_folder(state, 1)
      end,
      desc = "Next folder",
    },
    ["{"] = {
      function(state)
        M.jump_folder(state, -1)
      end,
      desc = "Previous folder",
    },
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
        -- Material Icon Theme style: folder icons and colors by name.
        provider = nerd and require("wraithvim.ui.material").provider or nil,
      },
      modified = { symbol = nerd and "●" or "[+]" },
      git_status = git_symbols and { symbols = git_symbols } or nil,
    },
    event_handlers = {
      {
        event = "neo_tree_window_after_open",
        handler = function(args)
          local win = args and args.winid
          if
            ex.header
            and win
            and vim.api.nvim_win_is_valid(win)
            and vim.api.nvim_win_get_config(win).relative == ""
          then
            vim.wo[win].winbar = "%{%v:lua.require'wraithvim.features.files'.header()%}"
          end
        end,
      },
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
      -- inotify watches on the folders shown (no polling).
      use_libuv_file_watcher = ex.watch,
      hijack_netrw_behavior = "open_current",
    },
  }
end

return M
