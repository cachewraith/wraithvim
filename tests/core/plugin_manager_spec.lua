local pm = require("wraithvim.core.plugin_manager")

local function cfg_with(overrides)
  vim.notify = function() end
  package.loaded["wraithvim.core.config"] = nil
  return require("wraithvim.core.config").setup(overrides)
end

describe("core.plugin_manager", function()
  it("derives lazy.nvim names from specs", function()
    assert.equals("flash.nvim", pm.spec_name({ "folke/flash.nvim" }))
    assert.equals("custom", pm.spec_name({ "a/b", name = "custom" }))
    assert.equals("repo", pm.spec_name({ url = "https://example.com/x/repo.git" }))
    assert.equals("plain.nvim", pm.spec_name("owner/plain.nvim"))
  end)

  it("builds unique, lazily-loaded specs", function()
    local specs = pm.build_spec(cfg_with())
    local seen = {}
    for _, spec in ipairs(specs) do
      local name = pm.spec_name(spec)
      assert.is_nil(seen[name], "duplicate spec " .. tostring(name))
      seen[name] = true
      -- Nothing may load eagerly at startup.
      assert.is_not.equal(false, spec.lazy, name .. " is not lazy")
    end
    for _, required in ipairs({
      "tokyonight.nvim",
      "lualine.nvim",
      "bufferline.nvim",
      "neo-tree.nvim",
      "telescope.nvim",
      "flash.nvim",
      "blink.cmp",
      "nvim-lspconfig",
      "gitsigns.nvim",
      "vim-fugitive",
      "diffview.nvim",
      "nvim-treesitter",
      "conform.nvim",
      "nvim-web-devicons",
    }) do
      assert.is_true(seen[required], required .. " missing")
    end
  end)

  it("every plugin has a lazy-load trigger or is loaded on require", function()
    -- Loaded by `:colorscheme`, as a dependency, or by keymaps calling require().
    local on_require = { ["tokyonight.nvim"] = true, ["nvim-web-devicons"] = true, ["flash.nvim"] = true }
    for _, spec in ipairs(pm.build_spec(cfg_with())) do
      local name = pm.spec_name(spec)
      local trigger = spec.event or spec.cmd or spec.ft or spec.keys or on_require[name]
      assert.is_truthy(trigger, name .. " has no trigger")
    end
  end)

  it("disables plugins listed in plugins.disable", function()
    local specs = pm.build_spec(cfg_with({ plugins = { disable = { "flash.nvim" } } }))
    for _, spec in ipairs(specs) do
      if pm.spec_name(spec) == "flash.nvim" then
        assert.is_false(spec.enabled)
      end
    end
  end)

  it("appends user specs after the distribution's so lazy.nvim merges them", function()
    local specs = pm.build_spec(cfg_with({ plugins = { { "folke/todo-comments.nvim", opts = {} } } }))
    assert.equals("folke/todo-comments.nvim", specs[#specs][1])
  end)

  it("disables mason.nvim unless enabled", function()
    local function mason_enabled(cfg)
      for _, spec in ipairs(pm.build_spec(cfg)) do
        if pm.spec_name(spec) == "mason.nvim" then
          return spec.enabled
        end
      end
    end
    assert.is_false(mason_enabled(cfg_with()))
    assert.is_true(mason_enabled(cfg_with({ options = { mason = { enabled = true } } })))
  end)

  it("keeps netrw when the explorer is disabled", function()
    assert.is_true(vim.tbl_contains(pm.disabled_plugins(cfg_with()), "netrwPlugin"))
    local cfg = cfg_with({ ui = { explorer = { enabled = false } } })
    assert.is_false(vim.tbl_contains(pm.disabled_plugins(cfg), "netrwPlugin"))
  end)

  it("only runs :TSUpdate as a build step when parsers can be built", function()
    local spec
    for _, s in ipairs(pm.build_spec(cfg_with())) do
      if pm.spec_name(s) == "nvim-treesitter" then
        spec = s
      end
    end
    local ts = require("wraithvim.integrations.treesitter")
    local real_missing, real_cmd = ts.missing_requirements, vim.cmd
    local ran = false
    vim.cmd = function(c)
      ran = ran or c == "TSUpdate"
    end
    ts.missing_requirements = function()
      return { "tree-sitter CLI" }
    end
    spec.build()
    assert.is_false(ran)
    ts.missing_requirements = function()
      return {}
    end
    spec.build()
    assert.is_true(ran)
    ts.missing_requirements, vim.cmd = real_missing, real_cmd
  end)

  it("installs plugins outside the default lazy root", function()
    local bootstrap = require("wraithvim.core.bootstrap")
    assert.matches("/wraithvim/plugins$", bootstrap.plugin_root())
    assert.is_not.equal(vim.fn.stdpath("data") .. "/lazy", bootstrap.plugin_root())
  end)

  it("accepts the running Neovim version", function()
    assert.is_true(require("wraithvim.core.bootstrap").check_version())
  end)
end)
