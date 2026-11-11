-- Side-by-side diffs and history.
return function(cfg)
  return {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewFileHistory",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewRefresh",
    },
    opts = {
      enhanced_diff_hl = true,
      use_icons = cfg.ui.icons.nerd_font,
    },
  }
end
