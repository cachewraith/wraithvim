-- Label-based jumps on `s`/`S`. Native f/t/F/T and `/` are left untouched.
return function(_)
  return {
    "folke/flash.nvim",
    opts = {
      modes = {
        char = { enabled = false },
        search = { enabled = false },
      },
    },
  }
end
