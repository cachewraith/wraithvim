-- Git graph: branch/commit graph built on fugitive (:Flog, <leader>gg).
return function(_)
  return {
    "rbong/vim-flog",
    cmd = { "Flog", "Flogsplit", "Floggit" },
    dependencies = { "tpope/vim-fugitive" },
  }
end
