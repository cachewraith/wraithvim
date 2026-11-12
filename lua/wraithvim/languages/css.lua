return {
  description = "CSS, SCSS and Less",
  filetypes = { "css", "scss", "less" },
  parsers = { "css", "scss" },
  servers = {
    cssls = {
      cmd = "vscode-css-language-server",
      mason = "css-lsp",
      install = "npm install -g vscode-langservers-extracted",
    },
  },
  formatters = {
    prettier = {
      cmd = "prettier",
      mason = "prettier",
      filetypes = { "css", "scss", "less" },
      install = "npm install -g prettier",
    },
  },
}
