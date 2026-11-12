-- Native LSP setup driven by the language registry.
--
-- A server is enabled with vim.lsp.enable() only when its language is enabled
-- and its executable is on PATH; Neovim then starts it lazily when a buffer of
-- a matching filetype opens. Missing servers are offered for installation by
-- integrations/mason.lua, which calls M.enable() once one is installed.

local utils = require("wraithvim.core.utils")
local languages = require("wraithvim.languages")

local M = {}

---@type string[] names of enabled servers
M.active = {}
---@type table<string, table> server name -> registry entry, for servers not installed
M.missing = {}

local hinted = {}

---@param server table
local function hint_missing(server)
  if hinted[server.name] then
    return
  end
  hinted[server.name] = true
  vim.notify(
    ("%s (%s) is not installed, so LSP features are off for this file.\nInstall: %s\nSee :Health."):format(
      server.cmd,
      server.language,
      server.install or "see docs/languages.md"
    ),
    vim.log.levels.INFO,
    { title = "WraithVim LSP" }
  )
end

---@param filetypes string[]
local function watch_missing(filetypes)
  local by_ft = {}
  for _, server in pairs(M.missing) do
    for _, ft in ipairs(server.filetypes) do
      by_ft[ft] = by_ft[ft] or {}
      table.insert(by_ft[ft], server)
    end
  end
  local fts = vim.tbl_keys(by_ft)
  if #fts == 0 then
    return
  end
  local function check(ft)
    for _, server in ipairs(by_ft[ft] or {}) do
      hint_missing(server)
    end
  end
  vim.api.nvim_create_autocmd("FileType", {
    group = utils.augroup("lsp_missing"),
    pattern = fts,
    callback = function(args)
      check(args.match)
    end,
  })
  -- The buffer that triggered loading this module already had its FileType event.
  for _, ft in ipairs(filetypes) do
    check(ft)
  end
end

---@param server table registry entry
---@return table config passed to vim.lsp.config
function M.server_config(server)
  local cfg = vim.deepcopy(server.config or {})
  -- Custom servers without an nvim-lspconfig definition need cmd/filetypes.
  if not vim.lsp.config[server.name] then
    cfg.cmd = cfg.cmd or { server.cmd }
    cfg.filetypes = cfg.filetypes or server.filetypes
  end
  return cfg
end

--- Configure and enable one server (registry entry). Buffers already open
--- with a matching filetype get it right away.
---@param server table
function M.enable(server)
  local server_cfg = M.server_config(server)
  if next(server_cfg) then
    vim.lsp.config(server.name, server_cfg)
  end
  vim.lsp.enable(server.name)
  if not vim.tbl_contains(M.active, server.name) then
    M.active[#M.active + 1] = server.name
  end
  M.missing[server.name] = nil
end

function M.setup()
  local cfg = require("wraithvim.core.config").get()
  local profiles = languages.enabled()
  M.active, M.missing = {}, {}

  for _, server in ipairs(languages.servers(profiles)) do
    for _, p in ipairs(profiles) do
      if p.name == server.language then
        server.filetypes = p.filetypes
      end
    end
    if utils.executable(server.cmd) then
      M.enable(server)
    else
      M.missing[server.name] = server
    end
  end

  vim.api.nvim_create_autocmd("LspAttach", {
    group = utils.augroup("lsp_attach"),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      require("wraithvim.config.keymaps").apply_lsp(args.buf)
      if client and cfg.options.lsp.inlay_hints and client:supports_method("textDocument/inlayHint") then
        vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
      end
    end,
  })

  -- With Mason offering installs, the offer replaces this hint.
  local offers = cfg.options.mason.enabled and cfg.options.mason.auto_install ~= "never"
  if cfg.options.lsp.notify_missing and not offers then
    local open_fts = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype ~= "" then
        open_fts[#open_fts + 1] = vim.bo[buf].filetype
      end
    end
    watch_missing(open_fts)
  end
end

function M.toggle_inlay_hints()
  local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
  vim.lsp.inlay_hint.enable(not enabled, { bufnr = 0 })
end

return M
