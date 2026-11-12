return {
  description = "Rust",
  filetypes = { "rust" },
  parsers = { "rust" },
  servers = {
    rust_analyzer = {
      cmd = "rust-analyzer",
      mason = "rust-analyzer",
      install = "rustup component add rust-analyzer",
      -- clippy lints as you save (falls back to cargo check without clippy).
      config = { settings = { ["rust-analyzer"] = { check = { command = "clippy" } } } },
    },
  },
  formatters = {
    rustfmt = { cmd = "rustfmt", filetypes = { "rust" }, install = "rustup component add rustfmt" },
  },
}
