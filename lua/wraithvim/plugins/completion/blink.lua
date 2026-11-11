-- Completion. Uses Neovim's vim.snippet with friendly-snippets; no LuaSnip needed.
return function(cfg)
  local border = cfg.ui.border
  return {
    "saghen/blink.cmp",
    -- Release tags ship prebuilt fuzzy-matcher binaries; otherwise the Lua matcher is used.
    version = "1.*",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = { "rafamadriz/friendly-snippets" },
    opts_extend = { "sources.default" },
    opts = {
      keymap = {
        preset = "enter",
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
      },
      appearance = { nerd_font_variant = "mono" },
      completion = {
        list = { selection = { preselect = false, auto_insert = false } },
        menu = { border = border },
        documentation = { auto_show = true, auto_show_delay_ms = 300, window = { border = border } },
      },
      signature = { enabled = true, window = { border = border } },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
      fuzzy = { implementation = "prefer_rust" },
    },
  }
end
