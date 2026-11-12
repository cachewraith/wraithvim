return {
  description = "Ruby",
  filetypes = { "ruby", "eruby" },
  parsers = { "ruby" },
  servers = {
    -- Also runs RuboCop diagnostics when the project uses it.
    ruby_lsp = { cmd = "ruby-lsp", mason = "ruby-lsp", install = "gem install ruby-lsp" },
  },
  formatters = {
    rubocop = { cmd = "rubocop", mason = "rubocop", filetypes = { "ruby" }, install = "gem install rubocop" },
  },
}
