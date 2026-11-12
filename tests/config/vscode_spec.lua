local env = require("tests.helpers.env")

local function setup_with(keymaps_lua)
  vim.notify = function() end
  local dir = env.tmpdir("vscode")
  env.write(dir .. "/keymaps.lua", keymaps_lua)
  vim.env.WRAITHVIM_CONFIG_DIR = dir
  package.loaded["wraithvim.core.config"] = nil
  require("wraithvim.core.config").setup()
  vim.g.mapleader = " "
  require("wraithvim.config.keymaps").setup()
end

local function mapped(mode, lhs)
  return vim.fn.maparg(lhs, mode) ~= ""
end

describe("VS Code keymap preset", function()
  local vscode = require("wraithvim.config.vscode")

  it("is off by default", function()
    setup_with("return {}")
    assert.is_false(mapped("n", "<C-z>"))
    assert.is_false(mapped("x", "<C-c>"))
    assert.equals("", vim.o.keymodel)
  end)

  it("adds VS Code shortcuts and VS Code-style selection", function()
    setup_with('return { preset = "vscode" }')
    for _, m in ipairs({
      { "n", "<C-z>" },
      { "i", "<C-z>" },
      { "n", "<C-/>" },
      { "n", "<C-_>" },
      { "n", "<A-Down>" },
      { "x", "<C-c>" },
      { "s", "<C-c>" },
      { "n", "<C-Space>" },
      { "t", "<C-`>" },
      { "n", "<F12>" },
    }) do
      assert.is_true(mapped(m[1], m[2]), m[1] .. " " .. m[2])
    end
    -- Select-mode twins switch to Visual mode before running Visual commands.
    assert.matches("^<C%-G>", vim.fn.maparg("<C-c>", "s"))
    assert.equals("startsel,stopsel", vim.o.keymodel)
    assert.equals("mouse,key", vim.o.selectmode)
    assert.equals("exclusive", vim.o.selection)
  end)

  it("honours the disable list", function()
    setup_with('return { preset = "vscode", disable = { "<C-w>", { "n", "<C-z>" } } }')
    assert.is_false(mapped("n", "<C-w>"))
    assert.is_false(mapped("n", "<C-z>"))
    assert.is_true(mapped("i", "<C-z>"))
  end)

  it("warns about an unknown preset", function()
    local msgs = {}
    setup_with('return { preset = "emacs" }')
    vim.notify = function(m)
      msgs[#msgs + 1] = m
    end
    vim.wait(200, function()
      return #msgs > 0
    end)
    assert.matches('unknown preset "emacs"', table.concat(msgs, "\n"))
    assert.is_false(mapped("n", "<C-z>"))
  end)

  it("keeps keys that keymaps.lua maps itself", function()
    setup_with([[
      vim.keymap.set("n", "<C-n>", "<cmd>let g:mine = 1<cr>", { desc = "mine" })
      vim.opt.selection = "inclusive"
      return { preset = "vscode" }
    ]])
    assert.equals("mine", vim.fn.maparg("<C-n>", "n", false, true).desc)
    assert.equals("inclusive", vim.o.selection)
    -- Neovim's own default mappings are still replaced by the preset.
    assert.is_not.matches("snippet", vim.fn.maparg("<Tab>", "s", false, true).desc or "")
  end)

  it("matches disabled keys however they are spelled", function()
    pcall(vim.keymap.del, "s", "<C-c>") -- left by earlier tests
    setup_with('return { preset = "vscode", disable = { "<c-c>", "<Leader>CA" } }')
    assert.is_false(mapped("s", "<C-c>")) -- Select mode is filtered only by is_disabled
    assert.is_true(require("wraithvim.config.keymaps").is_disabled("n", "<leader>CA")) -- buffer-local LSP keys
  end)

  it("has a description for every mapping and no duplicates with the defaults", function()
    local seen = {}
    local keymaps = require("wraithvim.config.keymaps")
    for _, list in ipairs({ keymaps.defaults(), vscode.mappings() }) do
      for _, e in ipairs(list) do
        assert.is_string(e.desc)
        for _, mode in ipairs(type(e[1]) == "table" and e[1] or { e[1] }) do
          local key = mode .. " " .. e[2]
          assert.is_nil(seen[key], "duplicate " .. key)
          seen[key] = true
        end
      end
    end
  end)

  it("is documented in docs/keymaps.md", function()
    local doc = env.read(env.root .. "/docs/keymaps.md")
    for _, e in ipairs(vscode.mappings()) do
      local documented = doc:find("`" .. e[2] .. "`", 1, true) or doc:find("`` " .. e[2] .. " ``", 1, true)
      assert.is_truthy(documented, e[2] .. " not documented")
    end
  end)
end)
