return {
  description = "Markdown",
  filetypes = { "markdown" },
  parsers = { "markdown", "markdown_inline" },
  servers = {
    marksman = { cmd = "marksman", mason = "marksman", install = "install marksman from GitHub releases or Mason" },
  },
  formatters = {
    prettier = { cmd = "prettier", mason = "prettier", filetypes = { "markdown" }, install = "npm install -g prettier" },
  },
}
