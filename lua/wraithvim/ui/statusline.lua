-- lualine configuration. Components only read cached buffer variables
-- (gitsigns status, LSP client names) so redraws stay cheap.

local M = {}

--- Cache attached LSP client names in `b:wraith_lsp`.
---@param buf integer
function M.update_lsp(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local names = {}
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
    names[#names + 1] = client.name
  end
  vim.b[buf].wraith_lsp = table.concat(names, ",")
end

local function setup_lsp_cache()
  local group = require("wraithvim.core.utils").augroup("statusline_lsp")
  vim.api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
    group = group,
    callback = function(args)
      -- On LspDetach the client is still attached; read the list afterwards.
      vim.schedule(function()
        M.update_lsp(args.buf)
      end)
    end,
  })
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    M.update_lsp(buf)
  end
end

-- lualine refreshes on a 16 ms polling timer by default (~60 wakeups/s while
-- idle). WraithVim instead pushes refreshes on the events that change the
-- statusline. Cursor position needs no refresh: the location/progress
-- components below emit %l/%P items that Neovim evaluates while drawing.
M.refresh_events = {
  "ModeChanged",
  "BufEnter",
  "WinEnter",
  "TabEnter",
  "BufWritePost",
  "BufModifiedSet",
  "FileType",
  "DirChanged",
  "DiagnosticChanged",
  "LspAttach",
  "LspDetach",
  "FileChangedShellPost",
  "TermLeave",
  "VimResized",
  "WinResized",
  "BufFilePost",
  "SessionLoadPost",
}

-- Options shown in the statusline; OptionSet is matched by option name.
M.refresh_options = { "fileformat", "fileencoding", "readonly", "modifiable" }

-- Interval used for lualine's own timers: long enough that they never matter.
M.idle_interval = 2 ^ 31 - 1

local pending = false

--- Coalesce refresh requests into one forced refresh per event-loop tick.
function M.request_refresh()
  if pending then
    return
  end
  pending = true
  vim.schedule(function()
    pending = false
    local ok, lualine = pcall(require, "lualine")
    if ok then
      pcall(lualine.refresh, { force = true, scope = "tabpage", place = { "statusline" } })
    end
  end)
end

local function setup_refresh()
  local group = require("wraithvim.core.utils").augroup("statusline_refresh")
  vim.api.nvim_create_autocmd(M.refresh_events, { group = group, callback = M.request_refresh })
  vim.api.nvim_create_autocmd("OptionSet", {
    group = group,
    pattern = M.refresh_options,
    callback = M.request_refresh,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = { "GitSignsUpdate", "GitSignsChanged" },
    callback = M.request_refresh,
  })
end

local function cmd(command)
  return function()
    vim.cmd(command)
  end
end

--- lualine extension for WraithVim terminals: shell and folder instead of
--- the raw `term://…` buffer name, plus a hint for the current mode.
---@param ic table icon set
---@param nerd boolean
---@return table
function M.terminal_extension(ic, nerd)
  local function shell()
    return (nerd and (ic.terminal .. " ") or "") .. (vim.b.wraith_term_shell or "shell")
  end
  local function folder()
    local cwd = vim.fn.fnamemodify(vim.b.wraith_term_cwd or vim.fn.getcwd(), ":~")
    return (nerd and (ic.folder.open .. " ") or "") .. cwd:gsub("%%", "%%%%")
  end
  local function hint()
    if vim.api.nvim_get_mode().mode == "t" then
      return "Esc Esc: scroll & copy"
    end
    return "click or i: type"
  end
  return {
    filetypes = { require("wraithvim.features.terminal").filetype },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { shell },
      lualine_c = { folder },
      lualine_x = { hint },
    },
  }
end

---@return table lualine options
function M.opts()
  local config = require("wraithvim.core.config").get()
  local ui = config.ui
  local sl = ui.statusline
  local nerd = ui.icons.nerd_font
  local icons = require("wraithvim.ui.icons")
  local ic = icons.get()
  local seps = icons.separators(ui.separators, nerd)

  setup_lsp_cache()
  setup_refresh()

  local branch = {
    function()
      local head = vim.b.gitsigns_head
      if not head or head == "" then
        head = vim.g.gitsigns_head
      end
      if not head or head == "" then
        return ""
      end
      head = head:gsub("%%", "%%%%") -- branch names may contain "%"
      return ic.git.branch ~= "" and (ic.git.branch .. " " .. head) or head
    end,
    on_click = cmd("GitBranches"),
  }

  local diff = {
    "diff",
    symbols = { added = ic.git.added, modified = ic.git.modified, removed = ic.git.removed },
    source = function()
      local s = vim.b.gitsigns_status_dict
      if s then
        return { added = s.added, modified = s.changed, removed = s.removed }
      end
    end,
    on_click = cmd("GitStatus"),
  }

  local diagnostics = {
    "diagnostics",
    sources = { "nvim_diagnostic" },
    symbols = {
      error = ic.diagnostics.Error,
      warn = ic.diagnostics.Warn,
      info = ic.diagnostics.Info,
      hint = ic.diagnostics.Hint,
    },
    on_click = cmd("Telescope diagnostics bufnr=0"),
  }

  local lsp = {
    function()
      local names = vim.b.wraith_lsp
      if not names or names == "" then
        return ""
      end
      return (nerd and (ic.lsp .. " ") or "") .. names
    end,
    on_click = cmd("checkhealth vim.lsp"),
  }

  local filename = {
    "filename",
    path = 1,
    shorting_target = 40,
    symbols = { modified = ic.modified, readonly = "[RO]", unnamed = "[No Name]", newfile = "[New]" },
  }

  -- Statusline items evaluated by Neovim on every redraw (no refresh needed).
  local location = {
    function()
      return "%3l:%-2v"
    end,
  }
  local progress = {
    function()
      return "%P"
    end,
  }

  local sections = {
    lualine_a = { "mode" },
    lualine_b = { branch },
    lualine_c = { filename },
    lualine_x = {},
    lualine_y = { progress },
    lualine_z = { location },
  }
  if sl.diff then
    table.insert(sections.lualine_b, diff)
  end
  if sl.diagnostics then
    table.insert(sections.lualine_c, diagnostics)
  end
  if sl.lsp then
    table.insert(sections.lualine_x, lsp)
  end
  table.insert(sections.lualine_x, { "filetype", icons_enabled = nerd, on_click = cmd("Telescope filetypes") })
  if sl.encoding then
    table.insert(sections.lualine_x, "encoding")
    table.insert(sections.lualine_x, { "fileformat", symbols = { unix = "LF", dos = "CRLF", mac = "CR" } })
  end

  return {
    options = {
      theme = "auto",
      globalstatus = sl.global,
      icons_enabled = nerd,
      component_separators = seps.component,
      section_separators = seps.section,
      disabled_filetypes = { statusline = { "wraithdashboard" } },
      always_show_tabline = false,
      refresh = {
        statusline = M.idle_interval,
        tabline = M.idle_interval,
        winbar = M.idle_interval,
        refresh_time = M.idle_interval,
        events = { "VimResized" },
      },
    },
    sections = sections,
    inactive_sections = {
      lualine_c = { filename },
      lualine_x = { location },
    },
    extensions = { "neo-tree", "fugitive", "quickfix", "man", "lazy", M.terminal_extension(ic, nerd) },
  }
end

return M
