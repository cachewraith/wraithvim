-- TokyoNight. Loaded on demand by `:colorscheme` (lazy.nvim handles ColorSchemePre).
return function(cfg)
  local theme = cfg.ui.theme
  return {
    "folke/tokyonight.nvim",
    lazy = true,
    opts = {
      style = theme.style,
      transparent = theme.transparent,
      styles = {
        sidebars = theme.transparent and "transparent" or "dark",
        floats = theme.transparent and "transparent" or "dark",
      },
      cache = true,
    },
  }
end
