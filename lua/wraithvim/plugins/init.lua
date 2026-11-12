-- Plugin specification assembly. Each module returns `function(cfg) -> spec|spec[]`
-- so specs can depend on configuration without global state.

local M = {}

-- Events used for "a real file buffer was opened".
M.lazy_file = { "BufReadPost", "BufNewFile", "BufWritePre" }

M.modules = {
  "wraithvim.plugins.ui.theme",
  "wraithvim.plugins.ui.devicons",
  "wraithvim.plugins.ui.lualine",
  "wraithvim.plugins.ui.bufferline",
  "wraithvim.plugins.ui.neo_tree",
  "wraithvim.plugins.ui.which_key",
  "wraithvim.plugins.editor.telescope",
  "wraithvim.plugins.editor.flash",
  "wraithvim.plugins.completion.blink",
  "wraithvim.plugins.lsp.lspconfig",
  "wraithvim.plugins.lsp.mason",
  "wraithvim.plugins.git.gitsigns",
  "wraithvim.plugins.git.fugitive",
  "wraithvim.plugins.git.diffview",
  "wraithvim.plugins.git.flog",
  "wraithvim.plugins.syntax.treesitter",
  "wraithvim.plugins.syntax.conform",
}

---@param cfg table
---@return table[]
function M.specs(cfg)
  local specs = {}
  for _, mod in ipairs(M.modules) do
    local result = require(mod)(cfg)
    if type(result[1]) == "table" then
      vim.list_extend(specs, result)
    else
      specs[#specs + 1] = result
    end
  end
  return specs
end

return M
