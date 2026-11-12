return {
  description = "Go",
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  parsers = { "go", "gomod", "gosum", "gowork" },
  servers = {
    gopls = {
      cmd = "gopls",
      mason = "gopls",
      install = "go install golang.org/x/tools/gopls@latest",
      -- staticcheck and extra analyses: lint errors without golangci-lint.
      config = {
        settings = {
          gopls = {
            staticcheck = true,
            analyses = { unusedparams = true, unusedvariable = true, shadow = true },
          },
        },
      },
    },
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
