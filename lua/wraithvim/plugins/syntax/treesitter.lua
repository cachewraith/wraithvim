-- Parser management only. Highlighting is started by integrations.treesitter
-- through Neovim's built-in vim.treesitter, so this plugin loads only when a
-- parser command is run. Parsers are never installed automatically.
return function(_)
  return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    -- Rebuild installed parsers after plugin updates, but only when the
    -- tree-sitter CLI can do it; otherwise parsers left by another config
    -- would produce build errors on every install (see :Health).
    build = function()
      if #require("wraithvim.integrations.treesitter").missing_requirements() == 0 then
        vim.cmd("TSUpdate")
      end
    end,
    cmd = { "TSInstall", "TSUpdate", "TSUninstall", "TSLog" },
    config = function()
      require("nvim-treesitter").setup({})
    end,
  }
end
