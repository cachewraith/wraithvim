-- Server definitions from nvim-lspconfig, started through native vim.lsp.enable().
-- blink.cmp is a dependency so its LSP capabilities are registered first.
return function(_)
  return {
    "neovim/nvim-lspconfig",
    event = require("wraithvim.plugins").lazy_file,
    cmd = { "LspInfo", "LspStart", "LspStop", "LspRestart", "LspLog" },
    dependencies = { "saghen/blink.cmp" },
    config = function()
      require("wraithvim.integrations.lsp").setup()
    end,
  }
end
