return {
  description = "Java",
  filetypes = { "java" },
  parsers = { "java" },
  servers = {
    jdtls = {
      cmd = "jdtls",
      mason = "jdtls",
      install = "install jdtls (Java 21+ required) from your package manager or Mason",
    },
  },
  formatters = {
    ["google-java-format"] = {
      cmd = "google-java-format",
      mason = "google-java-format",
      filetypes = { "java" },
      install = "download google-java-format from GitHub releases or use Mason",
    },
  },
}
