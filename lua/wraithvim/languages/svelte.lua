return {
  description = "Svelte",
  filetypes = { "svelte" },
  parsers = { "svelte" },
  servers = {
    svelte = {
      cmd = "svelteserver",
      mason = "svelte-language-server",
      install = "npm install -g svelte-language-server",
    },
  },
  formatters = {
    prettier = { cmd = "prettier", mason = "prettier", filetypes = { "svelte" }, install = "npm install -g prettier" },
  },
}
