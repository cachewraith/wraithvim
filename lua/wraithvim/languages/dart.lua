return {
  description = "Dart and Flutter",
  filetypes = { "dart" },
  parsers = { "dart" },
  servers = {
    -- Ships with the Dart / Flutter SDK; nothing to install separately.
    dartls = { cmd = "dart", install = "install the Dart or Flutter SDK" },
  },
  formatters = {
    dart_format = { cmd = "dart", filetypes = { "dart" }, install = "install the Dart or Flutter SDK" },
  },
}
