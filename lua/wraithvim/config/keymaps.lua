-- Keymap registry. Every WraithVim mapping is declared here so it can be
-- documented, tested and disabled from ~/.config/wraithvim/keymaps.lua.
-- Plugin-backed mappings call `require()` lazily; lazy.nvim loads the plugin
-- on first use.

local M = {}

-- Prefix groups (shown by the key-hint popup and the cheatsheet). The most
-- used actions sit on a single key right after <leader> instead.
M.groups = {
  { "<leader>b", "Buffers (tabs)" },
  { "<leader>c", "Code" },
  { "<leader>d", "Diagnostics" },
  { "<leader>f", "Find" },
  { "<leader>g", "Git" },
  { "<leader>l", "LSP" },
  { "<leader>T", "Terminals" },
  { "<leader>u", "Update & tools" },
  { "<leader>w", "Windows" },
}

--- Mapping rhs that calls `require(mod)[fn](...)` on use (keeps plugins lazy).
---@param mod string
---@param fn string
---@param ... any
---@return function
local function call(mod, fn, ...)
  local args = { ... }
  return function()
    require(mod)[fn](unpack(args))
  end
end

---@param name string telescope builtin
---@param opts? table
local function pick(name, opts)
  return function()
    require("wraithvim.features.search").pick(name, opts)
  end
end

---@param fn string gitsigns action
---@param ... any
local function gs(fn, ...)
  return call("gitsigns", fn, ...)
end

M.call, M.pick = call, pick

local key_names = {
  leader = "Space",
  space = "Space",
  cr = "Enter",
  esc = "Esc",
  tab = "Tab",
  bs = "Backspace",
  up = "Up",
  down = "Down",
  left = "Left",
  right = "Right",
  pageup = "PageUp",
  pagedown = "PageDown",
}
local modifier_names = { c = "Ctrl", s = "Shift", a = "Alt", m = "Alt", d = "Cmd" }

