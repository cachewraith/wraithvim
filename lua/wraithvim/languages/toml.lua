return {
  description = "TOML",
  filetypes = { "toml" },
  parsers = { "toml" },
  servers = {
    -- Also formats (through the LSP fallback).
    taplo = { cmd = "taplo", mason = "taplo", install = "cargo install --locked taplo-cli" },
  },
}
