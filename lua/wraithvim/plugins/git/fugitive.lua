-- Git porcelain: status, commit, push, pull, blame.
return function(_)
  return {
    "tpope/vim-fugitive",
    cmd = {
      "G",
      "Git",
      "Gdiffsplit",
      "Gvdiffsplit",
      "Gread",
      "Gwrite",
      "Gedit",
      "Ggrep",
      "GMove",
      "GRename",
      "GDelete",
      "GBrowse",
      "Gclog",
    },
  }
end
