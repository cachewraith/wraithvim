return {
  description = "Elixir",
  filetypes = { "elixir", "eelixir", "heex", "surface" },
  parsers = { "elixir", "heex", "eex" },
  servers = {
    elixirls = { cmd = "elixir-ls", mason = "elixir-ls", install = "install elixir-ls from GitHub releases or Mason" },
  },
  formatters = {
    mix = { cmd = "mix", filetypes = { "elixir", "eelixir", "heex" }, install = "install Elixir" },
  },
}
