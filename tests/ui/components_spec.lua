local function setup(ui)
  vim.notify = function() end
  package.loaded["wraithvim.core.config"] = nil
  return require("wraithvim.core.config").setup({ ui = ui or {} })
end

describe("ui components", function()
  it("statusline avoids lualine's polling timers and uses redraw-time items", function()
    setup()
    local sl = require("wraithvim.ui.statusline")
    local opts = sl.opts()
    assert.equals(sl.idle_interval, opts.options.refresh.refresh_time)
    assert.equals(sl.idle_interval, opts.options.refresh.statusline)
    assert.is_true(opts.options.globalstatus)
    assert.equals("%3l:%-2v", opts.sections.lualine_z[1][1]())
    assert.equals("%P", opts.sections.lualine_y[1][1]())
    -- Refresh autocmds exist for mode changes.
    assert.is_true(#vim.api.nvim_get_autocmds({ group = "wraithvim_statusline_refresh", event = "ModeChanged" }) > 0)
  end)

  it("statusline sections follow the configuration", function()
    setup({ statusline = { lsp = false, diff = false, encoding = false } })
    local opts = require("wraithvim.ui.statusline").opts()
    assert.equals(1, #opts.sections.lualine_b) -- branch only
    assert.equals(1, #opts.sections.lualine_x) -- filetype only
  end)

  it("caches LSP client names per buffer", function()
    local sl = require("wraithvim.ui.statusline")
    local buf = vim.api.nvim_create_buf(true, false)
    sl.update_lsp(buf)
    assert.equals("", vim.b[buf].wraith_lsp)
  end)

  it("terminal statusline shows the shell and folder instead of term://", function()
    setup()
    local opts = require("wraithvim.ui.statusline").opts()
    local ext
    for _, e in ipairs(opts.extensions) do
      if type(e) == "table" then
        ext = e
      end
    end
    assert.same({ "wraithterm" }, ext.filetypes)
    vim.b.wraith_term_shell = "fish"
    vim.b.wraith_term_cwd = vim.fn.getcwd()
    assert.matches("fish$", ext.sections.lualine_b[1]())
    assert.is_truthy(ext.sections.lualine_c[1]():find(vim.fn.fnamemodify(vim.fn.getcwd(), ":~"), 1, true))
    assert.equals("click or i: type", ext.sections.lualine_x[1]())
  end)

  it("tabline closes buffers safely and shows the project header", function()
    setup()
    local tl = require("wraithvim.ui.tabline")
    local opts = tl.opts().options
    assert.is_function(opts.close_command)
    assert.is_function(opts.middle_mouse_command)
    assert.equals("buffer %d", opts.left_mouse_command)
    assert.equals("neo-tree", opts.offsets[1].filetype)
    assert.equals(opts.custom_areas.right, tl.header)
    vim.g.gitsigns_head = "main"
    local header = tl.header()
    assert.equals(vim.fs.basename(vim.fn.getcwd()), vim.trim(header[1].text))
    assert.matches("main", header[2].text)
  end)

  it("shows line blame by default, GitLens style, and can turn it off", function()
    setup()
    local opts = require("wraithvim.features.git").gitsigns_opts()
    assert.is_true(opts.current_line_blame)
    assert.matches("<author>, <author_time:%%R> • <summary>", opts.current_line_blame_formatter)
    setup({ line_blame = false })
    assert.is_false(require("wraithvim.features.git").gitsigns_opts().current_line_blame)
  end)

  it("tabline header can be disabled", function()
    setup({ tabline = { header = false } })
    assert.is_nil(require("wraithvim.ui.tabline").opts().options.custom_areas)
  end)

  it("explorer supports single click, folder jumps, keeps <Space> for the leader and watches files", function()
    setup({ explorer = { width = 40, position = "right" } })
    local ex = require("wraithvim.ui.explorer").opts()
    assert.equals(40, ex.window.width)
    assert.equals("right", ex.window.position)
    assert.is_function(ex.window.mappings["<LeftRelease>"])
    assert.equals("none", ex.window.mappings["<2-LeftMouse>"])
    assert.equals("none", ex.window.mappings["<space>"])
    assert.is_function(ex.window.mappings["}"][1])
    assert.is_function(ex.window.mappings["{"][1])
    assert.is_true(ex.filesystem.use_libuv_file_watcher)
    -- Nothing is hidden by default.
    assert.is_false(ex.filesystem.filtered_items.hide_dotfiles)
    assert.is_false(ex.filesystem.filtered_items.hide_gitignored)
    assert.same({}, ex.filesystem.filtered_items.hide_by_name)
    setup({ explorer = { watch = false, show_gitignored = false, hide = { ".git" } } })
    local items = require("wraithvim.ui.explorer").opts().filesystem.filtered_items
    assert.is_true(items.hide_gitignored)
    assert.same({ ".git" }, items.hide_by_name)
    assert.is_false(require("wraithvim.ui.explorer").opts().filesystem.use_libuv_file_watcher)
  end)

  it("explorer keeps the default double click when single click is off", function()
    setup({ explorer = { single_click = false } })
    local ex = require("wraithvim.ui.explorer").opts()
    assert.is_nil(ex.window.mappings["<LeftRelease>"])
  end)

  it("falls back to ASCII icons without a Nerd Font", function()
    setup({ icons = { nerd_font = false } })
    local icons = require("wraithvim.ui.icons")
    assert.equals(icons.ascii, icons.get())
    local ex = require("wraithvim.ui.explorer").opts()
    assert.equals("+", ex.default_component_configs.icon.folder_closed)
    assert.equals("?", ex.default_component_configs.git_status.symbols.untracked)
    assert.is_false(require("wraithvim.ui.statusline").opts().options.icons_enabled)
    local seps = icons.separators("slant", false)
    assert.equals("", seps.section.left)
  end)
end)
