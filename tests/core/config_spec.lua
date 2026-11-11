local env = require("tests.helpers.env")

local function fresh_config(files)
  local dir = env.tmpdir("userconf")
  for name, content in pairs(files or {}) do
    env.write(dir .. "/" .. name .. ".lua", content)
  end
  vim.env.WRAITHVIM_CONFIG_DIR = dir
  package.loaded["wraithvim.core.config"] = nil
  -- Silence notifications from validation problems.
  vim.notify = function() end
  return require("wraithvim.core.config"), dir
end

describe("core.config", function()
  local saved_dir = vim.env.WRAITHVIM_CONFIG_DIR

  after_each(function()
    vim.env.WRAITHVIM_CONFIG_DIR = saved_dir
  end)

  it("uses defaults when no user files exist", function()
    local config = fresh_config()
    local cfg = config.setup()
    local defaults = require("wraithvim.config.defaults")
    assert.equals(defaults.options.leader, cfg.options.leader)
    assert.equals("default", cfg.ui.preset)
    assert.is_true(cfg.ui.explorer.enabled)
    assert.same({}, config.problems)
  end)

  it("resolves the user directory from XDG_CONFIG_HOME", function()
    vim.env.WRAITHVIM_CONFIG_DIR = nil
    local old = vim.env.XDG_CONFIG_HOME
    vim.env.XDG_CONFIG_HOME = "/tmp/xdg-test"
    package.loaded["wraithvim.core.config"] = nil
    assert.equals("/tmp/xdg-test/wraithvim", require("wraithvim.core.config").dir())
    vim.env.XDG_CONFIG_HOME = old
  end)

  it("lets user files override defaults", function()
    local config = fresh_config({
      options = "return { format = { on_save = true }, opt = { relativenumber = true } }",
      ui = "return { explorer = { width = 42 }, theme = { style = 'storm' } }",
    })
    local cfg = config.setup()
    assert.is_true(cfg.options.format.on_save)
    assert.equals(1000, cfg.options.format.timeout_ms) -- untouched sibling keeps default
    assert.is_true(cfg.options.opt.relativenumber)
    assert.equals(42, cfg.ui.explorer.width)
    assert.equals("storm", cfg.ui.theme.style)
    assert.same({}, config.problems)
  end)

  it("applies presets below user settings", function()
    local config = fresh_config({ ui = "return { preset = 'minimal', statusline = { lsp = true } }" })
    local cfg = config.setup()
    assert.is_false(cfg.ui.tabline.enabled) -- from preset
    assert.is_false(cfg.ui.explorer.auto_open) -- from preset
    assert.is_true(cfg.ui.statusline.lsp) -- user wins over preset
  end)

  it("reports an unknown preset and falls back to default", function()
    local config = fresh_config({ ui = "return { preset = 'fancy' }" })
    local cfg = config.setup()
    assert.is_true(cfg.ui.tabline.enabled)
    assert.matches("unknown preset", table.concat(config.problems, "\n"))
  end)

  it("replaces wrongly typed values by defaults and reports them", function()
    local config = fresh_config({ ui = "return { explorer = { width = 'wide' } }" })
    local cfg = config.setup()
    assert.equals(30, cfg.ui.explorer.width)
    assert.matches("ui.explorer.width: expected number, got string", table.concat(config.problems, "\n"))
  end)

  it("reports unknown keys (typos)", function()
    local config = fresh_config({ options = "return { formatt = {} }" })
    config.setup()
    assert.matches("options.formatt: unknown option", table.concat(config.problems, "\n"))
  end)

  it("survives syntax errors, runtime errors and non-table returns", function()
    local config = fresh_config({
      options = "return {",
      ui = "error('boom')",
      languages = "return 42",
    })
    local cfg = config.setup()
    local problems = table.concat(config.problems, "\n")
    assert.matches("options.lua: syntax error", problems)
    assert.matches("ui.lua: runtime error", problems)
    assert.matches("languages.lua: must return a table", problems)
    assert.is_true(cfg.ui.explorer.enabled)
  end)

  it("accepts boolean shorthand and custom profiles in languages.lua", function()
    local config = fresh_config({
      languages = "return { go = false, zig = { filetypes = { 'zig' } } }",
    })
    local cfg = config.setup()
    assert.is_false(cfg.languages.go.enabled)
    assert.same({ "zig" }, cfg.languages.zig.filetypes)
  end)

  it("separates plugin specs from named plugin options", function()
    local config = fresh_config({
      plugins = "return { disable = { 'flash.nvim' }, { 'folke/todo-comments.nvim', opts = {} } }",
    })
    local cfg = config.setup()
    assert.same({ "flash.nvim" }, cfg.plugins.disable)
    assert.equals("folke/todo-comments.nvim", cfg.plugins.specs[1][1])
  end)

  it("loads keymaps.lua lazily with entries and a disable list", function()
    local config = fresh_config({
      keymaps = "vim.g.wraith_keymaps_loaded = true\nreturn { disable = { 's' }, { 'n', '<leader>zz', '<cmd>echo 1<cr>', desc = 'x' } }",
    })
    config.setup()
    assert.is_nil(vim.g.wraith_keymaps_loaded)
    local km = config.load_keymaps()
    assert.is_true(vim.g.wraith_keymaps_loaded)
    assert.same({ "s" }, km.disable)
    assert.equals("<leader>zz", km.entries[1][2])
  end)

  it("gives explicit setup overrides precedence over user files", function()
    local config = fresh_config({ ui = "return { explorer = { width = 42 } }" })
    local cfg = config.setup({ ui = { explorer = { width = 50 } } })
    assert.equals(50, cfg.ui.explorer.width)
  end)
end)
