-- User commands (:Update, :Health, :Terminal, ...). Implementations are
-- required lazily. Names are short and free of a prefix; they must not clash
-- with Neovim or bundled plugin commands (tested).

local M = {}

---@param mod string
---@param fn string
---@param ... any
local function call(mod, fn, ...)
  local args = { ... }
  return function()
    require(mod)[fn](unpack(args))
  end
end

--- The words that start with what has been typed. Neovim does not filter what
--- a Lua `complete` function returns.
---@param lead string
---@param words string[]
---@return string[]
local function matching(lead, words)
  return vim.tbl_filter(function(w)
    return vim.startswith(w, lead)
  end, words)
end

--- Command definitions: name -> { fn, opts }.
---@return table<string, { [1]: function, [2]: table }>
function M.definitions()
  local g = "wraithvim.features.git"
  local c = "wraithvim.features.conflicts"
  local t = "wraithvim.features.terminal"
  return {
    Health = {
      function()
        vim.cmd("checkhealth wraithvim")
      end,
      { desc = "Run WraithVim health checks" },
    },
    Update = { call("wraithvim.core.update", "run"), { desc = "Update WraithVim and sync pinned plugins" } },
    Log = { call("wraithvim.core.logger", "open"), { desc = "Open the WraithVim log" } },
    Profile = { call("wraithvim.core.performance", "profile"), { desc = "Show plugin load profile" } },
    Benchmark = {
      function(o)
        require("wraithvim.core.performance").benchmark(o.fargs)
      end,
      { nargs = "*", desc = "Run the startup benchmark" },
    },
    Config = {
      function()
        local dir = require("wraithvim.core.config").dir()
        vim.fn.mkdir(dir, "p")
        vim.cmd.edit(vim.fn.fnameescape(dir))
      end,
      { desc = "Open the user configuration directory" },
    },
    Notifications = {
      call("wraithvim.ui.notifications", "show_history"),
      { desc = "Show notification history" },
    },
    Keys = { call("wraithvim.config.keymaps", "cheatsheet"), { desc = "Keymap cheatsheet" } },
    BufferCleanup = {
      call("wraithvim.features.buffers", "cleanup"),
      { desc = "Delete hidden, unmodified buffers" },
    },

    -- Terminal
    Terminal = {
      function(o)
        if o.args ~= "" then
          require(t).open(o.args)
        else
          require(t).toggle()
        end
      end,
      {
        nargs = "?",
        complete = function(lead)
          return matching(lead, { "bottom", "top", "left", "right", "float" })
        end,
        desc = "Toggle the terminal panel",
      },
    },
    TerminalSplit = {
      function(o)
        require(t).split(o.args == "vertical" and "vertical" or "horizontal")
      end,
      {
        nargs = "?",
        complete = function(lead)
          return matching(lead, { "horizontal", "vertical" })
        end,
        desc = "Open a terminal in a new split",
      },
    },
    SidePanel = {
      function(o)
        local panels = require("wraithvim.features.panels")
        local view, side
        for _, arg in ipairs(o.fargs) do
          if arg == "left" or arg == "right" then
            side = arg
          else
            view = arg
          end
        end
        if not view and not side then
          panels.toggle()
        else
          panels.open(view, side)
        end
      end,
      {
        nargs = "*",
        complete = function(lead)
          return matching(lead, { "graph", "changes", "terminal", "left", "right" })
        end,
        desc = "Show the Git graph, changed files or terminal beside the editor",
      },
    },
    TerminalClose = { call(t, "close"), { desc = "Stop and close the terminal panel" } },
    TerminalNew = { call(t, "new"), { desc = "Open another terminal beside the panel" } },

    -- Git
    Actions = { call("wraithvim.config.keymaps", "palette"), { desc = "Search and run any action by name" } },
    Explorer = { call("wraithvim.features.explorer", "toggle"), { desc = "Toggle the file explorer" } },
    FindFile = { call("wraithvim.features.search", "find_files"), { desc = "Find a file by name" } },
    Search = { call("wraithvim.features.search", "live_grep"), { desc = "Search text in the project" } },
    DiffDisk = { call("wraithvim.features.autoreload", "diff_disk"), { desc = "Compare buffer with file on disk" } },
    NewFile = { call("wraithvim.features.files", "new_file"), { desc = "New file next to the current one" } },
    NewFolder = { call("wraithvim.features.files", "new_folder"), { desc = "New folder next to the current file" } },
    CloseTab = { call("wraithvim.features.buffers", "delete"), { desc = "Close the current tab (buffer)" } },
    GitGraph = { call(g, "graph"), { desc = "Commit graph of the current branch" } },
    GitGraphAll = { call(g, "graph", true), { desc = "Commit graph of all branches" } },
    GitStatus = { call(g, "status"), { desc = "Git status (fugitive)" } },
    GitDiff = { call(g, "diff"), { desc = "Diff working tree (diffview)" } },
    GitDiffClose = { call(g, "diff_close"), { desc = "Close diffview" } },
    GitCommit = { call(g, "commit"), { desc = "Git commit" } },
    GitAmend = { call(g, "commit", true), { desc = "Git commit --amend" } },
    GitPush = { call(g, "push"), { desc = "Git push" } },
    GitPull = { call(g, "pull"), { desc = "Git pull" } },
    GitBranches = { call(g, "branches"), { desc = "Switch Git branch" } },
    GitLog = { call(g, "history"), { desc = "Repository history" } },
    GitFileHistory = { call(g, "file_history"), { desc = "Current file history" } },
    GitStage = { call(g, "stage_file"), { desc = "Stage current file" } },
    GitUnstage = { call(g, "unstage_file"), { desc = "Unstage current file" } },

    -- Conflicts
    Conflict = {
      function(o)
        require(c).open(o.args ~= "" and o.args or nil)
      end,
      { nargs = "?", complete = "file", desc = "Open the three-way conflict view" },
    },
    Conflicts = { call(c, "quickfix"), { desc = "List conflicted files in quickfix" } },
    ConflictChoose = {
      function(o)
        local choice, scope = o.fargs[1], o.fargs[2]
        if o.bang then
          require(c).choose_file(choice)
        else
          require(c).choose(choice, { all = scope == "all" })
        end
      end,
      {
        nargs = "+",
        bang = true,
        complete = function(lead, line)
          if #vim.split(line, "%s+") > 2 then
            return matching(lead, { "all" })
          end
          return matching(lead, require(c).choices)
        end,
        desc = "Take ours/theirs/both/base/none for a conflict (! = whole file)",
      },
    },
    ConflictResolve = {
      function(o)
        require(c).resolve(o.args ~= "" and o.args or nil)
      end,
      { nargs = "?", complete = "file", desc = "Mark conflict resolved and stage the file" },
    },
    ConflictClose = { call(c, "close"), { desc = "Close the conflict view" } },

    -- Formatting, syntax, tools
    Format = {
      function(o)
        -- The end column must be the end of the last line, or language
        -- servers leave that line out.
        local last = o.range > 0 and vim.api.nvim_buf_get_lines(0, o.line2 - 1, o.line2, true)[1] or ""
        local range = o.range > 0 and { start = { o.line1, 0 }, ["end"] = { o.line2, #last } } or nil
        require("wraithvim.integrations.formatter").format({ range = range })
      end,
      { range = true, desc = "Format buffer or range" },
    },
    FormatToggle = {
      function(o)
        require("wraithvim.integrations.formatter").toggle(o.bang)
      end,
      { bang = true, desc = "Toggle format on save (! = buffer only)" },
    },
    InstallParsers = {
      function(o)
        require("wraithvim.integrations.treesitter").install(o.fargs)
      end,
      { nargs = "*", desc = "Install Treesitter parsers for enabled languages" },
    },
    InstallTools = {
      call("wraithvim.integrations.mason", "install_missing"),
      { desc = "Install missing language tools with Mason (asks first)" },
    },
  }
end

function M.setup()
  for name, def in pairs(M.definitions()) do
    vim.api.nvim_create_user_command(name, def[1], def[2])
  end
end

return M
