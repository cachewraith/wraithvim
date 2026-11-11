-- Luacheck configuration for WraithVim.
std = "luajit"
cache = false
-- Line length is StyLua's job (long strings cannot be wrapped).
max_line_length = false
codes = true

-- Neovim Lua writes to vim.bo/vim.wo/vim.b/vim.g fields routinely.
globals = { "vim" }

-- Plenary Busted test globals.
files["tests/**/*_spec.lua"] = {
  read_globals = { "describe", "it", "before_each", "after_each", "pending", "assert" },
}
files["tests/run.lua"] = { read_globals = { "arg" } }
files["scripts/benchmark.lua"] = { read_globals = { "arg" } }
