return {
  description = "C#",
  filetypes = { "cs" },
  parsers = { "c_sharp" },
  servers = {
    csharp_ls = {
      cmd = "csharp-ls",
      mason = "csharp-language-server",
      install = "dotnet tool install --global csharp-ls",
    },
  },
  formatters = {
    csharpier = {
      cmd = "csharpier",
      mason = "csharpier",
      filetypes = { "cs" },
      install = "dotnet tool install -g csharpier",
    },
  },
}
