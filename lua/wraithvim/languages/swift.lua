return {
  description = "Swift",
  filetypes = { "swift" },
  parsers = { "swift" },
  servers = {
    -- Ships with the Swift toolchain / Xcode.
    -- Swift only: C and C++ stay with clangd.
    sourcekit = { cmd = "sourcekit-lsp", install = "install the Swift toolchain", config = { filetypes = { "swift" } } },
  },
}
