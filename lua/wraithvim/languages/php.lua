return {
  description = "PHP",
  filetypes = { "php" },
  parsers = { "php", "phpdoc" },
  servers = {
    intelephense = { cmd = "intelephense", mason = "intelephense", install = "npm install -g intelephense" },
  },
  formatters = {
    -- conform.nvim prefers a project-local vendor/bin/pint when present.
    pint = { cmd = "pint", mason = "pint", filetypes = { "php" }, install = "composer global require laravel/pint" },
  },
}
