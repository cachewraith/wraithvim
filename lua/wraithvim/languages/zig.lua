return {
  description = "Zig",
  filetypes = { "zig", "zir" },
  parsers = { "zig" },
  servers = {
    -- Also formats (through the LSP fallback).
    zls = { cmd = "zls", mason = "zls", install = "install zls matching your Zig version" },
  },
}
