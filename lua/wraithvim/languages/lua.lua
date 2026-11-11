--- Add the Neovim runtime to lua_ls for Neovim-style projects (a `lua/`
--- directory and no .luarc.json of their own).
---@param client vim.lsp.Client
local function on_init(client)
  local folder = client.workspace_folders and client.workspace_folders[1]
  if not folder then
    return
  end
  local path = folder.name
  if vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc") then
    return
  end
  if not vim.uv.fs_stat(path .. "/lua") then
    return
  end
  client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua or {}, {
    runtime = { version = "LuaJIT", path = { "lua/?.lua", "lua/?/init.lua" } },
    workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
  })
end

return {
  description = "Lua",
  filetypes = { "lua" },
  parsers = { "lua", "luadoc" },
  servers = {
    lua_ls = {
      cmd = "lua-language-server",
      mason = "lua-language-server",
      install = "install lua-language-server from your package manager or Mason",
      config = {
        on_init = on_init,
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      },
    },
  },
  formatters = {
    stylua = {
      cmd = "stylua",
      mason = "stylua",
      filetypes = { "lua" },
      install = "install stylua from your package manager, cargo or Mason",
    },
  },
}
