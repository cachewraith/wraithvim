local env = require("tests.helpers.env")

local function setup_config(overrides)
  vim.notify = function() end
  package.loaded["wraithvim.core.config"] = nil
  return require("wraithvim.core.config").setup(overrides)
end

describe("config.keymaps", function()
  local keymaps = require("wraithvim.config.keymaps")

  it("has no duplicate (mode, lhs) pairs and every mapping has a description", function()
    local seen = {}
    for _, list in ipairs({ keymaps.defaults(), keymaps.lsp() }) do
      for _, e in ipairs(list) do
        assert.is_string(e.desc, "missing desc for " .. e[2])
        local modes = type(e[1]) == "table" and e[1] or { e[1] }
        for _, m in ipairs(modes) do
          local key = m .. " " .. e[2]
          -- LSP mappings are buffer-local and may refine a global one (none do today).
          assert.is_nil(seen[key], "duplicate mapping " .. key)
          seen[key] = true
        end
      end
    end
  end)

  it("keeps leader mappings inside the documented groups", function()
    local prefixes = vim.tbl_map(function(g)
      return g[1]
    end, keymaps.groups)
    local keymaps_mod = require("wraithvim.config.keymaps")
    local allowed_extra = { ["<leader>rn"] = true }
    for _, list in ipairs({ keymaps.defaults(), keymaps.lsp() }) do
      for _, e in ipairs(list) do
        if vim.startswith(e[2], "<leader>") and not allowed_extra[e[2]] and not keymaps_mod.is_quick(e[2]) then
          local ok = false
          for _, p in ipairs(prefixes) do
            ok = ok or vim.startswith(e[2], p)
          end
          assert.is_true(ok, e[2] .. " is outside every group")
        end
      end
    end
  end)

  it("recognises quick (single-key) leader mappings", function()
    assert.is_true(keymaps.is_quick("<leader>e"))
    assert.is_true(keymaps.is_quick("<leader><space>"))
    assert.is_true(keymaps.is_quick("<leader>/"))
    assert.is_false(keymaps.is_quick("<leader>ff"))
    assert.is_false(keymaps.is_quick("s"))
  end)

  it("shows keys in plain words", function()
    assert.equals("Space g Shift+P", keymaps.human("<leader>gP"))
    assert.equals("Space Space", keymaps.human("<leader><space>"))
    assert.equals("Ctrl+Shift+F", keymaps.human("<C-S-f>"))
    assert.equals("Shift+Alt+Down", keymaps.human("<S-A-Down>"))
    assert.equals("Ctrl+S", keymaps.human("<C-s>"))
    assert.equals("] h", keymaps.human("]h"))
    assert.equals("F12", keymaps.human("<F12>"))
  end)

  it("lists every action in the palette with its key", function()
    vim.env.WRAITHVIM_CONFIG_DIR = env.tmpdir("palette")
    setup_config()
    local items = keymaps.palette_items()
    local by_label = {}
    for _, it in ipairs(items) do
      by_label[it.label] = it.keys
      assert.is_function(it.run)
    end
    -- Plugin-backed mappings are skipped here (lazy.nvim is not set up), so
    -- check plain ones plus commands.
    assert.equals("Space x", by_label["Close tab"])
    assert.equals("Space t", by_label["Terminal"])
    assert.equals("Space u u", by_label["Update & tools: Update WraithVim"])
    assert.equals(":GitGraph", by_label["Command: Commit graph of the current branch"])
    assert.equals(":GitGraphAll", by_label["Command: Commit graph of all branches"])
    assert.equals("Alt+J", by_label["Jump 10 lines down"])
    assert.equals(":Update", by_label["Command: Update WraithVim and sync pinned plugins"])
    for label in pairs(by_label) do
      assert.is_nil(label:find("classic terminals", 1, true))
    end
  end)

  it("palette runs commands", function()
    local ran
    local real = vim.cmd
    vim.cmd = function(c)
      ran = c
    end
    for _, it in ipairs(keymaps.palette_items()) do
      if it.keys == ":Keys" then
        it.run()
      end
    end
    vim.cmd = real
    assert.equals("Keys", ran)
  end)

  it("documents every mapping in docs/keymaps.md", function()
    local doc = env.read(env.root .. "/docs/keymaps.md")
    assert.is_string(doc)
    for _, list in ipairs({ keymaps.defaults(), keymaps.lsp() }) do
      for _, e in ipairs(list) do
        local documented = doc:find("`" .. e[2] .. "`", 1, true) or doc:find("`` " .. e[2] .. " ``", 1, true)
        assert.is_truthy(documented, e[2] .. " not documented")
      end
    end
  end)

  it("applies defaults, honours the disable list and adds user entries", function()
    local dir = env.tmpdir("keys")
    env.write(
      dir .. "/keymaps.lua",
      [[
      return {
        disable = { "<leader>bd", { "n", "<leader>wv" } },
        { "n", "<leader>zz", "<cmd>let g:wraith_zz = 1<cr>", desc = "custom" },
      }
    ]]
    )
    vim.env.WRAITHVIM_CONFIG_DIR = dir
    setup_config()
    vim.g.mapleader = " "
    keymaps.setup()
    local function has(mode, lhs)
      return vim.fn.maparg(lhs, mode) ~= ""
    end
    assert.is_true(has("n", "<leader>t"))
    assert.is_true(has("n", "<leader>zz"))
    assert.is_false(has("n", "<leader>bd"))
    assert.is_false(has("n", "<leader>wv"))
    assert.is_true(keymaps.is_disabled("n", "<leader>bd"))
    assert.is_true(keymaps.is_disabled("n", "<leader>wv"))
    assert.is_false(keymaps.is_disabled("x", "<leader>wv"))
  end)

  it("skips mappings whose plugin is not available", function()
    vim.env.WRAITHVIM_CONFIG_DIR = env.tmpdir("nokeys")
    setup_config()
    vim.g.mapleader = " "
    keymaps.setup() -- lazy.nvim is not set up here, so no plugin is available
    assert.equals("", vim.fn.maparg("<leader>ff", "n"))
    assert.is_not.equal("", vim.fn.maparg("<leader>t", "n"))
  end)
end)
