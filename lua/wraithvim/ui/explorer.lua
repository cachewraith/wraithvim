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

-- VS Code's git decoration colors (gitDecoration.* in Dark+ / Light+).
M.git_colors = {
  dark = {
    untracked = "#73c991",
    added = "#81b88b",
    modified = "#e2c08d",
    deleted = "#c74e39",
    conflict = "#e4676b",
    ignored = "#8c8c8c",
  },
  light = {
    untracked = "#007100",
    added = "#587c0c",
    modified = "#895503",
    deleted = "#ad0707",
    conflict = "#ad0707",
    ignored = "#8e8e90",
  },
}

-- neo-tree highlight group -> M.git_colors key.
local git_groups = {
  NeoTreeGitUntracked = "untracked",
  NeoTreeGitAdded = "added",
  NeoTreeGitStaged = "added",
  NeoTreeGitRenamed = "untracked",
  NeoTreeGitModified = "modified",
  NeoTreeGitUnstaged = "modified",
  NeoTreeGitDeleted = "deleted",
  NeoTreeGitConflict = "conflict",
  NeoTreeGitIgnored = "ignored",
}

--- Color the explorer's git status like VS Code. Not `default`: colorschemes
--- style these groups themselves (tokyonight makes new files purple), and
--- `ui.colors` is applied afterwards, so user overrides still win.
function M.define_highlights()
  local colors = M.git_colors[vim.o.background] or M.git_colors.dark
  for group, key in pairs(git_groups) do
    vim.api.nvim_set_hl(0, group, { fg = colors[key] })
  end
end

-- Change letter -> VS Code letter and highlight group.
local decorations = {
  M = { "M", "NeoTreeGitModified" },
  T = { "M", "NeoTreeGitModified" },
  A = { "A", "NeoTreeGitAdded" },
  C = { "A", "NeoTreeGitAdded" },
  D = { "D", "NeoTreeGitDeleted" },
  R = { "R", "NeoTreeGitRenamed" },
}

--- VS Code letter and highlight group for a neo-tree git status code: "?"
--- (untracked), "!" (ignored), a porcelain "XY" pair with "." for unchanged,
--- or the single letter neo-tree bubbles up to folders ("U" = conflict).
---@param status string
---@return string? letter, string? highlight
function M.git_decoration(status)
  if status == "?" then
    return "U", "NeoTreeGitUntracked"
  elseif status == "!" then
    return "", "NeoTreeGitIgnored"
  end
  local x, y = status:sub(1, 1), status:sub(2, 2)
  if x == "U" or y == "U" or (x == y and (x == "A" or x == "D")) then
    return "C", "NeoTreeGitConflict"
  end
  -- The working tree change wins, except that a staged new file stays new.
  local change = (y ~= "" and y ~= "." and x ~= "A") and y or x
  local d = decorations[change]
  if d then
    return d[1], d[2]
  end
end

--- neo-tree `git_status` component, VS Code style: a letter after changed
--- files (U, M, A, D, R, C) and a dot after folders holding changes, in the
--- color the file name takes too (`name.use_git_status_colors`).
---@param node table neo-tree node
---@param state table neo-tree state
function M.git_status(_, node, state)
  if node.type ~= "file" and node.type ~= "directory" then
    return {}
  end
  local status = require("neo-tree.git").find_existing_status_code(node.path, state.git_base_by_worktree)
  if type(status) == "table" then
    status = status[1]
  end
  if not status then
    return {}
  end
  local letter, group = M.git_decoration(status)
  if not letter then
    return {}
  end
  if node.type == "directory" and letter ~= "" then
    letter = "●"
  end
  return { text = letter == "" and "" or letter .. " ", highlight = group }
end

---@return table neo-tree options
function M.opts()
  local config = require("wraithvim.core.config").get()
  local ui = config.ui
  local ex = ui.explorer
  local nerd = ui.icons.nerd_font
  local components = { git_status = M.git_status }
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

  local event_handlers = {
    {
      event = "neo_tree_window_after_open",
      handler = function(args)
        local win = args and args.winid
        if ex.header and win and vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_config(win).relative == "" then
          vim.wo[win].winbar = "%{%v:lua.require'wraithvim.features.files'.header()%}"
        end
      end,
    },
  }
  -- Files deleted, created or renamed in the explorer (or on disk, seen by
  -- its watcher) leave or join the side panel's changes view right away.
  for _, event in ipairs({ "file_added", "file_deleted", "file_moved", "file_renamed", "fs_event" }) do
    event_handlers[#event_handlers + 1] = {
      event = event,
      handler = function()
        require("wraithvim.features.panels").refresh_changes()
      end,
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
    },
    event_handlers = event_handlers,
    window = {
      position = ex.position,
      width = ex.width,
      mappings = mappings,
    },
    -- The side panel's "changes" view (wraithvim.features.panels).
    git_status = {
      components = components,
      window = {
        width = ui.side_panel.width,
        mappings = {
          ["d"] = {
            function(state)
              local node = state.tree:get_node()
              if node and node.type == "file" then
                require("wraithvim.features.panels").diff_file(node.path)
              end
            end,
            desc = "Diff this file",
          },
        },
      },
    },
    buffers = { components = components },
    filesystem = {
      components = components,
      filtered_items = {
        visible = false,
        hide_dotfiles = not ex.show_hidden,
        hide_gitignored = not ex.show_gitignored,
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
