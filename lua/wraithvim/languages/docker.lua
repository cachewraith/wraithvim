return {
  description = "Dockerfile",
  filetypes = { "dockerfile" },
  parsers = { "dockerfile" },
  servers = {
    dockerls = {
      cmd = "docker-langserver",
      mason = "dockerfile-language-server",
      install = "npm install -g dockerfile-language-server-nodejs",
    },
  },
}
