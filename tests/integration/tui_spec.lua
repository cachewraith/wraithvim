-- Real TUI in a pseudo-terminal: layout, mouse interaction and idle behaviour.
-- Mouse input is sent as SGR escape sequences through the terminal, exactly
-- like a terminal emulator would.

local env = require("tests.helpers.env")
local gh = require("tests.helpers.git")
local tui = require("tests.helpers.tui")

local function project()
  local dir = gh.repo()
  env.write(dir .. "/alpha.lua", "return 'alpha'\n")
  env.write(dir .. "/beta.lua", "return 'beta'\n")
  env.write(dir .. "/sub/gamma.lua", "return 'gamma'\n")
  local long = {}
  for i = 1, 300 do
    long[i] = "line " .. i
  end
  env.write(dir .. "/long.txt", table.concat(long, "\n") .. "\n")
  gh.commit_all(dir, "init")
  return dir
end

--- Screen position of a window's buffer line (0-based screen row, col).
local function line_pos(t, win, lnum)
  return t:lua(
    [[
    local win, lnum = ...
    local pos = vim.api.nvim_win_get_position(win)
    local top = vim.fn.line("w0", win)
    return { pos[1] + (lnum - top), pos[2] }
  ]],
    win,
    lnum
  )
end

local function tree_win(t)
  return t:lua([[
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "neo-tree" then return w end
    end
  ]])
end

local function tree_line(t, text)
  return t:lua(
    [[
    local win, text = ...
    for i, l in ipairs(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false)) do
      if l:find(text, 1, true) then return i end
    end
  ]],
    tree_win(t),
    text
  )
end

local function current_file(t)
  return t:lua("return vim.fn.expand('%:t')")
end

