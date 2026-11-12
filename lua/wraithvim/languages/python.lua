return {
  description = "Python",
  filetypes = { "python" },
  parsers = { "python" },
  servers = {
    -- Lint errors and quick fixes (the same ruff that formats).
    ruff = { cmd = "ruff", mason = "ruff", install = "pipx install ruff" },
    basedpyright = { cmd = "basedpyright-langserver", mason = "basedpyright", install = "pipx install basedpyright" },
  },
  formatters = {
    ruff_format = { cmd = "ruff", mason = "ruff", filetypes = { "python" }, install = "pipx install ruff" },
  },
}
