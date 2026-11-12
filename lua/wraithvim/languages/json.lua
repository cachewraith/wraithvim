return {
  description = "JSON",
  filetypes = { "json", "jsonc", "json5" },
  parsers = { "json" },
  servers = {
    jsonls = {
      cmd = "vscode-json-language-server",
      mason = "json-lsp",
      install = "npm install -g vscode-langservers-extracted",
    },
  },
  formatters = {
    prettier = {
      cmd = "prettier",
      mason = "prettier",
      filetypes = { "json", "jsonc" },
      install = "npm install -g prettier",
    },
  },
}
