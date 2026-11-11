-- File icons. Disabled entirely when the user has no Nerd Font.
return function(cfg)
  return {
    "nvim-tree/nvim-web-devicons",
    enabled = cfg.ui.icons.nerd_font,
    lazy = true,
    opts = {},
  }
end
