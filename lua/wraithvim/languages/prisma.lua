return {
  description = "Prisma",
  filetypes = { "prisma" },
  parsers = { "prisma" },
  servers = {
    -- Also formats (through the LSP fallback).
    prismals = {
      cmd = "prisma-language-server",
      mason = "prisma-language-server",
      install = "npm install -g @prisma/language-server",
    },
  },
}
