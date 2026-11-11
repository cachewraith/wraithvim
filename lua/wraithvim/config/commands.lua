-- :Wraith* user commands. Implementations are required lazily.

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

--- Command definitions: name -> { fn, opts }.
---@return table<string, { [1]: function, [2]: table }>
function M.definitions()
  local g = "wraithvim.features.git"
  local c = "wraithvim.features.conflicts"
  local t = "wraithvim.features.terminal"
  return {
    WraithHealth = {
      function()
        vim.cmd("checkhealth wraithvim")
      end,
      { desc = "Run WraithVim health checks" },
    },
    WraithUpdate = { call("wraithvim.core.update", "run"), { desc = "Update WraithVim and sync pinned plugins" } },
    WraithLog = { call("wraithvim.core.logger", "open"), { desc = "Open the WraithVim log" } },
    WraithProfile = { call("wraithvim.core.performance", "profile"), { desc = "Show plugin load profile" } },
    WraithBenchmark = {
      function(o)
        require("wraithvim.core.performance").benchmark(o.fargs)
      end,
      { nargs = "*", desc = "Run the startup benchmark" },
    },
    WraithConfig = {
      function()
        local dir = require("wraithvim.core.config").dir()
        vim.fn.mkdir(dir, "p")
        vim.cmd.edit(vim.fn.fnameescape(dir))
      end,
      { desc = "Open the user configuration directory" },
    },
    WraithNotifications = {
      call("wraithvim.ui.notifications", "show_history"),
      { desc = "Show notification history" },
    },
    WraithKeys = { call("wraithvim.config.keymaps", "cheatsheet"), { desc = "Keymap cheatsheet" } },
    WraithBufferCleanup = {
      call("wraithvim.features.buffers", "cleanup"),
      { desc = "Delete hidden, unmodified buffers" },
    },

    -- Terminal
    WraithTerminal = {
      function(o)
        if o.args ~= "" then
          require(t).open(o.args)
        else
          require(t).toggle()
        end
      end,
      {
        nargs = "?",
        complete = function()
          return { "bottom", "top", "left", "right", "float" }
        end,
        desc = "Toggle the terminal panel",
      },
    },
    WraithTerminalSplit = {
      function(o)
        require(t).split(o.args == "vertical" and "vertical" or "horizontal")
      end,
      {
        nargs = "?",
        complete = function()
          return { "horizontal", "vertical" }
        end,
        desc = "Open a terminal in a new split",
      },
    },
    WraithTerminalClose = { call(t, "close"), { desc = "Stop and close the terminal panel" } },

    -- Git
    WraithGitStatus = { call(g, "status"), { desc = "Git status (fugitive)" } },
    WraithGitDiff = { call(g, "diff"), { desc = "Diff working tree (diffview)" } },
    WraithGitDiffClose = { call(g, "diff_close"), { desc = "Close diffview" } },
    WraithGitCommit = { call(g, "commit"), { desc = "Git commit" } },
    WraithGitAmend = { call(g, "commit", true), { desc = "Git commit --amend" } },
    WraithGitPush = { call(g, "push"), { desc = "Git push" } },
    WraithGitPull = { call(g, "pull"), { desc = "Git pull" } },
    WraithGitBranches = { call(g, "branches"), { desc = "Switch Git branch" } },
    WraithGitLog = { call(g, "history"), { desc = "Repository history" } },
    WraithGitFileHistory = { call(g, "file_history"), { desc = "Current file history" } },
    WraithGitStage = { call(g, "stage_file"), { desc = "Stage current file" } },
    WraithGitUnstage = { call(g, "unstage_file"), { desc = "Unstage current file" } },

    -- Conflicts
    WraithConflict = {
      function(o)
        require(c).open(o.args ~= "" and o.args or nil)
      end,
      { nargs = "?", complete = "file", desc = "Open the three-way conflict view" },
    },
    WraithConflicts = { call(c, "quickfix"), { desc = "List conflicted files in quickfix" } },
    WraithConflictChoose = {
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
        complete = function(_, line)
          if #vim.split(line, "%s+") > 2 then
            return { "all" }
          end
          return require(c).choices
        end,
        desc = "Take ours/theirs/both/base/none for a conflict (! = whole file)",
      },
    },
    WraithConflictResolve = {
      function(o)
        require(c).resolve(o.args ~= "" and o.args or nil)
      end,
      { nargs = "?", complete = "file", desc = "Mark conflict resolved and stage the file" },
    },
    WraithConflictClose = { call(c, "close"), { desc = "Close the conflict view" } },

    -- Formatting, syntax, tools
    WraithFormat = {
      function(o)
        local range = o.range > 0 and { start = { o.line1, 0 }, ["end"] = { o.line2, 0 } } or nil
        require("wraithvim.integrations.formatter").format({ range = range })
      end,
      { range = true, desc = "Format buffer or range" },
    },
    WraithFormatToggle = {
      function(o)
        require("wraithvim.integrations.formatter").toggle(o.bang)
      end,
      { bang = true, desc = "Toggle format on save (! = buffer only)" },
    },
    WraithTSInstall = {
      function(o)
        require("wraithvim.integrations.treesitter").install(o.fargs)
      end,
      { nargs = "*", desc = "Install Treesitter parsers for enabled languages" },
    },
    WraithInstallTools = {
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
