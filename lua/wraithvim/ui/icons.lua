-- Icon sets. The ASCII set is used when `ui.icons.nerd_font = false` so
-- WraithVim stays readable without a patched font.

local M = {}

M.nerd = {
  diagnostics = { Error = " ", Warn = " ", Info = " ", Hint = "󰌵 " },
  git = {
    added = " ",
    modified = " ",
    removed = " ",
    renamed = "󰁕",
    untracked = "",
    ignored = "◌",
    unstaged = "󰄱",
    staged = "",
    conflict = "",
    branch = "",
  },
  signs = { add = "▎", change = "▎", delete = "", topdelete = "", changedelete = "▎", untracked = "▎" },
  folder = { closed = "", open = "", empty = "", empty_open = "" },
  file = "",
  modified = "●",
  close = "󰅖",
  lsp = "",
  terminal = "",
  term_new = "",
  term_hide = "",
  term_kill = "",
  prompt = "  ",
  caret = " ",
  trunc_left = "",
  trunc_right = "",
  dashboard = {
    find = "󰈞 ",
    recent = " ",
    grep = "󰊄 ",
    new = " ",
    explorer = " ",
    config = " ",
    plugins = "󰒲 ",
    health = " ",
    quit = " ",
  },
}

M.ascii = {
  diagnostics = { Error = "E ", Warn = "W ", Info = "I ", Hint = "H " },
  git = {
    added = "+",
    modified = "~",
    removed = "-",
    renamed = "R",
    untracked = "?",
    ignored = "!",
    unstaged = "M",
    staged = "S",
    conflict = "C",
    branch = "",
  },
  signs = { add = "▎", change = "▎", delete = "_", topdelete = "‾", changedelete = "~", untracked = "┆" },
  folder = { closed = "+", open = "-", empty = "+", empty_open = "-" },
  file = " ",
  modified = "+",
  close = "x",
  lsp = "LSP",
  terminal = ">",
  term_new = "+",
  term_hide = "_",
  term_kill = "x",
  prompt = "> ",
  caret = "> ",
  trunc_left = "<",
  trunc_right = ">",
  dashboard = {
    find = "f ",
    recent = "r ",
    grep = "g ",
    new = "n ",
    explorer = "e ",
    config = "c ",
    plugins = "p ",
    health = "h ",
    quit = "q ",
  },
}

--- Active icon set for the current configuration.
---@return table
function M.get()
  local cfg = require("wraithvim.core.config").get()
  return cfg.ui.icons.nerd_font and M.nerd or M.ascii
end

--- lualine/bufferline separator characters for a style name.
---@param style string
---@param nerd boolean
---@return table { component = {left,right}, section = {left,right} }
function M.separators(style, nerd)
  if not nerd or style == "none" then
    return { component = { left = "", right = "" }, section = { left = "", right = "" } }
  end
  if style == "slant" then
    return { component = { left = "", right = "" }, section = { left = "", right = "" } }
  elseif style == "round" then
    return { component = { left = "", right = "" }, section = { left = "", right = "" } }
  end
  return { component = { left = "│", right = "│" }, section = { left = "", right = "" } }
end

return M
