return {
  description = "Bash / POSIX shell",
  filetypes = { "sh", "bash" },
  parsers = { "bash" },
  servers = {
    bashls = {
      cmd = "bash-language-server",
      mason = "bash-language-server",
      install = "npm install -g bash-language-server",
    },
  },
  formatters = {
    shfmt = {
      cmd = "shfmt",
      mason = "shfmt",
      filetypes = { "sh", "bash" },
      install = "install shfmt from your package manager or Mason",
    },
  },
}
