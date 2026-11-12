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
  -- bash-language-server shows ShellCheck warnings when shellcheck is installed.
  tools = {
    shellcheck = { cmd = "shellcheck", mason = "shellcheck", install = "install shellcheck from your package manager" },
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
