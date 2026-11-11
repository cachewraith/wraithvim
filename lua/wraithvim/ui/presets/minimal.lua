-- Minimal preset: editor and statusline only. The explorer, terminal and
-- notifications remain available on demand.
return {
  separators = "none",
  explorer = {
    auto_open = false,
  },
  tabline = {
    enabled = false,
  },
  statusline = {
    lsp = false,
    diff = false,
    encoding = false,
  },
  dashboard = {
    enabled = false,
  },
  notifications = {
    enabled = false,
  },
}
