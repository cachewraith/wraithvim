return {
  description = "Terraform and HCL",
  filetypes = { "terraform", "terraform-vars", "hcl" },
  parsers = { "terraform", "hcl" },
  servers = {
    -- Also formats (through the LSP fallback).
    terraformls = { cmd = "terraform-ls", mason = "terraform-ls", install = "install terraform-ls from HashiCorp" },
  },
}
