return {
  description = "GraphQL",
  filetypes = { "graphql" },
  parsers = { "graphql" },
  servers = {
    graphql = {
      cmd = "graphql-lsp",
      mason = "graphql-language-service-cli",
      install = "npm install -g graphql-language-service-cli",
    },
  },
  formatters = {
    prettier = { cmd = "prettier", mason = "prettier", filetypes = { "graphql" }, install = "npm install -g prettier" },
  },
}
