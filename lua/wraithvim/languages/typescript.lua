return {
  description = "JavaScript and TypeScript",
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  parsers = { "javascript", "typescript", "tsx", "jsdoc" },
  servers = {
    vtsls = { cmd = "vtsls", mason = "vtsls", install = "npm install -g @vtsls/language-server" },
  },
  formatters = {
    -- conform.nvim prefers a project-local node_modules/.bin/prettier when present.
    prettier = {
      cmd = "prettier",
      mason = "prettier",
      filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
      install = "npm install -g prettier",
    },
  },
}
