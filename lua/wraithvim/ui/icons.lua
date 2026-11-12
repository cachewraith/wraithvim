-- Icon sets. The ASCII set is used when `ui.icons.nerd_font = false` so
-- WraithVim stays readable without a patched font.

local M = {}

-- Nerd Font glyphs are written as \u{...} escapes so the source stays ASCII:
-- private-use characters are easily lost by editors and tools. Names are
-- from https://www.nerdfonts.com/cheat-sheet.
M.nerd = {
  diagnostics = {
    Error = "\u{f057} ", -- fa-times_circle
    Warn = "\u{f071} ", -- fa-warning
    Info = "\u{f05a} ", -- fa-info_circle
    Hint = "\u{f0335} ", -- md-lightbulb
  },
  git = {
    added = "\u{f457} ", -- oct-diff_added
    modified = "\u{f459} ", -- oct-diff_modified
    removed = "\u{f458} ", -- oct-diff_removed
    renamed = "\u{f0055}", -- md-arrow_right_thick
    untracked = "\u{f005}", -- fa-star
    ignored = "◌",
    unstaged = "\u{f0131}", -- md-checkbox_blank_outline
    staged = "\u{f00c}", -- fa-check
    conflict = "\u{e727}", -- dev-git_merge
    branch = "\u{e0a0}", -- pl-branch
  },
  signs = { add = "▎", change = "▎", delete = "▁", topdelete = "▔", changedelete = "▎", untracked = "▎" },
  folder = {
    closed = "\u{f024b}", -- md-folder
    open = "\u{f0770}", -- md-folder_open
    empty = "\u{f0256}", -- md-folder_outline
    empty_open = "\u{f0dcf}", -- md-folder_open_outline
  },
  file = "\u{f0214}", -- md-file
  modified = "●",
  close = "\u{f0156}", -- md-close
  lsp = "\u{f085}", -- fa-cogs
  terminal = "\u{f120}", -- fa-terminal
  term_new = "\u{f067}", -- fa-plus
  term_hide = "\u{f068}", -- fa-minus
  term_kill = "\u{f00d}", -- fa-times
  prompt = "\u{f002}  ", -- fa-search
  caret = "\u{f054} ", -- fa-chevron_right
  trunc_left = "\u{f104}", -- fa-angle_left
  trunc_right = "\u{f105}", -- fa-angle_right
  dashboard = {
    find = "\u{f021e} ", -- md-file_find
    recent = "\u{f1da} ", -- fa-history
    grep = "\u{f0284} ", -- md-format_text
    new = "\u{f15b} ", -- fa-file
    explorer = "\u{f07c} ", -- fa-folder_open
    config = "\u{f013} ", -- fa-gear
    plugins = "\u{f04b2} ", -- md-sleep (lazy.nvim)
    health = "\u{f21e} ", -- fa-heartbeat
    quit = "\u{f011} ", -- fa-power_off
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
    return {
      component = { left = "\u{e0b9}", right = "\u{e0bb}" }, -- ple-backslash / forwardslash_separator
      section = { left = "\u{e0bc}", right = "\u{e0ba}" }, -- ple-upper_left / lower_right_triangle
    }
  elseif style == "round" then
    return {
      component = { left = "\u{e0b5}", right = "\u{e0b7}" }, -- ple-right / left_half_circle_thin
      section = { left = "\u{e0b4}", right = "\u{e0b6}" }, -- ple-right / left_half_circle_thick
    }
  end
  return { component = { left = "│", right = "│" }, section = { left = "\u{e0b4}", right = "\u{e0b6}" } }
end

return M
