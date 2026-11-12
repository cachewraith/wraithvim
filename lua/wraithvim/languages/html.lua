return {
  description = "HTML",
  filetypes = { "html" },
  parsers = { "html" },
  servers = {
    html = {
      cmd = "vscode-html-language-server",
      mason = "html-lsp",
      install = "npm install -g vscode-langservers-extracted",
    },
    -- Emmet abbreviations (div.box>ul>li*3) in HTML, CSS and JSX.
    emmet_language_server = {
      cmd = "emmet-language-server",
      mason = "emmet-language-server",
      install = "npm install -g @olrtg/emmet-language-server",
    },
  },
  formatters = {
    prettier = { cmd = "prettier", mason = "prettier", filetypes = { "html" }, install = "npm install -g prettier" },
  },
}