describe("TUI", function()
  local dir, t

  before_each(function()
    dir = project()
  end)

  after_each(function()
    if t then
      t:close()
      t = nil
    end
    vim.fn.delete(dir, "rf")
  end)

  it("shows explorer, buffer tabs with header, and an event-driven statusline", function()
    t = tui.spawn({ cwd = dir, args = { "alpha.lua", "beta.lua" } })
    assert.is_true(t:wait_for("package.loaded.lualine ~= nil and package.loaded['neo-tree'] ~= nil", 8000))
    assert.is_true(t:wait_for("vim.b.gitsigns_head ~= nil or vim.g.gitsigns_head ~= nil", 5000))
    assert.is_truthy(tree_win(t))
    t:sleep(200)
    local stl = t:lua("return vim.api.nvim_eval_statusline(vim.o.statusline, {}).str")
    assert.matches("NORMAL", stl)
    assert.matches("alpha.lua", stl)
    local tal = t:lua("return vim.api.nvim_eval_statusline(vim.o.tabline, { use_tabline = true }).str")
    assert.matches("WraithVim", tal)
    assert.matches("alpha.lua", tal)
    assert.matches("beta.lua", tal)
    assert.matches(vim.fs.basename(dir), tal)
    assert.matches("main", tal)

    t:keys("i")
    assert.is_true(t:wait_for("vim.api.nvim_eval_statusline(vim.o.statusline, {}).str:find('INSERT') ~= nil", 2000))
    t:keys("<Esc>")
    assert.is_true(t:wait_for("vim.api.nvim_eval_statusline(vim.o.statusline, {}).str:find('NORMAL') ~= nil", 2000))
  end)

  it("switches and closes buffers by clicking tabs", function()
    t = tui.spawn({ cwd = dir, args = { "alpha.lua", "beta.lua" } })
    assert.is_true(t:wait_for("package.loaded.bufferline ~= nil", 8000))
    t:sleep(300)
    local tal = t:lua("return vim.api.nvim_eval_statusline(vim.o.tabline, { use_tabline = true }).str")
    local col = vim.fn.strdisplaywidth(tal:sub(1, tal:find("beta.lua", 1, true) - 1)) + 2
    t:click(0, col)
    assert.is_true(t:wait_for("vim.fn.expand('%:t') == 'beta.lua'", 2000))

    t:click(0, col, "middle")
    assert.is_true(t:wait_for("vim.fn.buflisted(vim.fn.bufnr('beta.lua')) == 0", 2000))
    assert.equals("alpha.lua", current_file(t))
  end)

  it("opens files and toggles directories with a single click in the explorer", function()
    t = tui.spawn({ cwd = dir, args = { "alpha.lua" } })
    assert.is_true(t:wait_for("package.loaded['neo-tree'] ~= nil", 8000))
    t:sleep(500)
    local win = tree_win(t)

    local lnum = tree_line(t, "beta.lua")
    local pos = line_pos(t, win, lnum)
    t:click(pos[1], pos[2] + 6)
    assert.is_true(t:wait_for("vim.fn.expand('%:t') == 'beta.lua'", 2000))

    local before = t:lua("return vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(...))", win)
    lnum = tree_line(t, "sub")
    pos = line_pos(t, win, lnum)
    t:click(pos[1], pos[2] + 6)
    assert.is_true(
      t:wait_for(("vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(%d)) > %d"):format(win, before), 2000)
    )
    assert.is_truthy(tree_line(t, "gamma.lua"))
  end)

  it("resizes the explorer by dragging its separator without opening files", function()
    t = tui.spawn({ cwd = dir, args = { "alpha.lua" } })
    assert.is_true(t:wait_for("package.loaded['neo-tree'] ~= nil", 8000))
    t:sleep(500)
    local win = tree_win(t)
    -- Focus the tree first so a stray <LeftRelease> mapping would be noticed.
    t:lua("vim.api.nvim_set_current_win(...)", win)
    local width = t:lua("return vim.api.nvim_win_get_width(...)", win)
    t:drag(5, width, 5, width + 10) -- the separator column is just right of the tree
    assert.is_true(t:wait_for(("vim.api.nvim_win_get_width(%d) > %d"):format(win, width + 5), 2000))
    assert.equals("neo-tree", t:lua("return vim.bo.filetype"))
  end)

  it("scrolls with the mouse wheel and selects text by dragging", function()
    t = tui.spawn({ cwd = dir, args = { "long.txt" } })
    assert.is_true(t:wait_for("package.loaded['neo-tree'] ~= nil", 8000))
    t:sleep(300)
    local editor = t:lua("return vim.api.nvim_get_current_win()")
    local pos = t:lua("return vim.api.nvim_win_get_position(...)", editor)
    t:scroll(pos[1] + 5, pos[2] + 10, "down")
    t:scroll(pos[1] + 5, pos[2] + 10, "down")
    assert.is_true(t:wait_for(("vim.fn.line('w0', %d) > 1"):format(editor), 2000))

    t:drag(pos[1] + 2, pos[2] + 8, pos[1] + 2, pos[2] + 14)
    assert.is_true(t:wait_for("vim.fn.mode() == 'v'", 2000))
  end)

  it("opens Git branches from the statusline branch component", function()
    t = tui.spawn({ cwd = dir, args = { "alpha.lua" } })
    assert.is_true(t:wait_for("package.loaded.lualine ~= nil and vim.b.gitsigns_head == 'main'", 8000))
    t:sleep(300)
    local stl = t:lua("return vim.api.nvim_eval_statusline(vim.o.statusline, {}).str")
    local col = vim.fn.strdisplaywidth(stl:sub(1, stl:find("main", 1, true) - 1)) + 1
    t:click(t:lua("return vim.o.lines") - 2, col)
    assert.is_true(t:wait_for("vim.bo.filetype == 'TelescopePrompt'", 5000))
  end)

  it("shows a clickable dashboard on an empty start", function()
    t = tui.spawn({ cwd = dir })
    assert.is_true(t:wait_for("vim.bo.filetype == 'wraithdashboard'", 5000))
    -- The tab bar loads right after the first draw and shifts the window down a
    -- row; measure positions only once the UI has settled.
    assert.is_true(t:wait_for("package.loaded.bufferline ~= nil and package.loaded['which-key'] ~= nil", 5000))
    t:sleep(200)
    local row = t:lua([[
      for i, l in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
        if l:find("New file", 1, true) then return i end
      end
    ]])
    local pos = line_pos(t, t:lua("return vim.api.nvim_get_current_win()"), row)
    local text = t:lua("return vim.fn.getline(...)", row)
    local col = vim.fn.strdisplaywidth(text:match("^%s*"))
    t:click(pos[1], pos[2] + col + 2)
    assert.is_true(t:wait_for("vim.bo.filetype ~= 'wraithdashboard' and vim.bo.buftype == ''", 2000))
  end)

  it("toggles the terminal panel with <leader>t and focuses the editor on click", function()
    t = tui.spawn({ cwd = dir, args = { "alpha.lua" } })
    assert.is_true(t:wait_for("package.loaded['neo-tree'] ~= nil", 8000))
    t:keys(" t")
    assert.is_true(t:wait_for("vim.bo.buftype == 'terminal'", 3000))
    t:keys("<Esc><Esc>")
    -- Normal mode inside the terminal buffer (focus must stay in the terminal).
    assert.is_true(t:wait_for("vim.api.nvim_get_mode().mode == 'nt'", 2000))
    local editor = t:lua([[
      for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.fn.bufname(vim.api.nvim_win_get_buf(w)):find("alpha.lua") then return w end
      end
    ]])
    local pos = t:lua("return vim.api.nvim_win_get_position(...)", editor)
    t:click(pos[1], pos[2] + 3)
    assert.is_true(t:wait_for("vim.fn.expand('%:t') == 'alpha.lua'", 2000))
    t:keys(" t")
    assert.is_true(t:wait_for("vim.fn.bufwinid(require('wraithvim.features.terminal').panel.buf) == -1", 2000))
  end)

  it("opens the terminal at the bottom with Ctrl+Shift+`", function()
    t = tui.spawn({ cwd = dir, args = { "alpha.lua" } })
    assert.is_true(t:wait_for("package.loaded['neo-tree'] ~= nil", 8000))
    t:send("\27[96;6u") -- Ctrl+Shift+` (kitty keyboard protocol), right after startup
    assert.is_true(t:wait_for("vim.bo.buftype == 'terminal' and vim.fn.mode() == 't'", 3000))
    -- The explorer finishing its startup render must not pull focus back to the editor.
    t:sleep(800)
    assert.equals("terminal", t:lua("return vim.bo.buftype"))
    assert.equals("t", t:lua("return vim.fn.mode()"))
    -- Full-width panel below the editor and the explorer.
    local pos = t:lua("return vim.api.nvim_win_get_position(0)")
    local width = t:lua("return vim.api.nvim_win_get_width(0)")
    assert.is_true(pos[1] > 1, "terminal is not at the bottom")
    assert.equals(0, pos[2])
    assert.equals(t:lua("return vim.o.columns"), width)
    -- Pressing it again (from inside the terminal) keeps the same terminal.
    local buf = t:lua("return vim.api.nvim_get_current_buf()")
    t:send("\27[96;6u")
    t:sleep(200)
    assert.equals(buf, t:lua("return vim.api.nvim_get_current_buf()"))
    assert.equals(
      1,
      t:lua("return #vim.tbl_filter(function(b) return vim.bo[b].buftype == 'terminal' end, vim.api.nvim_list_bufs())")
    )
  end)

  it("terminal: header buttons, readable statusline, click to type", function()
    t = tui.spawn({ cwd = dir, args = { "alpha.lua" } })
    assert.is_true(t:wait_for("package.loaded.lualine ~= nil and package.loaded['neo-tree'] ~= nil", 8000))
    t:keys(" t")
    assert.is_true(t:wait_for("vim.bo.filetype == 'wraithterm' and vim.fn.mode() == 't'", 3000))
    t:sleep(300)
    local stl = t:lua("return vim.api.nvim_eval_statusline(vim.o.statusline, {}).str")
    assert.is_nil(stl:find("term://", 1, true))
    assert.is_nil(stl:find("[RO]", 1, true))
    assert.matches("bash", stl)
    local pos = t:lua("return vim.api.nvim_win_get_position(0)")
    -- Esc Esc to scroll/copy, then a click inside goes back to typing.
    t:keys("<Esc><Esc>")
    assert.is_true(t:wait_for("vim.fn.mode() ~= 't'", 2000))
    t:click(pos[1] + 3, pos[2] + 5)
    assert.is_true(t:wait_for("vim.fn.mode() == 't'", 2000))
    -- Header buttons: New opens a second terminal, Hide hides the panel.
    local bar = t:lua("return vim.api.nvim_eval_statusline(vim.wo.winbar, { winid = 0, use_winbar = true }).str")
    t:click(pos[1], pos[2] + vim.fn.strdisplaywidth(bar:sub(1, bar:find("New", 1, true) - 1)))
    assert.is_true(
      t:wait_for(
        "#vim.tbl_filter(function(b) return vim.bo[b].filetype == 'wraithterm' end, vim.api.nvim_list_bufs()) == 2",
        3000
      )
    )
    local pwin = t:lua("return require('wraithvim.features.terminal').panel.win")
    local ppos = t:lua("return vim.api.nvim_win_get_position(...)", pwin)
    local pbar =
      t:lua("return vim.api.nvim_eval_statusline(vim.wo[...].winbar, { winid = ..., use_winbar = true }).str", pwin)
    t:click(ppos[1], ppos[2] + vim.fn.strdisplaywidth(pbar:sub(1, pbar:find("Hide", 1, true) - 1)))
    assert.is_true(t:wait_for("not vim.api.nvim_win_is_valid(" .. pwin .. ")", 2000))
    assert.is_true(t:lua("return vim.api.nvim_buf_is_valid(require('wraithvim.features.terminal').panel.buf)"))
  end)

  it("shows notifications as floating windows that close themselves", function()
    t = tui.spawn({ cwd = dir, args = { "alpha.lua" } })
    assert.is_true(t:wait_for("vim.v.vim_did_enter == 1", 5000))
    t:lua("vim.notify('hello from the test', vim.log.levels.WARN, { title = 'Test' })")
    local find = [[(function()
      for _, w in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_config(w).relative ~= "" then
          local text = table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(w), 0, -1, false), "\n")
          if text:find("hello from the test", 1, true) then return true end
        end
      end
      return false
    end)()]]
    assert.is_true(t:wait_for(find, 2000))
    assert.is_true(t:wait_for("not " .. find, 5000)) -- default timeout is 3 s
  end)

  describe("VS Code preset", function()
    local function vscode_tui()
      local cfg = env.tmpdir("vscode-cfg")
      env.write(cfg .. "/keymaps.lua", 'return { preset = "vscode" }')
      t = tui.spawn({ cwd = dir, args = { "long.txt" }, env = { WRAITHVIM_CONFIG_DIR = cfg } })
      assert.is_true(t:wait_for("package.loaded['neo-tree'] ~= nil", 8000))
      t:sleep(300)
      t:lua("vim.cmd('wincmd l')")
      t:lua(
        "vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'one', 'two', 'three' }); vim.api.nvim_win_set_cursor(0, { 1, 0 })"
      )
      t:lua("vim.bo.commentstring = '-- %s'") -- plain text has no comment syntax
    end
    local function text()
      return table.concat(t:lua("return vim.api.nvim_buf_get_lines(0, 0, -1, false)"), "|")
    end

    it("edits with VS Code keys sent as real terminal sequences", function()
      vscode_tui()
      t:send("\27[1;3B") -- Alt+Down
      assert.is_true(t:wait_for("vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == 'two'", 2000), text())
      t:send("\26") -- Ctrl+Z
      assert.is_true(t:wait_for("vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == 'one'", 2000))
      t:send("\31") -- Ctrl+/ (classic encoding)
      assert.is_true(t:wait_for("vim.api.nvim_get_current_line() == '-- one'", 2000), text())
      t:send("\27[47;5u") -- Ctrl+/ (kitty keyboard protocol)
      assert.is_true(t:wait_for("vim.api.nvim_get_current_line() == 'one'", 2000))
      t:send("\27[1;2C\27[1;2C") -- Shift+Right twice
      assert.is_true(t:wait_for("vim.fn.mode() == 's'", 2000))
      t:send("X") -- typing replaces the selection
      assert.is_true(t:wait_for("vim.api.nvim_get_current_line() == 'Xe'", 2000), text())
      t:keys("<Esc>")
    end)

    it("opens panels with VS Code keys", function()
      vscode_tui()
      t:send("\2") -- Ctrl+B hides the explorer
      assert.is_true(
        t:wait_for(
          "vim.iter(vim.api.nvim_tabpage_list_wins(0)):all(function(w) return vim.bo[vim.api.nvim_win_get_buf(w)].filetype ~= 'neo-tree' end)",
          3000
        )
      )
      t:send("\0") -- Ctrl+` in classic terminals (NUL)
      assert.is_true(t:wait_for("vim.bo.buftype == 'terminal'", 3000))
      t:send("\0")
      assert.is_true(t:wait_for("vim.bo.buftype == ''", 3000))
      t:send("\16") -- Ctrl+P
      assert.is_true(t:wait_for("vim.bo.filetype == 'TelescopePrompt'", 5000))
      t:keys("<Esc>")
      t:keys("<Esc>")
      assert.is_true(t:wait_for("vim.bo.filetype ~= 'TelescopePrompt'", 3000))
      t:send("\27[102;6u") -- Ctrl+Shift+F (kitty keyboard protocol)
      assert.is_true(t:wait_for("vim.bo.filetype == 'TelescopePrompt'", 5000))
    end)
  end)

  it("shows key hints after pressing Space", function()
    t = tui.spawn({ cwd = dir, args = { "alpha.lua" } })
    assert.is_true(t:wait_for("package.loaded['which-key'] ~= nil", 8000))
    t:sleep(300)
    t:send(" ")
    local popup = [[(function()
      for _, w in ipairs(vim.api.nvim_list_wins()) do
        local b = vim.api.nvim_win_get_buf(w)
        if vim.api.nvim_win_get_config(w).relative ~= "" then
          local text = table.concat(vim.api.nvim_buf_get_lines(b, 0, -1, false), "\n")
          if text:find("Git", 1, true) and text:find("Find", 1, true) then return true end
        end
      end
      return false
    end)()]]
    assert.is_true(t:wait_for(popup, 3000))
    t:send("e") -- <leader>e toggles the explorer and closes the popup
    assert.is_true(t:wait_for("not " .. popup, 3000))
  end)

  it("uses no CPU while idle", function()
    t = tui.spawn({ cwd = dir, args = { "alpha.lua" } })
    assert.is_true(t:wait_for("package.loaded.lualine ~= nil and package.loaded['neo-tree'] ~= nil", 8000))
    t:sleep(1500)
    local pid = t:lua("return vim.fn.getpid()")
    local function ticks()
      local fields = vim.split(io.open("/proc/" .. pid .. "/stat"):read("*a"):match("%) (.*)"), " ")
      return tonumber(fields[12]) + tonumber(fields[13])
    end
    local before = ticks()
    t:sleep(5000)
    -- 1 tick = 10 ms; allow a little scheduler noise.
    assert.is_true(ticks() - before <= 2, "idle CPU ticks: " .. (ticks() - before))
  end)
end)
