local registry = require("wraithvim.languages.registry")
local languages = require("wraithvim.languages")

local plugins = vim.fs.joinpath(vim.fn.stdpath("data"), "wraithvim", "plugins")

local function cfg(langs)
  vim.notify = function() end
  package.loaded["wraithvim.core.config"] = nil
  languages.reset()
  return require("wraithvim.core.config").setup({ languages = langs or {} })
end

describe("languages", function()
  it("resolves every builtin profile with filetypes, servers and formatters", function()
    for _, name in ipairs(registry.builtin) do
      local p = assert(registry.resolve(name, { enabled = true }))
      assert.is_true(#p.filetypes > 0, name)
      assert.is_true(#p.parsers > 0, name)
      assert.is_true(next(p.servers) ~= nil, name .. " has no server")
      -- These servers format the file themselves (LSP fallback).
      local lsp_formats = { docker = true, prisma = true, swift = true, terraform = true, toml = true, zig = true }
      assert.is_true(next(p.formatters) ~= nil or lsp_formats[name] == true, name .. " has no formatter")
    end
  end)

  it("references servers that nvim-lspconfig defines", function()
    for _, name in ipairs(registry.builtin) do
      local p = registry.resolve(name, {})
      for server in pairs(p.servers) do
        local path = vim.fs.joinpath(plugins, "nvim-lspconfig", "lsp", server .. ".lua")
        assert.is_not_nil(vim.uv.fs_stat(path), server .. " is not an nvim-lspconfig config")
      end
    end
  end)

  it("references formatters that conform.nvim defines", function()
    for _, name in ipairs(registry.builtin) do
      local p = registry.resolve(name, {})
      for formatter in pairs(p.formatters) do
        local path = vim.fs.joinpath(plugins, "conform.nvim", "lua", "conform", "formatters", formatter .. ".lua")
        assert.is_not_nil(vim.uv.fs_stat(path), formatter .. " is not a conform formatter")
      end
    end
  end)

  it("enables only languages that are not disabled", function()
    local c = cfg({ go = { enabled = false }, python = false })
    local names = vim.tbl_map(function(p)
      return p.name
    end, languages.enabled(c))
    assert.is_false(vim.tbl_contains(names, "go"))
    assert.is_false(vim.tbl_contains(names, "python"))
    assert.is_true(vim.tbl_contains(names, "lua"))
  end)

  it("maps aliases onto their canonical profile", function()
    local c = cfg({ javascript = false, c = false })
    local names = vim.tbl_map(function(p)
      return p.name
    end, languages.enabled(c))
    assert.is_false(vim.tbl_contains(names, "typescript"))
    assert.is_false(vim.tbl_contains(names, "cpp"))
  end)

  it("lets users disable servers/formatters and add custom profiles", function()
    local c = cfg({
      php = { servers = { intelephense = false, phpactor = { cmd = "phpactor" } }, format = false },
      zig = { filetypes = { "zig" }, servers = { zls = { cmd = "zls" } }, formatters = { zigfmt = { cmd = "zig" } } },
    })
    local profiles = languages.enabled(c)
    local by = {}
    for _, p in ipairs(profiles) do
      by[p.name] = p
    end
    assert.is_nil(by.php.servers.intelephense)
    assert.is_not_nil(by.php.servers.phpactor)
    assert.same({}, by.php.formatters)
    assert.same({ "zig" }, by.zig.filetypes)
    assert.same({ "zigfmt" }, languages.formatters_by_ft(profiles).zig)
  end)

  it("reports unknown languages without crashing", function()
    local c = cfg({ cobol = { enabled = true } })
    local names = vim.tbl_map(function(p)
      return p.name
    end, languages.enabled(c))
    assert.is_false(vim.tbl_contains(names, "cobol"))
  end)

  it("builds conform formatters_by_ft without duplicates", function()
    local by_ft = languages.formatters_by_ft(languages.enabled(cfg()))
    assert.same({ "stylua" }, by_ft.lua)
    assert.same({ "prettier" }, by_ft.yaml)
    assert.same({ "prettier" }, by_ft.typescript)
    assert.same({ "ruff_format" }, by_ft.python)
  end)

  it("lists each formatter once even when shared by profiles", function()
    local count = 0
    for _, f in ipairs(languages.formatters(languages.enabled(cfg()))) do
      if f.name == "prettier" then
        count = count + 1
      end
    end
    assert.equals(1, count)
  end)
end)

describe("integrations.lsp", function()
  it("gives custom servers a cmd and filetypes", function()
    local lsp = require("wraithvim.integrations.lsp")
    local c = lsp.server_config({ name = "wraith_custom_ls", cmd = "custom-ls", filetypes = { "zig" }, config = {} })
    assert.same({ "custom-ls" }, c.cmd)
    assert.same({ "zig" }, c.filetypes)
  end)
end)

describe("integrations.treesitter", function()
  it("detects bundled parsers and rejects unknown ones", function()
    local ts = require("wraithvim.integrations.treesitter")
    assert.is_true(ts.has_parser("lua"))
    assert.is_false(ts.has_parser("definitely_not_a_language"))
    assert.is_true(ts.installed().lua)
  end)

  it("starts highlighting only for configured filetypes with a parser", function()
    cfg()
    local ts = require("wraithvim.integrations.treesitter")
    assert.is_true(vim.tbl_contains(ts.filetypes(), "lua"))
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "local x = 1" })
    assert.is_true(ts.attach(buf, "lua"))
    assert.is_false(ts.attach(vim.api.nvim_create_buf(true, false), "definitely_not_a_language"))
  end)
end)
