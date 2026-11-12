return {
  description = "Kotlin",
  filetypes = { "kotlin" },
  parsers = { "kotlin" },
  servers = {
    kotlin_language_server = {
      cmd = "kotlin-language-server",
      mason = "kotlin-language-server",
      install = "install kotlin-language-server from GitHub releases or Mason",
    },
  },
  formatters = {
    ktlint = {
      cmd = "ktlint",
      mason = "ktlint",
      filetypes = { "kotlin" },
      install = "install ktlint from GitHub releases",
    },
  },
}
