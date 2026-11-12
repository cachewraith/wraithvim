-- Treesitter highlighting through Neovim's built-in vim.treesitter.
--
-- Highlighting starts only for filetypes of enabled languages (plus
-- `options.treesitter.extra_filetypes`) and only when a parser is installed.
-- Parsers are installed explicitly with :InstallParsers, which delegates to
-- nvim-treesitter (requires the tree-sitter CLI and a C compiler).

local utils = require("wraithvim.core.utils")

local M = {}

--- True when a parser for `lang` can be loaded.
---@param lang string
---@return boolean
function M.has_parser(lang)
  local ok, added = pcall(vim.treesitter.language.add, lang)
  return ok and added == true
end

---@param buf integer
---@param ft string
---@return boolean started
function M.attach(buf, ft)
  local cfg = require("wraithvim.core.config").get()
  local ts = cfg.options.treesitter
  if vim.treesitter.highlighter.active[buf] then
    return true
  end
  if utils.is_large_file(buf, cfg.options.large_file_size) then
    return false
  end
  local lang = vim.treesitter.language.get_lang(ft) or ft
  if not M.has_parser(lang) then
    return false
  end
  if not pcall(vim.treesitter.start, buf, lang) then
    return false
  end
  if ts.folds then
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
      vim.wo[win][0].foldmethod = "expr"
      vim.wo[win][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
      vim.wo[win][0].foldlevel = 99
    end
  end
  if ts.indent and package.loaded["nvim-treesitter"] == nil then
    -- nvim-treesitter's indentexpr requires the plugin; load it on demand.
    pcall(require, "nvim-treesitter")
  end
  if ts.indent and package.loaded["nvim-treesitter"] then
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end
  return true
end

--- Filetypes that get Treesitter highlighting.
---@param cfg? table
---@return string[]
function M.filetypes(cfg)
  cfg = cfg or require("wraithvim.core.config").get()
  local fts = require("wraithvim.languages").filetypes()
  for _, ft in ipairs(cfg.options.treesitter.extra_filetypes) do
    if not vim.tbl_contains(fts, ft) then
      fts[#fts + 1] = ft
    end
  end
  return fts
end

--- Parsers WraithVim wants for the current configuration.
---@param cfg? table
---@return string[]
function M.wanted_parsers(cfg)
  cfg = cfg or require("wraithvim.core.config").get()
  local parsers = require("wraithvim.languages").parsers()
  for _, p in ipairs(cfg.options.treesitter.extra_parsers) do
    if not vim.tbl_contains(parsers, p) then
      parsers[#parsers + 1] = p
    end
  end
  return parsers
end

--- Names of parsers available on the runtimepath.
---@return table<string, boolean>
function M.installed()
  local out = {}
  for _, path in ipairs(vim.api.nvim_get_runtime_file("parser/*.so", true)) do
    out[vim.fn.fnamemodify(path, ":t:r")] = true
  end
  return out
end

--- Missing build requirements for parser installation.
---@return string[]
function M.missing_requirements()
  local missing = {}
  if not utils.executable("tree-sitter") then
    missing[#missing + 1] = "tree-sitter CLI (>= 0.26.1)"
  end
  if not (utils.executable("cc") or utils.executable("gcc") or utils.executable("clang")) then
    missing[#missing + 1] = "C compiler (cc/gcc/clang)"
  end
  for _, tool in ipairs({ "curl", "tar" }) do
    if not utils.executable(tool) then
      missing[#missing + 1] = tool
    end
  end
  return missing
end

--- Install parsers (default: wanted parsers that are not installed yet).
---@param parsers? string[]
---@param attach? boolean highlight open buffers once installed
function M.install(parsers, attach)
  local missing = M.missing_requirements()
  if #missing > 0 then
    vim.notify(
      "Cannot install Treesitter parsers; missing: " .. table.concat(missing, ", ") .. "\nSee docs/languages.md.",
      vim.log.levels.ERROR,
      { title = "Treesitter" }
    )
    return
  end
  if not parsers or #parsers == 0 then
    local installed = M.installed()
    parsers = vim.tbl_filter(function(p)
      return not installed[p]
    end, M.wanted_parsers())
  end
  if #parsers == 0 then
    vim.notify("All configured parsers are installed.", vim.log.levels.INFO, { title = "Treesitter" })
    return
  end
  vim.notify("Installing parsers: " .. table.concat(parsers, ", "), vim.log.levels.INFO, { title = "Treesitter" })
  local task = require("nvim-treesitter").install(parsers)
  if attach and task and task.await then
    task:await(vim.schedule_wrap(function()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype ~= "" then
          pcall(M.attach, buf, vim.bo[buf].filetype)
        end
      end
    end))
  end
end

---@param cfg table
function M.setup(cfg)
  if not cfg.options.treesitter.highlight then
    return
  end
  vim.api.nvim_create_autocmd("FileType", {
    group = utils.augroup("treesitter"),
    pattern = M.filetypes(cfg),
    callback = function(args)
      M.attach(args.buf, args.match)
    end,
  })
end

return M