--- Human-readable key sequence: "<leader>gP" -> "Space g Shift+P",
--- "<C-S-f>" -> "Ctrl+Shift+F", "]h" -> "] h".
---@param lhs string
---@return string
function M.human(lhs)
  local parts = {}
  local i = 1
  while i <= #lhs do
    local special = lhs:match("^<([^<>]+)>", i)
    if special then
      local words, rest = {}, special
      -- Peel modifier prefixes such as "C-" and "S-" off "C-S-f".
      while #rest > 2 and rest:match("^%a%-") do
        local m = rest:sub(1, 1)
        words[#words + 1] = modifier_names[m:lower()] or m
        rest = rest:sub(3)
      end
      words[#words + 1] = key_names[rest:lower()] or (#rest == 1 and rest:upper()) or rest
      parts[#parts + 1] = table.concat(words, "+")
      i = i + #special + 2
    else
      local ch = lhs:sub(i, i)
      parts[#parts + 1] = ch:match("%u") and ("Shift+" .. ch) or ch
      i = i + 1
    end
  end
  return table.concat(parts, " ")
end

--- True for single-key leader mappings such as <leader>e or <leader><space>.
---@param lhs string
---@return boolean
function M.is_quick(lhs)
  local rest = lhs:match("^<leader>(.*)$")
  return rest ~= nil and (#rest == 1 or rest:match("^<[^>]+>$") ~= nil)
end

local function visual_range()
  local a, b = vim.fn.line("."), vim.fn.line("v")
  return { math.min(a, b), math.max(a, b) }
end

--- Default global mappings: { mode, lhs, rhs, desc = ..., plugin = ... }.
---@return table[]
function M.defaults()
  local x = "wraithvim.features.explorer"
  local s = "wraithvim.features.search"
  local g = "wraithvim.features.git"
  local c = "wraithvim.features.conflicts"
  local b = "wraithvim.features.buffers"
  local t = "wraithvim.features.terminal"
  local d = "wraithvim.features.diagnostics"
  local f = "wraithvim.integrations.formatter"
  local cmd = function(command)
    return "<cmd>" .. command .. "<cr>"
  end
  return {
    -- Quick keys: one key after <leader>
    { "n", "<leader><space>", call(s, "find_files"), desc = "Find file", plugin = "telescope.nvim" },
    { "n", "<leader>/", call(s, "live_grep"), desc = "Search text in project", plugin = "telescope.nvim" },
    { "n", "<leader>,", pick("buffers"), desc = "Switch tab", plugin = "telescope.nvim" },
    { "n", "<leader>e", call(x, "toggle"), desc = "Explorer", plugin = "neo-tree.nvim" },
    { "n", "<leader>E", call(x, "reveal"), desc = "Show file in explorer", plugin = "neo-tree.nvim" },
    { "n", "<leader>t", call(t, "toggle"), desc = "Terminal" },
    { "n", "<leader>x", call(b, "delete"), desc = "Close tab" },
    { "n", "<leader>q", cmd("confirm qall"), desc = "Quit (asks to save)" },
    { "n", "<leader>p", call("wraithvim.config.keymaps", "palette"), desc = "Actions (search by name)" },
    { "n", "<leader>?", call("wraithvim.config.keymaps", "cheatsheet"), desc = "All keymaps" },

    -- Find
    { "n", "<leader>ff", call(s, "find_files"), desc = "Files", plugin = "telescope.nvim" },
    { "n", "<leader>fg", call(s, "live_grep"), desc = "Text (live grep)", plugin = "telescope.nvim" },
    { { "n", "x" }, "<leader>fw", call(s, "grep_word"), desc = "Word / selection", plugin = "telescope.nvim" },
    { "n", "<leader>fb", pick("buffers"), desc = "Open tabs", plugin = "telescope.nvim" },
    { "n", "<leader>fr", pick("oldfiles"), desc = "Recent files", plugin = "telescope.nvim" },
    { "n", "<leader>fv", call(s, "git_files"), desc = "Git files", plugin = "telescope.nvim" },
    { "n", "<leader>fx", pick("diagnostics"), desc = "Problems", plugin = "telescope.nvim" },
    { "n", "<leader>fh", pick("help_tags"), desc = "Help", plugin = "telescope.nvim" },
    { "n", "<leader>fk", pick("keymaps"), desc = "Keymaps", plugin = "telescope.nvim" },
    { "n", "<leader>fc", pick("commands"), desc = "Commands", plugin = "telescope.nvim" },
    { "n", "<leader>f/", pick("current_buffer_fuzzy_find"), desc = "In this file", plugin = "telescope.nvim" },
    { "n", "<leader>fR", pick("resume"), desc = "Resume last search", plugin = "telescope.nvim" },

    -- Git
    { "n", "<leader>gg", call(g, "graph"), desc = "Graph (this branch)", plugin = "vim-flog" },
    { "n", "<leader>gG", call(g, "graph", true), desc = "Graph (all branches)", plugin = "vim-flog" },
    { "n", "<leader>gs", call(g, "status"), desc = "Status", plugin = "vim-fugitive" },
    { "n", "<leader>gd", call(g, "diff"), desc = "Diff all changes", plugin = "diffview.nvim" },
    { "n", "<leader>gD", call(g, "diff_close"), desc = "Close diff", plugin = "diffview.nvim" },
    { "n", "<leader>gb", call(g, "branches"), desc = "Switch branch", plugin = "telescope.nvim" },
    { "n", "<leader>gc", call(g, "commit"), desc = "Commit", plugin = "vim-fugitive" },
    { "n", "<leader>gC", call(g, "commit", true), desc = "Amend last commit", plugin = "vim-fugitive" },
    { "n", "<leader>gp", call(g, "push"), desc = "Push", plugin = "vim-fugitive" },
    { "n", "<leader>gP", call(g, "pull"), desc = "Pull", plugin = "vim-fugitive" },
    { "n", "<leader>gl", call(g, "history"), desc = "History (log)", plugin = "diffview.nvim" },
    { "n", "<leader>gf", call(g, "file_history"), desc = "File history", plugin = "diffview.nvim" },
    { "n", "<leader>ge", call(x, "git_status"), desc = "Changed files in explorer", plugin = "neo-tree.nvim" },
    { "n", "<leader>ga", call(g, "stage_file"), desc = "Stage file" },
    { "n", "<leader>gu", call(g, "unstage_file"), desc = "Unstage file" },
    { "n", "<leader>gh", gs("stage_hunk"), desc = "Stage / unstage hunk", plugin = "gitsigns.nvim" },
    {
      "x",
      "<leader>gh",
      function()
        require("gitsigns").stage_hunk(visual_range())
      end,
      desc = "Stage / unstage selected lines",
      plugin = "gitsigns.nvim",
    },
    { "n", "<leader>gr", gs("reset_hunk"), desc = "Undo hunk changes", plugin = "gitsigns.nvim" },
    {
      "x",
      "<leader>gr",
      function()
        require("gitsigns").reset_hunk(visual_range())
      end,
      desc = "Undo changes in selected lines",
      plugin = "gitsigns.nvim",
    },
    { "n", "<leader>gS", gs("stage_buffer"), desc = "Stage whole file (hunks)", plugin = "gitsigns.nvim" },
    { "n", "<leader>gR", gs("reset_buffer"), desc = "Undo all file changes", plugin = "gitsigns.nvim" },
    { "n", "<leader>gv", gs("preview_hunk"), desc = "Preview hunk", plugin = "gitsigns.nvim" },
    { "n", "<leader>gB", gs("blame_line", { full = true }), desc = "Blame line", plugin = "gitsigns.nvim" },
    { "n", "]h", gs("nav_hunk", "next"), desc = "Next change (hunk)", plugin = "gitsigns.nvim" },
    { "n", "[h", gs("nav_hunk", "prev"), desc = "Previous change (hunk)", plugin = "gitsigns.nvim" },
    { "n", "<leader>gx", call(c, "quickfix"), desc = "List merge conflicts" },
    { "n", "<leader>gm", call(c, "open"), desc = "Resolve merge conflict" },

    -- Buffers (tabs)
    { "n", "<leader>bb", "<cmd>BufferLinePick<cr>", desc = "Pick tab", plugin = "bufferline.nvim" },
    { "n", "<leader>bd", call(b, "delete"), desc = "Close tab" },
    { "n", "<leader>bD", call(b, "delete", 0, true), desc = "Close tab (discard changes)" },
    { "n", "<leader>bo", call(b, "close_others"), desc = "Close other tabs" },
    { "n", "<leader>bc", call(b, "cleanup"), desc = "Close hidden tabs" },
    { "n", "<leader>bn", "<cmd>bnext<cr>", desc = "Next tab" },
    { "n", "<leader>bp", "<cmd>bprevious<cr>", desc = "Previous tab" },

    -- Terminals (the panel itself is <leader>t)
    { "n", "<leader>Tn", call(t, "new"), desc = "New terminal beside" },
    { "n", "<leader>Th", call(t, "split", "horizontal"), desc = "Terminal below (split)" },
    { "n", "<leader>Tv", call(t, "split", "vertical"), desc = "Terminal right (split)" },
    { "n", "<leader>Tf", call(t, "open", "float"), desc = "Floating terminal" },
    { "n", "<leader>Tc", call(t, "close"), desc = "Kill terminal panel" },
    -- Ctrl+Shift+` as sent by kitty-protocol / modifyOtherKeys terminals; some report it as Ctrl+~.
    { { "n", "i", "t" }, "<C-S-`>", call(t, "open", "bottom"), desc = "Open terminal at the bottom" },
    { { "n", "i", "t" }, "<C-~>", call(t, "open", "bottom"), desc = "Open terminal at the bottom (Ctrl+Shift+`)" },

    -- Diagnostics
    { "n", "<leader>dd", vim.diagnostic.open_float, desc = "Show line problems" },
    {
      "n",
      "<leader>dn",
      function()
        vim.diagnostic.jump({ count = 1, float = true })
      end,
      desc = "Next problem",
    },
    {
      "n",
      "<leader>dp",
      function()
        vim.diagnostic.jump({ count = -1, float = true })
      end,
      desc = "Previous problem",
    },
    { "n", "<leader>dq", vim.diagnostic.setqflist, desc = "All problems (quickfix)" },
    { "n", "<leader>dl", vim.diagnostic.setloclist, desc = "File problems (list)" },
    { "n", "<leader>dt", call(d, "toggle_virtual_text"), desc = "Toggle inline problems" },
    { "n", "<leader>dT", call(d, "toggle_buffer"), desc = "Toggle problems for file" },
    { "n", "<leader>dx", pick("diagnostics"), desc = "Search problems", plugin = "telescope.nvim" },

    -- Code
    { { "n", "x" }, "<leader>cf", call(f, "format"), desc = "Format", plugin = "conform.nvim" },
    { "n", "<leader>cF", call(f, "toggle"), desc = "Toggle format on save", plugin = "conform.nvim" },

    -- Update & tools
    { "n", "<leader>uu", call("wraithvim.core.update", "run"), desc = "Update WraithVim" },
    { "n", "<leader>uh", cmd("checkhealth wraithvim"), desc = "Health check" },
    { "n", "<leader>up", cmd("Lazy"), desc = "Plugins" },
    { "n", "<leader>uc", cmd("Config"), desc = "Open settings folder" },
    { "n", "<leader>ul", call("wraithvim.core.logger", "open"), desc = "Log" },
    { "n", "<leader>un", call("wraithvim.ui.notifications", "show_history"), desc = "Notification history" },
    { "n", "<leader>ut", cmd("InstallParsers"), desc = "Install syntax parsers" },
    { "n", "<leader>um", cmd("InstallTools"), desc = "Install language tools (Mason)" },

    -- Windows
    { "n", "<leader>wv", "<cmd>vsplit<cr>", desc = "Split right" },
    { "n", "<leader>ws", "<cmd>split<cr>", desc = "Split below" },
    { "n", "<leader>wc", "<cmd>close<cr>", desc = "Close window" },
    { "n", "<leader>wo", "<cmd>only<cr>", desc = "Close other windows" },
    { "n", "<leader>w=", "<C-w>=", desc = "Equal sizes" },
    { "n", "<leader>wh", "<C-w>h", desc = "Go left" },
    { "n", "<leader>wj", "<C-w>j", desc = "Go down" },
    { "n", "<leader>wk", "<C-w>k", desc = "Go up" },
    { "n", "<leader>wl", "<C-w>l", desc = "Go right" },
    { "n", "<leader>w+", "<cmd>resize +3<cr>", desc = "Taller" },
    { "n", "<leader>w-", "<cmd>resize -3<cr>", desc = "Shorter" },
    { "n", "<leader>w>", "<cmd>vertical resize +5<cr>", desc = "Wider" },
    { "n", "<leader>w<", "<cmd>vertical resize -5<cr>", desc = "Narrower" },

    -- Scrolling (the mouse wheel speed is options.scroll)
    { { "n", "x" }, "<C-d>", "<C-d>zz", desc = "Half page down (cursor centered)" },
    { { "n", "x" }, "<C-u>", "<C-u>zz", desc = "Half page up (cursor centered)" },
    { { "n", "x" }, "<A-j>", "10j", desc = "Jump 10 lines down" },
    { { "n", "x" }, "<A-k>", "10k", desc = "Jump 10 lines up" },

    -- Navigation
    { { "n", "x", "o" }, "s", call("flash", "jump"), desc = "Flash jump", plugin = "flash.nvim" },
    { { "n", "x", "o" }, "S", call("flash", "treesitter"), desc = "Flash Treesitter select", plugin = "flash.nvim" },
    { "o", "r", call("flash", "remote"), desc = "Flash remote operation", plugin = "flash.nvim" },

    -- General
    { { "n", "i", "x" }, "<C-s>", "<cmd>write<cr><esc>", desc = "Save file" },
  }
end

--- Buffer-local mappings applied when a language server attaches.
---@return table[]
function M.lsp()
  local tel = function(name)
    return pick(name)
  end
  return {
    { "n", "gd", vim.lsp.buf.definition, desc = "Go to definition" },
    { "n", "gD", vim.lsp.buf.declaration, desc = "Go to declaration" },
    { "n", "<leader>ld", vim.lsp.buf.definition, desc = "Definition" },
    { "n", "<leader>lD", vim.lsp.buf.declaration, desc = "Declaration" },
    { "n", "<leader>lr", vim.lsp.buf.references, desc = "References" },
    { "n", "<leader>li", vim.lsp.buf.implementation, desc = "Implementations" },
    { "n", "<leader>lt", vim.lsp.buf.type_definition, desc = "Type definition" },
    { "n", "<leader>lh", vim.lsp.buf.hover, desc = "Hover" },
    { "n", "<leader>lk", vim.lsp.buf.signature_help, desc = "Signature help" },
    { "n", "<leader>ls", tel("lsp_document_symbols"), desc = "Document symbols", plugin = "telescope.nvim" },
    { "n", "<leader>lS", tel("lsp_dynamic_workspace_symbols"), desc = "Workspace symbols", plugin = "telescope.nvim" },
    { "n", "<leader>lR", "<cmd>lsp restart<cr>", desc = "Restart language server" },
    { "n", "<leader>lI", "<cmd>checkhealth vim.lsp<cr>", desc = "LSP info" },
    { "n", "<leader>lH", call("wraithvim.integrations.lsp", "toggle_inlay_hints"), desc = "Toggle inlay hints" },
    { "n", "<leader>rn", vim.lsp.buf.rename, desc = "Rename symbol" },
    { { "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, desc = "Code action" },
  }
end

---@param entry table
---@param buf? integer
function M.set(entry, buf)
  local opts = {
    desc = entry.desc,
    buffer = buf or entry.buffer,
    silent = entry.silent ~= false,
    nowait = entry.nowait,
    expr = entry.expr,
    remap = entry.remap,
  }
  vim.keymap.set(entry[1], entry[2], entry[3], opts)
end

--- True when (mode, lhs) is listed in `keymaps.disable`.
---@param mode string
---@param lhs string
---@return boolean
function M.is_disabled(mode, lhs)
  local disable = require("wraithvim.core.config").get().keymaps.disable
  for _, d in ipairs(disable) do
    if d == lhs then
      return true
    end
    if type(d) == "table" then
      local modes = type(d[1]) == "table" and d[1] or { d[1] }
      if d[2] == lhs and vim.tbl_contains(modes, mode) then
        return true
      end
    end
  end
  return false
end

---@param entry table
---@return boolean
local function plugin_available(entry)
  return not entry.plugin or require("wraithvim.core.plugin_manager").has(entry.plugin)
end

---@param entries table[]
---@param buf? integer
local function apply(entries, buf)
  for _, entry in ipairs(entries) do
    if plugin_available(entry) then
      local modes = type(entry[1]) == "table" and entry[1] or { entry[1] }
      local enabled = vim.tbl_filter(function(m)
        return not M.is_disabled(m, entry[2])
      end, modes)
      if #enabled > 0 then
        M.set(vim.tbl_extend("force", entry, { [1] = enabled }), buf)
      end
    end
  end
end

---@param buf integer
function M.apply_lsp(buf)
  apply(M.lsp(), buf)
end

--- Apply defaults, then the user's keymaps.lua (disable list and extra entries).
M.presets = { "default", "vscode" }

function M.setup()
  apply(M.defaults())
  local config = require("wraithvim.core.config")
  local user = config.load_keymaps()
  if user.preset == "vscode" then
    local vscode = require("wraithvim.config.vscode")
    vscode.apply_options()
    apply(vscode.mappings())
  elseif user.preset ~= "default" then
    require("wraithvim.core.logger").notify(
      vim.log.levels.WARN,
      ("keymaps.preset: unknown preset %q (use %s)"):format(tostring(user.preset), table.concat(M.presets, " or "))
    )
  end
  for _, d in ipairs(user.disable) do
    local modes, lhs = { "n", "x", "o", "i", "t" }, d
    if type(d) == "table" then
      modes = type(d[1]) == "table" and d[1] or { d[1] }
      lhs = d[2]
    end
    for _, mode in ipairs(modes) do
      pcall(vim.keymap.del, mode, lhs)
    end
  end
  for i, entry in ipairs(user.entries) do
    if type(entry) ~= "table" or entry[2] == nil or entry[3] == nil then
      require("wraithvim.core.logger").notify(
        vim.log.levels.WARN,
        ("keymaps.lua entry #%d must look like { mode, lhs, rhs, desc = ... }"):format(i)
      )
    else
      local ok, err = pcall(M.set, entry)
      if not ok then
        require("wraithvim.core.logger").notify(vim.log.levels.WARN, ("keymaps.lua entry #%d: %s"):format(i, err))
      end
    end
  end
end

--- Floating cheatsheet: quick keys first, then each group.
function M.cheatsheet()
  local lines =
    { "WraithVim keymaps  (<leader> = " .. (vim.g.mapleader == " " and "Space" or vim.g.mapleader) .. ")", "" }
  local all = vim.list_extend(vim.deepcopy(M.defaults()), M.lsp())
  local function row(e)
    return ("  %-22s %s"):format(M.human(e[2]), e.desc or "")
  end
  lines[#lines + 1] = "Quick keys"
  for _, e in ipairs(all) do
    if M.is_quick(e[2]) and plugin_available(e) then
      lines[#lines + 1] = row(e)
    end
  end
  lines[#lines + 1] = ""
  for _, group in ipairs(M.groups) do
    lines[#lines + 1] = M.human(group[1]) .. "  " .. group[2]
    for _, e in ipairs(all) do
      if vim.startswith(e[2], group[1]) and plugin_available(e) then
        lines[#lines + 1] = row(e)
      end
    end
    lines[#lines + 1] = ""
  end
  if require("wraithvim.core.config").get().keymaps.preset == "vscode" then
    lines[#lines + 1] = "VS Code keys"
    local seen = {}
    for _, e in ipairs(require("wraithvim.config.vscode").mappings()) do
      if not seen[e[2]] and plugin_available(e) and not e.desc:find("classic terminals", 1, true) then
        seen[e[2]] = true
        lines[#lines + 1] = ("  %-22s %s"):format(M.human(e[2]), e.desc)
      end
    end
    lines[#lines + 1] = ""
  end
  lines[#lines + 1] =
    "Other: Ctrl+Shift+` terminal at the bottom, s / Shift+S flash jump, ] h / [ h changes, Ctrl+S save."
  lines[#lines + 1] = "Full list: :Telescope keymaps"
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  local width = math.min(vim.o.columns - 4, 80)
  local height = math.min(vim.o.lines - 4, #lines)
  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    title = " Keymaps ",
    title_pos = "center",
  })
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, nowait = true })
end

--- Everything you can do, searchable by name (like VS Code's Command
--- Palette): every normal-mode mapping plus argument-free commands. Each
--- entry shows its key so it can be learned.
---@return { label: string, keys: string, run: function }[]
function M.palette_items()
  local items = {}
  local function group_of(lhs)
    for _, g in ipairs(M.groups) do
      if vim.startswith(lhs, g[1]) then
        return g[2]
      end
    end
  end
  local function add(entry, prefix)
    local modes = type(entry[1]) == "table" and entry[1] or { entry[1] }
    if not vim.tbl_contains(modes, "n") or not plugin_available(entry) or M.is_disabled("n", entry[2]) then
      return
    end
    if entry.desc:find("classic terminals", 1, true) or entry.desc:find("Ctrl+Shift+`)", 1, true) then
      return -- alternative encodings of a key already listed
    end
    local group = prefix or group_of(entry[2])
    local label = group and (group .. ": " .. entry.desc) or entry.desc
    local rhs = entry[3]
    items[#items + 1] = {
      label = label,
      keys = M.human(entry[2]),
      run = function()
        if type(rhs) == "function" then
          rhs()
        else
          vim.api.nvim_feedkeys(vim.keycode(rhs), entry.remap and "m" or "n", false)
        end
      end,
    }
  end
  for _, e in ipairs(M.defaults()) do
    add(e)
  end
  for _, e in ipairs(M.lsp()) do
    add(e, "LSP")
  end
  if require("wraithvim.core.config").get().keymaps.preset == "vscode" then
    for _, e in ipairs(require("wraithvim.config.vscode").mappings()) do
      add(e, "VS Code")
    end
  end
  local defs = require("wraithvim.config.commands").definitions()
  local names = vim.tbl_keys(defs)
  table.sort(names)
  for _, name in ipairs(names) do
    local opts = defs[name][2]
    if opts.nargs == nil or opts.nargs == "?" or opts.nargs == "*" then
      items[#items + 1] = {
        label = "Command: " .. (opts.desc or name),
        keys = ":" .. name,
        run = function()
          vim.cmd(name)
        end,
      }
    end
  end
  return items
end

--- Open the actions palette (Telescope when available, else vim.ui.select).
function M.palette()
  local items = M.palette_items()
  local width = 0
  for _, it in ipairs(items) do
    width = math.max(width, vim.fn.strdisplaywidth(it.label))
  end
  local function display(it)
    return it.label .. string.rep(" ", width - vim.fn.strdisplaywidth(it.label) + 3) .. it.keys
  end
  local function run(it)
    vim.schedule(it.run)
  end
  if not require("wraithvim.core.plugin_manager").has("telescope.nvim") then
    vim.ui.select(items, { prompt = "Actions", format_item = display }, function(it)
      if it then
        run(it)
      end
    end)
    return
  end
  local actions = require("telescope.actions")
  local state = require("telescope.actions.state")
  require("telescope.pickers")
    .new({}, {
      prompt_title = "Actions  (type a name, Enter to run)",
      finder = require("telescope.finders").new_table({
        results = items,
        entry_maker = function(it)
          return { value = it, display = display(it), ordinal = it.label .. " " .. it.keys }
        end,
      }),
      sorter = require("telescope.config").values.generic_sorter({}),
      attach_mappings = function(bufnr)
        actions.select_default:replace(function()
          local entry = state.get_selected_entry()
          actions.close(bufnr)
          if entry then
            run(entry.value)
          end
        end)
        return true
      end,
    })
    :find()
end

return M
