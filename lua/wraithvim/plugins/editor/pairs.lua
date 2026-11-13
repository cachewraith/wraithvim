-- Auto-close brackets and quotes like VS Code: `{` gives `{}`, typing the
-- closer steps over it, Backspace between a pair deletes both, and Enter
-- between `{}` opens an indented line.
return function(_)
  -- Pair only before whitespace, the line end or a closer, as VS Code does:
  -- `(` typed in front of a word stays a lone `(`. ("\n" = line end.)
  local before = "[%s)%]}>;:.,=`\n]"
  local open = "[^\\]" .. before
  -- Quotes also not right after a letter or digit (don't, x').
  local quote = "[^%w\\]" .. before
  return {
    "nvim-mini/mini.pairs",
    event = "InsertEnter",
    opts = {
      modes = { insert = true, command = false, terminal = false },
      mappings = {
        ["("] = { action = "open", pair = "()", neigh_pattern = open },
        ["["] = { action = "open", pair = "[]", neigh_pattern = open },
        ["{"] = { action = "open", pair = "{}", neigh_pattern = open },
        ['"'] = { action = "closeopen", pair = '""', neigh_pattern = quote, register = { cr = false } },
        ["'"] = { action = "closeopen", pair = "''", neigh_pattern = quote, register = { cr = false } },
        ["`"] = { action = "closeopen", pair = "``", neigh_pattern = quote, register = { cr = false } },
      },
    },
  }
end
