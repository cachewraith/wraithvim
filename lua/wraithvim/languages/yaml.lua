return {
  description = "YAML",
  filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab" },
  parsers = { "yaml" },
  servers = {
    yamlls = {
      cmd = "yaml-language-server",
      mason = "yaml-language-server",
      install = "npm install -g yaml-language-server",
      config = { settings = { yaml = { keyOrdering = false } } },
    },
  },
  formatters = {
    prettier = { cmd = "prettier", mason = "prettier", filetypes = { "yaml" }, install = "npm install -g prettier" },
  },
}
