-- Git graph: branch/commit graph built on fugitive (:Flog, <leader>gg).
-- Format, colors and one-key actions: wraithvim.features.graph.
return function(_)
  return {
    "rbong/vim-flog",
    cmd = { "Flog", "Flogsplit", "Floggit" },
    dependencies = { "tpope/vim-fugitive" },
    init = function()
      require("wraithvim.features.graph").setup()
    end,
  }
end
