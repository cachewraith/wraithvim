-- Compact preset: narrower panels, no separators, tabline only when needed.
return {
  separators = "none",
  explorer = {
    width = 24,
  },
  tabline = {
    header = false,
    close_icons = false,
    always_show = false,
  },
  statusline = {
    encoding = false,
  },
  terminal = {
    height = 10,
  },
}
