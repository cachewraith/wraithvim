return {
  description = "Python",
  filetypes = { "python" },
  parsers = { "python" },
  servers = {
    basedpyright = { cmd = "basedpyright-langserver", mason = "basedpyright", install = "pipx install basedpyright" },
  },
  formatters = {
    ruff_format = { cmd = "ruff", mason = "ruff", filetypes = { "python" }, install = "pipx install ruff" },
  },
}
