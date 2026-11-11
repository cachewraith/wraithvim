return {
  description = "Go",
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  parsers = { "go", "gomod", "gosum", "gowork" },
  servers = {
    gopls = { cmd = "gopls", mason = "gopls", install = "go install golang.org/x/tools/gopls@latest" },
  },
  formatters = {
    gofumpt = {
      cmd = "gofumpt",
      mason = "gofumpt",
      filetypes = { "go" },
      install = "go install mvdan.cc/gofumpt@latest",
    },
  },
}
