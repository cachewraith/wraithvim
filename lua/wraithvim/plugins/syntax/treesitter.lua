-- Parser management only. Highlighting is started by integrations.treesitter
-- through Neovim's built-in vim.treesitter, so this plugin loads only when a
-- parser command is run. Parsers are never installed automatically.
return function(_)
  return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    cmd = { "TSInstall", "TSUpdate", "TSUninstall", "TSLog" },
    config = function()
      require("nvim-treesitter").setup({})
    end,
  }
end
