return {
  description = "Nix",
  filetypes = { "nix" },
  parsers = { "nix" },
  servers = {
    nil_ls = { cmd = "nil", mason = "nil", install = "nix profile install nixpkgs#nil" },
  },
  formatters = {
    nixfmt = { cmd = "nixfmt", filetypes = { "nix" }, install = "nix profile install nixpkgs#nixfmt-rfc-style" },
  },
}
