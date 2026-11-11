-- Keymap registry. Every WraithVim mapping is declared here so it can be
-- documented, tested and disabled from ~/.config/wraithvim/keymaps.lua.
-- Plugin-backed mappings call `require()` lazily; lazy.nvim loads the plugin
-- on first use.

local M = {}

M.groups = {
  { "<leader>b", "Buffers" },
  { "<leader>c", "Code" },
  { "<leader>d", "Diagnostics" },
  { "<leader>e", "Explorer" },
  { "<leader>f", "Find / search" },
  { "<leader>g", "Git" },
  { "<leader>l", "LSP" },
  { "<leader>t", "Terminal" },
  { "<leader>w", "Windows" },
}

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
  return {
    -- Explorer
    { "n", "<leader>ee", call(x, "toggle"), desc = "Toggle explorer", plugin = "neo-tree.nvim" },
    { "n", "<leader>ef", call(x, "reveal"), desc = "Reveal current file", plugin = "neo-tree.nvim" },
    { "n", "<leader>eg", call(x, "git_status"), desc = "Explorer: Git changes", plugin = "neo-tree.nvim" },
    { "n", "<leader>eb", call(x, "buffers"), desc = "Explorer: open buffers", plugin = "neo-tree.nvim" },
    { "n", "<leader>e>", call(x, "resize", 5), desc = "Widen explorer", plugin = "neo-tree.nvim" },
    { "n", "<leader>e<", call(x, "resize", -5), desc = "Narrow explorer", plugin = "neo-tree.nvim" },

    -- Find / search
    { "n", "<leader>ff", call(s, "find_files"), desc = "Find files", plugin = "telescope.nvim" },
    { "n", "<leader>fg", call(s, "live_grep"), desc = "Live grep", plugin = "telescope.nvim" },
    { { "n", "x" }, "<leader>fw", call(s, "grep_word"), desc = "Search word / selection", plugin = "telescope.nvim" },
    { "n", "<leader>fb", pick("buffers"), desc = "Find buffers", plugin = "telescope.nvim" },
    { "n", "<leader>fr", pick("oldfiles"), desc = "Recent files", plugin = "telescope.nvim" },
    { "n", "<leader>fv", call(s, "git_files"), desc = "Git files", plugin = "telescope.nvim" },
    { "n", "<leader>fx", pick("diagnostics"), desc = "Search diagnostics", plugin = "telescope.nvim" },
    { "n", "<leader>fh", pick("help_tags"), desc = "Help tags", plugin = "telescope.nvim" },
    { "n", "<leader>fk", pick("keymaps"), desc = "Keymaps", plugin = "telescope.nvim" },
    { "n", "<leader>fc", pick("commands"), desc = "Commands", plugin = "telescope.nvim" },
    { "n", "<leader>f/", pick("current_buffer_fuzzy_find"), desc = "Search in buffer", plugin = "telescope.nvim" },
    { "n", "<leader>fR", pick("resume"), desc = "Resume last search", plugin = "telescope.nvim" },
    { { "n", "x" }, "<leader>fd", call(f, "format"), desc = "Format document", plugin = "conform.nvim" },

    -- Git
    { "n", "<leader>gs", call(g, "status"), desc = "Git status", plugin = "vim-fugitive" },
    { "n", "<leader>gd", call(g, "diff"), desc = "Git diff (all changes)", plugin = "diffview.nvim" },
    { "n", "<leader>gD", call(g, "diff_close"), desc = "Close diff view", plugin = "diffview.nvim" },
    { "n", "<leader>gb", call(g, "branches"), desc = "Git branches", plugin = "telescope.nvim" },
    { "n", "<leader>gc", call(g, "commit"), desc = "Git commit", plugin = "vim-fugitive" },
    { "n", "<leader>gC", call(g, "commit", true), desc = "Git commit --amend", plugin = "vim-fugitive" },
    { "n", "<leader>gp", call(g, "push"), desc = "Git push", plugin = "vim-fugitive" },
    { "n", "<leader>gP", call(g, "pull"), desc = "Git pull", plugin = "vim-fugitive" },
    { "n", "<leader>gl", call(g, "history"), desc = "Commit history", plugin = "diffview.nvim" },
    { "n", "<leader>gf", call(g, "file_history"), desc = "File history", plugin = "diffview.nvim" },
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
    { "n", "<leader>gr", gs("reset_hunk"), desc = "Reset hunk", plugin = "gitsigns.nvim" },
    {
      "x",
      "<leader>gr",
      function()
        require("gitsigns").reset_hunk(visual_range())
      end,
      desc = "Reset selected lines",
      plugin = "gitsigns.nvim",
    },
    { "n", "<leader>gS", gs("stage_buffer"), desc = "Stage buffer", plugin = "gitsigns.nvim" },
    { "n", "<leader>gR", gs("reset_buffer"), desc = "Reset buffer", plugin = "gitsigns.nvim" },
    { "n", "<leader>gv", gs("preview_hunk"), desc = "Preview hunk", plugin = "gitsigns.nvim" },
    { "n", "<leader>gB", gs("blame_line", { full = true }), desc = "Blame line", plugin = "gitsigns.nvim" },
    { "n", "]h", gs("nav_hunk", "next"), desc = "Next hunk", plugin = "gitsigns.nvim" },
    { "n", "[h", gs("nav_hunk", "prev"), desc = "Previous hunk", plugin = "gitsigns.nvim" },
    { "n", "<leader>gx", call(c, "quickfix"), desc = "List merge conflicts" },
    { "n", "<leader>gm", call(c, "open"), desc = "Resolve merge conflict (3-way)" },

    -- Buffers
    { "n", "<leader>bb", "<cmd>BufferLinePick<cr>", desc = "Pick buffer", plugin = "bufferline.nvim" },
    { "n", "<leader>bd", call(b, "delete"), desc = "Delete buffer" },
    { "n", "<leader>bD", call(b, "delete", 0, true), desc = "Delete buffer (discard changes)" },
    { "n", "<leader>bo", call(b, "close_others"), desc = "Delete other buffers" },
    { "n", "<leader>bc", call(b, "cleanup"), desc = "Delete hidden buffers" },
    { "n", "<leader>bn", "<cmd>bnext<cr>", desc = "Next buffer" },
    { "n", "<leader>bp", "<cmd>bprevious<cr>", desc = "Previous buffer" },

    -- Terminal
    { "n", "<leader>tt", call(t, "toggle"), desc = "Toggle terminal" },
    { "n", "<leader>th", call(t, "split", "horizontal"), desc = "Terminal in horizontal split" },
    { "n", "<leader>tv", call(t, "split", "vertical"), desc = "Terminal in vertical split" },
    { "n", "<leader>tf", call(t, "open", "float"), desc = "Floating terminal" },
    { "n", "<leader>tc", call(t, "close"), desc = "Close terminal" },

    -- Diagnostics
    { "n", "<leader>dd", vim.diagnostic.open_float, desc = "Line diagnostics" },
    {
      "n",
      "<leader>dn",
      function()
        vim.diagnostic.jump({ count = 1, float = true })
      end,
      desc = "Next diagnostic",
    },
    {
      "n",
      "<leader>dp",
      function()
        vim.diagnostic.jump({ count = -1, float = true })
      end,
      desc = "Previous diagnostic",
    },
    { "n", "<leader>dq", vim.diagnostic.setqflist, desc = "Diagnostics to quickfix" },
    { "n", "<leader>dl", vim.diagnostic.setloclist, desc = "Buffer diagnostics to location list" },
    { "n", "<leader>dt", call(d, "toggle_virtual_text"), desc = "Toggle inline diagnostics" },
    { "n", "<leader>dT", call(d, "toggle_buffer"), desc = "Toggle buffer diagnostics" },
    { "n", "<leader>dx", pick("diagnostics"), desc = "Search all diagnostics", plugin = "telescope.nvim" },

    -- Code
    { { "n", "x" }, "<leader>cf", call(f, "format"), desc = "Format", plugin = "conform.nvim" },
    { "n", "<leader>cF", call(f, "toggle"), desc = "Toggle format on save", plugin = "conform.nvim" },

    -- Windows
    { "n", "<leader>wv", "<cmd>vsplit<cr>", desc = "Split vertically" },
    { "n", "<leader>ws", "<cmd>split<cr>", desc = "Split horizontally" },
    { "n", "<leader>wc", "<cmd>close<cr>", desc = "Close window" },
    { "n", "<leader>wo", "<cmd>only<cr>", desc = "Close other windows" },
    { "n", "<leader>w=", "<C-w>=", desc = "Equalize windows" },
    { "n", "<leader>wh", "<C-w>h", desc = "Focus left window" },
    { "n", "<leader>wj", "<C-w>j", desc = "Focus window below" },
    { "n", "<leader>wk", "<C-w>k", desc = "Focus window above" },
    { "n", "<leader>wl", "<C-w>l", desc = "Focus right window" },
    { "n", "<leader>w+", "<cmd>resize +3<cr>", desc = "Taller window" },
    { "n", "<leader>w-", "<cmd>resize -3<cr>", desc = "Shorter window" },
    { "n", "<leader>w>", "<cmd>vertical resize +5<cr>", desc = "Wider window" },
    { "n", "<leader>w<", "<cmd>vertical resize -5<cr>", desc = "Narrower window" },

    -- Navigation
    { { "n", "x", "o" }, "s", call("flash", "jump"), desc = "Flash jump", plugin = "flash.nvim" },
    { { "n", "x", "o" }, "S", call("flash", "treesitter"), desc = "Flash Treesitter select", plugin = "flash.nvim" },
    { "o", "r", call("flash", "remote"), desc = "Flash remote operation", plugin = "flash.nvim" },

    -- General
    { { "n", "i", "x" }, "<C-s>", "<cmd>write<cr><esc>", desc = "Save file" },
    { "n", "<leader>?", call("wraithvim.config.keymaps", "cheatsheet"), desc = "Keymap cheatsheet" },
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
function M.setup()
  apply(M.defaults())
  local config = require("wraithvim.core.config")
  local user = config.load_keymaps()
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

--- Floating cheatsheet of leader mappings, grouped by prefix.
function M.cheatsheet()
  local lines =
    { "WraithVim keymaps  (<leader> = " .. (vim.g.mapleader == " " and "Space" or vim.g.mapleader) .. ")", "" }
  local all = vim.list_extend(vim.deepcopy(M.defaults()), M.lsp())
  for _, group in ipairs(M.groups) do
    lines[#lines + 1] = group[1] .. "  " .. group[2]
    for _, e in ipairs(all) do
      if vim.startswith(e[2], group[1]) and plugin_available(e) then
        local modes = type(e[1]) == "table" and table.concat(e[1], "") or e[1]
        lines[#lines + 1] = ("  %-14s %-4s %s"):format(e[2], modes, e.desc or "")
      end
    end
    lines[#lines + 1] = ""
  end
  lines[#lines + 1] = "Other: s/S flash, ]h/[h hunks, ]x/[x conflicts, <C-s> save. Full list: :Telescope keymaps"
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

return M
