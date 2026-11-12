-- VS Code keymap preset (opt-in: `preset = "vscode"` in keymaps.lua).
--
-- Adds familiar VS Code shortcuts on top of WraithVim's defaults and makes
-- selections behave like VS Code: Shift+arrows and mouse drags start a
-- selection, and typing replaces it (Neovim's Select mode).
--
-- Terminals only deliver Ctrl+Shift+<key>, Ctrl+. and Ctrl+Tab when they speak
-- the kitty keyboard protocol (kitty, foot, WezTerm, Ghostty, Alacritty);
-- every essential action also has a key that works in any terminal.

local keymaps = require("wraithvim.config.keymaps")
local call, pick = keymaps.call, keymaps.pick

local M = {}

--- Options that make selection and cursor movement feel like VS Code.
--- Options the user already set (options.lua, keymaps.lua) are left alone.
function M.apply_options()
  local function default(name, value)
    if not vim.api.nvim_get_option_info2(name, {}).was_set then
      vim.opt[name] = value
    end
  end
  default("keymodel", { "startsel", "stopsel" }) -- Shift+arrows select, plain arrows deselect
  default("selectmode", { "mouse", "key" }) -- typing replaces a selection
  default("selection", "exclusive") -- the cursor character is not part of a selection
  vim.opt.whichwrap:append("<,>,[,]") -- arrows move across line ends
end

--- A visual-mode mapping plus its Select-mode twin. In Select mode typed
--- characters replace the selection, so string rhs first switch to Visual
--- mode with <C-g>.
---@param lhs string
---@param rhs string
---@param desc string
---@param opts? table
---@return table[]
local function visual(lhs, rhs, desc, opts)
  return {
    vim.tbl_extend("force", { "x", lhs, rhs, desc = desc }, opts or {}),
    vim.tbl_extend("force", { "s", lhs, "<C-g>" .. rhs, desc = desc }, opts or {}),
  }
end

local function go_to_line()
  vim.ui.input({ prompt = "Go to line: " }, function(input)
    local n = tonumber(input)
    if n then
      local last = vim.api.nvim_buf_line_count(0)
      vim.api.nvim_win_set_cursor(0, { math.max(1, math.min(n, last)), 0 })
      vim.cmd("normal! zz")
    end
  end)
end

--- Mappings of the preset, in the same format as keymaps.defaults().
---@return table[]
function M.mappings()
  local x = "wraithvim.features.explorer"
  local t = "wraithvim.features.terminal"
  local s = "wraithvim.features.search"
  local list = {
    -- Files, search, panels
    { "n", "<C-p>", call(s, "find_files"), desc = "Quick open file", plugin = "telescope.nvim" },
    { { "n", "i" }, "<F1>", call("wraithvim.config.keymaps", "palette"), desc = "Command palette" },
    { { "n", "i" }, "<C-S-p>", call("wraithvim.config.keymaps", "palette"), desc = "Command palette" },
    { { "n", "i" }, "<C-S-f>", call(s, "live_grep"), desc = "Search in project", plugin = "telescope.nvim" },
    { "n", "<C-f>", "/", desc = "Find in file", silent = false },
    { "n", "<C-g>", go_to_line, desc = "Go to line" },
    { "n", "<C-n>", "<cmd>enew<cr>", desc = "New file" },
    { "n", "<C-b>", call(x, "toggle"), desc = "Toggle explorer", plugin = "neo-tree.nvim" },
    { "n", "<C-S-e>", call(x, "reveal"), desc = "Show file in explorer", plugin = "neo-tree.nvim" },
    { { "n", "t" }, "<C-`>", call(t, "toggle"), desc = "Toggle terminal" },
    -- Terminals without the kitty protocol send Ctrl+` as NUL, read as <C-Space>.
    { { "n", "t" }, "<C-Space>", call(t, "toggle"), desc = "Toggle terminal (Ctrl+` in classic terminals)" },
    { "n", "<C-\\>", "<cmd>vsplit<cr>", desc = "Split editor right" },
    { "n", "<C-S-g>", call("wraithvim.features.git", "status"), desc = "Source control", plugin = "vim-fugitive" },

    -- Tabs (buffers)
    { "n", "<C-Tab>", "<cmd>bnext<cr>", desc = "Next tab" },
    { "n", "<C-S-Tab>", "<cmd>bprevious<cr>", desc = "Previous tab" },
    { "n", "<C-PageDown>", "<cmd>bnext<cr>", desc = "Next tab" },
    { "n", "<C-PageUp>", "<cmd>bprevious<cr>", desc = "Previous tab" },
    { "n", "<C-w>", call("wraithvim.features.buffers", "delete"), desc = "Close tab", nowait = true },

    -- Editing
    { { "n", "i" }, "<C-z>", "<cmd>undo<cr>", desc = "Undo" },
    { { "n", "i" }, "<C-y>", "<cmd>redo<cr>", desc = "Redo" },
    { { "n", "i" }, "<C-S-z>", "<cmd>redo<cr>", desc = "Redo" },
    { "n", "<C-a>", "ggVG<C-g>", desc = "Select all" },
    { "i", "<C-a>", "<Esc>ggVG<C-g>", desc = "Select all" },
    { "n", "<C-c>", '"+yy', desc = "Copy line" },
    { "n", "<C-x>", '"+dd', desc = "Cut line" },
    { "n", "<C-v>", '"+P', desc = "Paste" },
    { "i", "<C-v>", "<C-r><C-o>+", desc = "Paste" },
    { "c", "<C-v>", "<C-r>+", desc = "Paste", silent = false },
    { "n", "<C-/>", "gcc", desc = "Toggle line comment", remap = true },
    { "n", "<C-_>", "gcc", desc = "Toggle line comment (Ctrl+/ in classic terminals)", remap = true },
    { "i", "<C-/>", "<cmd>normal gcc<cr>", desc = "Toggle line comment" },
    { "i", "<C-_>", "<cmd>normal gcc<cr>", desc = "Toggle line comment (Ctrl+/ in classic terminals)" },
    { { "n", "i" }, "<A-Down>", "<cmd>silent! move .+1<cr>", desc = "Move line down" },
    { { "n", "i" }, "<A-Up>", "<cmd>silent! move .-2<cr>", desc = "Move line up" },
    { { "n", "i" }, "<S-A-Down>", "<cmd>copy .<cr>", desc = "Duplicate line down" },
    { { "n", "i" }, "<S-A-Up>", "<cmd>copy .-1<cr>", desc = "Duplicate line up" },
    { { "n", "i" }, "<C-S-k>", vim.api.nvim_del_current_line, desc = "Delete line" },

    -- Code (LSP)
    { "n", "<F2>", vim.lsp.buf.rename, desc = "Rename symbol" },
    { "n", "<F12>", vim.lsp.buf.definition, desc = "Go to definition" },
    { "n", "<S-F12>", vim.lsp.buf.references, desc = "Find references" },
    -- Many terminals report Shift+F12 as F24 and Shift+F8 as F20.
    { "n", "<F24>", vim.lsp.buf.references, desc = "Find references (Shift+F12)" },
    { { "n", "i", "x" }, "<C-.>", vim.lsp.buf.code_action, desc = "Quick fix / code action" },
    { "n", "<F8>", call("wraithvim.config.vscode", "next_problem", 1), desc = "Next problem" },
    { "n", "<S-F8>", call("wraithvim.config.vscode", "next_problem", -1), desc = "Previous problem" },
    { "n", "<F20>", call("wraithvim.config.vscode", "next_problem", -1), desc = "Previous problem (Shift+F8)" },
    { "n", "<C-S-o>", pick("lsp_document_symbols"), desc = "Go to symbol in file", plugin = "telescope.nvim" },
    {
      "n",
      "<C-t>",
      pick("lsp_dynamic_workspace_symbols"),
      desc = "Go to symbol in workspace",
      plugin = "telescope.nvim",
    },
    {
      { "n", "i" },
      "<S-A-f>",
      call("wraithvim.integrations.formatter", "format"),
      desc = "Format document",
      plugin = "conform.nvim",
    },
    -- Classic terminals send Shift+Alt+F as Alt+F (uppercase).
    {
      { "n", "i" },
      "<M-F>",
      call("wraithvim.integrations.formatter", "format"),
      desc = "Format document (Shift+Alt+F in classic terminals)",
      plugin = "conform.nvim",
    },
  }

  -- Selection-aware mappings (Visual and Select mode).
  for _, group in ipairs({
    visual("<C-c>", '"+y', "Copy"),
    visual("<C-x>", '"+d', "Cut"),
    visual("<C-v>", '"+P', "Paste over selection"),
    visual("<Tab>", ">gv", "Indent"),
    visual("<S-Tab>", "<gv", "Outdent"),
    visual("<C-/>", "gc", "Toggle comment", { remap = true }),
    visual("<C-_>", "gc", "Toggle comment (Ctrl+/ in classic terminals)", { remap = true }),
    visual("<A-Down>", ":<C-u>silent! '<,'>move '>+1<cr>gv", "Move lines down"),
    visual("<A-Up>", ":<C-u>silent! '<,'>move '<-2<cr>gv", "Move lines up"),
  }) do
    vim.list_extend(list, group)
  end
  return list
end

--- Jump to the next/previous diagnostic and show it, like F8 in VS Code.
---@param count integer
function M.next_problem(count)
  vim.diagnostic.jump({ count = count, float = true })
end

return M
