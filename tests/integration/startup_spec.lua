-- Full WraithVim in headless child processes (real init.lua, installed plugins).

local env = require("tests.helpers.env")
local gh = require("tests.helpers.git")

local function run(code, opts)
  local res, err = env.headless(code, opts)
  assert(res ~= nil, err)
  return res, err
end

describe("startup", function()
  it("starts without errors and loads almost nothing eagerly", function()
    local res, messages = run([[
      local loaded = {}
      for name, p in pairs(require("lazy.core.config").plugins) do
        if p._.loaded then loaded[#loaded + 1] = name end
      end
      table.sort(loaded)
      return { loaded = loaded, colors = vim.g.colors_name, leader = vim.g.mapleader, mouse = vim.o.mouse,
               problems = require("wraithvim.core.config").problems }
    ]])
    assert.same({ "lazy.nvim", "tokyonight.nvim" }, res.loaded)
    assert.equals("tokyonight-night", res.colors)
    assert.equals(" ", res.leader)
    assert.equals("a", res.mouse)
    assert.same({}, res.problems)
    assert.is_nil(messages:find("E%d+:"), messages)
  end)

  it("defines every :Wraith command and the core keymaps", function()
    local res = run([[
      local names = vim.tbl_keys(require("wraithvim.config.commands").definitions())
      local missing = {}
      for _, n in ipairs(names) do
        if vim.fn.exists(":" .. n) ~= 2 then missing[#missing + 1] = n end
      end
      local maps = {}
      for _, lhs in ipairs({ "<leader>ee", "<leader>ff", "<leader>fg", "<leader>gs", "<leader>tt", "<leader>bd" }) do
        maps[lhs] = vim.fn.maparg(lhs, "n") ~= ""
      end
      return { missing = missing, maps = maps }
    ]])
    assert.same({}, res.missing)
    for lhs, present in pairs(res.maps) do
      assert.is_true(present, lhs)
    end
  end)

  it("applies user configuration from ~/.config/wraithvim", function()
    local dir = env.tmpdir("user")
    env.write(dir .. "/ui.lua", "return { preset = 'minimal', theme = { style = 'storm' } }")
    env.write(dir .. "/options.lua", "vim.opt.wrap = true\nreturn { opt = { relativenumber = true } }")
    env.write(dir .. "/plugins.lua", "return { disable = { 'flash.nvim' } }")
    env.write(dir .. "/keymaps.lua", "return { { 'n', '<leader>zz', '<cmd>echo 1<cr>', desc = 'zz' } }")
    local res = run(
      [[
      local plugins = require("lazy.core.config").plugins
      return { bufferline = plugins["bufferline.nvim"] ~= nil, flash = plugins["flash.nvim"] ~= nil,
               colors = vim.g.colors_name, wrap = vim.o.wrap, rnu = vim.o.relativenumber,
               zz = vim.fn.maparg("<leader>zz", "n") ~= "", s = vim.fn.maparg("s", "n") ~= "" }
    ]],
      { env = { WRAITHVIM_CONFIG_DIR = dir } }
    )
    assert.is_false(res.bufferline) -- minimal preset disables the tabline plugin
    assert.is_false(res.flash)
    assert.is_false(res.s) -- flash mapping skipped with the plugin
    assert.equals("tokyonight-storm", res.colors)
    assert.is_true(res.wrap)
    assert.is_true(res.rnu)
    assert.is_true(res.zz)
    vim.fn.delete(dir, "rf")
  end)

  it("keeps working with a broken user configuration", function()
    local dir = env.tmpdir("broken")
    env.write(dir .. "/options.lua", "return {")
    env.write(dir .. "/ui.lua", "return { explorer = { width = 'wide' } }")
    env.write(dir .. "/keymaps.lua", "return { { 'n' } }")
    local res, messages = run(
      [[
      return { problems = require("wraithvim.core.config").problems, width = require("wraithvim.core.config").get().ui.explorer.width,
               tt = vim.fn.maparg("<leader>tt", "n") ~= "" }
    ]],
      { env = { WRAITHVIM_CONFIG_DIR = dir }, wait_ms = 300 }
    )
    assert.equals(2, #res.problems)
    assert.equals(30, res.width)
    assert.is_true(res.tt)
    assert.matches("configuration problems", messages)
    assert.matches("keymaps.lua entry #1", messages)
    vim.fn.delete(dir, "rf")
  end)

  it("lazy-loads editing plugins when a file is opened", function()
    local res = run(
      [[
      vim.wait(500, function() return package.loaded["gitsigns"] ~= nil end)
      local p = require("lazy.core.config").plugins
      return { gitsigns = p["gitsigns.nvim"]._.loaded ~= nil, lsp = p["nvim-lspconfig"]._.loaded ~= nil,
               blink = p["blink.cmp"]._.loaded ~= nil, telescope = p["telescope.nvim"]._.loaded ~= nil,
               ts = vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil }
    ]],
      { args = { env.root .. "/lua/wraithvim/init.lua" } }
    )
    assert.is_true(res.gitsigns)
    assert.is_true(res.lsp)
    assert.is_true(res.blink)
    assert.is_true(res.ts)
    assert.is_false(res.telescope) -- still not needed
  end)

  it("passes its own health check without errors", function()
    local res = run([[
      vim.cmd("checkhealth wraithvim")
      return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    ]])
    assert.matches("WraithVim: core", res)
    assert.is_nil(res:find("ERROR"), res)
  end)
end)

describe("features in a real session", function()
  local dir

  before_each(function()
    dir = gh.repo()
    env.write(dir .. "/a.lua", "local a = 1\nreturn a\n")
    env.write(dir .. "/b.txt", "b\n")
    gh.commit_all(dir, "init")
    env.write(dir .. "/a.lua", "local a = 2\nreturn a\n")
  end)

  after_each(function()
    vim.fn.delete(dir, "rf")
  end)

  it("explorer, search, git signs, fugitive and diffview work", function()
    local res = run(
      [[
      local out = {}
      vim.cmd.edit("a.lua")
      vim.wait(5000, function()
        local d = vim.b.gitsigns_status_dict
        return d ~= nil and d.changed ~= nil
      end, 20)
      out.signs = vim.b.gitsigns_status_dict and vim.b.gitsigns_status_dict.changed or -1
      out.head = vim.b.gitsigns_head

      require("wraithvim.features.explorer").toggle()
      -- neo-tree renders asynchronously.
      vim.wait(3000, function()
        for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          local b = vim.api.nvim_win_get_buf(w)
          if vim.bo[b].filetype == "neo-tree" then
            out.tree = table.concat(vim.api.nvim_buf_get_lines(b, 0, -1, false), "\n")
            return out.tree:find("a.lua", 1, true) ~= nil
          end
        end
      end, 20)
      require("wraithvim.features.explorer").toggle()

      require("wraithvim.features.search").find_files()
      vim.wait(2000, function() return vim.bo.filetype == "TelescopePrompt" end, 20)
      out.telescope = vim.bo.filetype
      vim.cmd("stopinsert")
      require("telescope.actions").close(vim.api.nvim_get_current_buf())

      vim.cmd.edit("a.lua")
      require("wraithvim.features.git").status()
      out.fugitive = vim.bo.filetype
      vim.cmd("close")

      require("wraithvim.features.git").diff()
      vim.wait(5000, function()
        local v = require("diffview.lib").get_current_view()
        return v ~= nil and v.files ~= nil and #v.files.working > 0
      end, 20)
      local view = require("diffview.lib").get_current_view()
      out.diffview = view and #view.files.working or 0
      require("wraithvim.features.git").diff_close()
      return out
    ]],
      { cwd = dir, wait_ms = 300 }
    )
    assert.equals(1, res.signs)
    assert.equals("main", res.head)
    assert.matches("a.lua", res.tree)
    assert.equals("TelescopePrompt", res.telescope)
    assert.equals("fugitive", res.fugitive)
    assert.equals(1, res.diffview)
  end)

  it("completion engine loads on insert and offers buffer words", function()
    local res = run(
      [[
      vim.cmd.edit("words.txt")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { "wraithword wraithwonder", "wrai" })
      vim.api.nvim_win_set_cursor(0, { 2, 4 })
      vim.cmd("startinsert!")
      local loaded_on_insert = package.loaded["blink.cmp"] ~= nil
      local cmp = require("blink.cmp")
      vim.wait(100)
      cmp.show()
      vim.wait(3000, function() return #require("blink.cmp.completion.list").items > 0 end, 20)
      local labels = {}
      for _, item in ipairs(require("blink.cmp.completion.list").items) do labels[#labels + 1] = item.label end
      return { loaded = loaded_on_insert, labels = labels }
    ]],
      { cwd = dir }
    )
    assert.is_true(res.loaded)
    assert.is_true(vim.tbl_contains(res.labels, "wraithword"), vim.inspect(res.labels))
  end)
end)

describe("language tooling", function()
  local has_clangd = vim.fn.executable("clangd") == 1
  local has_clang_format = vim.fn.executable("clang-format") == 1

  local function c_project()
    local dir = gh.repo()
    env.write(dir .. "/main.c", '#include <stdio.h>\nint main(void){printf("hi\\n");return 0;}\n')
    return dir
  end

  local it_lsp = has_clangd and it or pending
  it_lsp("starts clangd for C files and serves hover/definition", function()
    local dir = c_project()
    local res = run(
      [[
      vim.cmd.edit("main.c")
      vim.wait(15000, function()
        local c = vim.lsp.get_clients({ bufnr = 0 })[1]
        return c ~= nil and c.initialized
      end, 50)
      local client = vim.lsp.get_clients({ bufnr = 0 })[1]
      local maps = vim.fn.maparg("<leader>rn", "n") ~= "" and vim.fn.maparg("gd", "n") ~= ""
      local hover = vim.lsp.buf_request_sync(0, "textDocument/hover", vim.lsp.util.make_position_params(0, "utf-16"), 5000)
      return { name = client and client.name, maps = maps, statusline = vim.b.wraith_lsp, hover = hover ~= nil }
    ]],
      { cwd = dir, timeout = 60000 }
    )
    assert.equals("clangd", res.name)
    assert.is_true(res.maps)
    assert.is_true(res.hover)
    vim.fn.delete(dir, "rf")
  end)

  local it_fmt = has_clang_format and it or pending
  it_fmt("formats a C buffer with clang-format through conform", function()
    local dir = c_project()
    local res, messages = run(
      [[
      vim.cmd.edit("main.c")
      require("wraithvim.integrations.formatter").format()
      local conform = require("conform")
      local info = conform.get_formatter_info("clang-format", 0)
      return { lines = vim.api.nvim_buf_get_lines(0, 0, -1, false), info = info,
               formatters = vim.tbl_map(function(f) return f.name end, conform.list_formatters_to_run(0)) }
    ]],
      { cwd = dir, timeout = 60000 }
    )
    local diag = vim.inspect(res) .. "\nmessages:\n" .. tostring(messages)
    res = res.lines
    assert.is_true(#res > 2, diag) -- the one-line body was expanded
    assert.matches('printf%("hi\\n"%);', table.concat(res, "\n"))
    vim.fn.delete(dir, "rf")
  end)

  it("format on save is opt-in", function()
    local dir = c_project()
    local original = env.read(dir .. "/main.c")
    run([[ vim.cmd.edit("main.c"); vim.cmd.write(); return true ]], { cwd = dir })
    assert.equals(original, env.read(dir .. "/main.c"))
    if has_clang_format then
      local user = env.tmpdir("fos")
      env.write(user .. "/options.lua", "return { format = { on_save = true } }")
      run(
        [[ vim.cmd.edit("main.c"); vim.cmd.write(); return true ]],
        { cwd = dir, env = { WRAITHVIM_CONFIG_DIR = user } }
      )
      assert.is_not.equal(original, env.read(dir .. "/main.c"))
    end
    vim.fn.delete(dir, "rf")
  end)

  it("explains missing language servers once", function()
    local dir = gh.repo()
    env.write(dir .. "/x.go", "package main\n")
    local _, messages = run([[ return true ]], { cwd = dir, args = { "x.go" }, wait_ms = 500 })
    if vim.fn.executable("gopls") == 0 then
      assert.matches("gopls %(go%) is not installed", messages)
    end
    vim.fn.delete(dir, "rf")
  end)
end)
