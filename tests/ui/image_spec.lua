describe("image preview", function()
  local function spec(ui)
    vim.notify = function() end
    package.loaded["wraithvim.core.config"] = nil
    local cfg = require("wraithvim.core.config").setup({ ui = ui or {} })
    return require("wraithvim.plugins.ui.image")(cfg)
  end

  it("loads snacks.nvim only when an image file is opened", function()
    local s = spec()
    assert.equals("folke/snacks.nvim", s[1])
    assert.is_true(s.enabled)
    assert.is_nil(s.lazy)
    assert.equals("BufReadCmd", s.event[1].event)
    for _, p in ipairs({ "*.png", "*.PNG", "*.jpg", "*.svg", "*.ico", "*.webp", "*.gif" }) do
      assert.is_true(vim.tbl_contains(s.event[1].pattern, p), p)
    end
  end)

  it("enables only the image module, for the same formats", function()
    local s = spec()
    assert.same({ "image" }, vim.tbl_keys(s.opts))
    assert.is_false(s.opts.image.doc.enabled)
    assert.equals(#s.event[1].pattern, #s.opts.image.formats)
    for i, ext in ipairs(s.opts.image.formats) do
      assert.equals("*." .. ext, s.event[1].pattern[i])
    end
  end)

  it("can be turned off in ui.lua", function()
    assert.is_false(spec({ image = { enabled = false } }).enabled)
  end)
end)
