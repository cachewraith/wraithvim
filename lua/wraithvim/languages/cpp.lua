return {
  description = "C and C++",
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
  parsers = { "c", "cpp" },
  servers = {
    clangd = {
      cmd = "clangd",
      mason = "clangd",
      install = "install clangd (part of clang / clang-tools)",
      -- clang-tidy lint checks (configured per project with .clang-tidy).
      config = { cmd = { "clangd", "--clang-tidy", "--background-index", "--header-insertion=never" } },
    },
  },
  formatters = {
    ["clang-format"] = {
      cmd = "clang-format",
      mason = "clang-format",
      filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
      install = "install clang-format (part of clang / clang-tools)",
    },
  },
}
