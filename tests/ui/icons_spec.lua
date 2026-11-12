local env = require("tests.helpers.env")
local icons = require("wraithvim.ui.icons")
local material = require("wraithvim.ui.material")

--- Every string leaf of a table, as { path, value }.
local function leaves(t, prefix, out)
  out = out or {}
  for k, v in pairs(t) do
    local path = (prefix and (prefix .. ".") or "") .. tostring(k)
    if type(v) == "table" then
      leaves(v, path, out)
    else
      out[#out + 1] = { path, v }
    end
  end
  return out
end

describe("ui icons", function()
  it("has a visible glyph for every Nerd Font icon", function()
    for _, leaf in ipairs(leaves(icons.nerd)) do
      assert.is_truthy(vim.trim(leaf[2]) ~= "", "empty icon: " .. leaf[1])
    end
    for _, style in ipairs({ "default", "slant", "round" }) do
      for _, leaf in ipairs(leaves(icons.separators(style, true))) do
        assert.is_truthy(leaf[2] ~= "", ("empty %s separator: %s"):format(style, leaf[1]))
      end
    end
  end)

  it("keeps Nerd Font glyphs out of the source as raw characters", function()
    -- Private-use characters get stripped by tools; write them as \u{...}.
    local files = vim.fs.find(function(name)
      return name:match("%.lua$") ~= nil
    end, { path = env.root .. "/lua", type = "file", limit = math.huge })
    assert.is_true(#files > 20)
    for _, file in ipairs(files) do
      local text = env.read(file)
      -- U+E000-U+F8FF and U+F0000+ in UTF-8 (LuaJIT has no utf8 library).
      assert.is_nil(text:find("\238[\128-\191]") or text:find("\239[\128-\163]") or text:find("\243[\176-\191]"), file)
    end
  end)

  it("gives folders and well-known files Material icons and colors", function()
    local src_icon, src_hl = material.folder("src", false)
    assert.equals(icons.nerd.folder.closed, src_icon)
    assert.equals("WraithIconGreen", src_hl)
    assert.equals(icons.nerd.folder.open, (material.folder("src", true)))
    local docs_icon, docs_hl = material.folder("Docs", false)
    assert.not_equals(icons.nerd.folder.closed, docs_icon)
    assert.equals("WraithIconBlue", docs_hl)
    assert.equals("WraithIconFolder", select(2, material.folder("editor", false)))

    local readme = { text = "x", highlight = "Normal" }
    material.provider(readme, { type = "file", name = "README.md" })
    assert.equals("WraithIconBlue", readme.highlight)
    assert.not_equals("x", readme.text)

    material.define_highlights()
    assert.equals(tonumber("66bb6a", 16), vim.api.nvim_get_hl(0, { name = "WraithIconGreen" }).fg)
  end)
end)
