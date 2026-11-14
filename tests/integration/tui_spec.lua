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
    local winbar = vim.wo[win].winbar ~= "" and 1 or 0
    return { pos[1] + winbar + (lnum - top), pos[2] }
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

  it("creates files from the explorer header, the right-click menu and the a key", function()
    t = tui.spawn({ cwd = dir, args = { "alpha.lua" } })
    assert.is_true(t:wait_for("package.loaded['neo-tree'] ~= nil", 8000))
    t:sleep(500)
    local win = tree_win(t)
    local header =
      t:lua("return vim.api.nvim_eval_statusline(vim.wo[...].winbar, { winid = ..., use_winbar = true }).str", win)
    assert.matches("File", header)
    assert.matches("Folder", header)

    -- Header button: creates in the project root, nested folders included.
    local pos = t:lua("return vim.api.nvim_win_get_position(...)", win)
    t:click(pos[1], pos[2] + 3)
    assert.is_true(t:wait_for("vim.fn.mode() == 'c'", 2000))
    t:keys("made/new.lua<CR>")
    assert.is_true(t:wait_for("vim.fn.expand('%:.') == 'made/new.lua'", 3000))
    assert.equals(1, t:lua("return vim.fn.filereadable('made/new.lua')"))

    -- Right click on a folder, first menu item (New File): prompt starts in it.
    local lnum = tree_line(t, "sub")
    local p = line_pos(t, win, lnum)
    t:click(p[1], p[2] + 6, "right")
    t:sleep(300)
    t:send("\27[B") -- Down as one escape sequence (keys() would split off the Esc)
    t:sleep(100)
    t:send("\r")
    assert.is_true(t:wait_for("vim.fn.mode() == 'c' and vim.fn.getcmdline() == 'sub/'", 2000))
    t:keys("menu.lua<CR>")
    assert.is_true(t:wait_for("vim.fn.expand('%:.') == 'sub/menu.lua'", 3000))

    -- a on a tree item.
    t:lua("vim.api.nvim_set_current_win(...)", win)
    t:wait_for(("vim.api.nvim_get_current_win() == %d"):format(win), 1000)
    t:lua("vim.api.nvim_win_set_cursor(0, { ..., 0 })", tree_line(t, "sub"))
    t:keys("a")
    assert.is_true(t:wait_for("vim.fn.mode() == 'c' and vim.fn.getcmdline() == 'sub/'", 2000))
    t:keys("key.lua<CR>")
    assert.is_true(t:wait_for("vim.fn.expand('%:.') == 'sub/key.lua'", 3000))
  end)

  it("opens suggestions only with Ctrl+Space, not while typing", function()
    t = tui.spawn({ cwd = dir, args = { "long.txt" } })
    assert.is_true(t:wait_for("vim.v.vim_did_enter == 1", 5000))
    t:lua("vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'wraithword wraithwonder', '' })")
    t:lua("vim.api.nvim_win_set_cursor(0, { 2, 0 })")
    t:keys("iwrai")
    assert.is_true(t:wait_for("vim.api.nvim_get_current_line() == 'wrai' and package.loaded['blink.cmp'] ~= nil", 3000))
    t:sleep(800)
    assert.is_false(t:lua("return require('blink.cmp').is_menu_visible()"))
    t:send("\0") -- Ctrl+Space as a terminal sends it
    assert.is_true(t:wait_for("require('blink.cmp').is_menu_visible()", 3000))
  end)

  it("opens a file left with unsaved edits by a crashed session from the explorer", function()
    -- A session that edited beta.lua without saving and was killed.
    vim
      .system({
        "nvim",
        "--headless",
        "--clean",
        "-c",
        "e beta.lua",
        "-c",
        "normal! Ounsaved()",
        "-c",
        "preserve",
        "-c",
        "lua vim.uv.kill(vim.uv.os_getpid(), 9)",
      }, { cwd = dir, env = env.env() })
      :wait()
    t = tui.spawn({ cwd = dir, args = { "alpha.lua" } })
    assert.is_true(t:wait_for("package.loaded['neo-tree'] ~= nil", 8000))
    t:sleep(500)
    local win = tree_win(t)
    local p = line_pos(t, win, tree_line(t, "beta.lua"))
    t:click(p[1], p[2] + 6)
    -- No "E325: ATTENTION" prompt or error: the edits are back, unsaved.
    assert.is_true(t:wait_for("vim.fn.expand('%:t') == 'beta.lua' and vim.bo.modified", 3000))
    assert.equals("unsaved()", t:lua("return vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]"))
    assert.is_false(vim.rpcrequest(t.chan, "nvim_get_mode").blocking)
    -- The old swap file is gone (this session's own is beta.lua.swo).
    local swap = t:lua("return vim.fn.stdpath('state') .. '/swap/' .. vim.fn.expand('%:p'):gsub('/', '%%') .. '.swp'")
    assert.is_nil(vim.uv.fs_stat(swap), swap)
  end)

  it("renames a file from the right-click menu", function()
    t = tui.spawn({ cwd = dir, args = { "alpha.lua" } })
    assert.is_true(t:wait_for("package.loaded['neo-tree'] ~= nil", 8000))
    t:sleep(500)
    local win = tree_win(t)
    local p = line_pos(t, win, tree_line(t, "beta.lua"))
    t:click(p[1], p[2] + 6, "right")
    t:sleep(300)
    -- Rename is the fourth item (New File, New Folder, Open to the Side, Rename).
    for _ = 1, 4 do
      t:send("\27[B")
      t:sleep(80)
    end
    t:send("\r")
    -- neo-tree's rename prompt opens (it failed with E565 inside :popup).
    assert.is_true(t:wait_for("vim.bo.filetype == 'neo-tree-popup' and vim.fn.mode() == 'i'", 2000))
    assert.is_false(t:lua("return vim.v.errmsg:find('E565') ~= nil"))
    t:keys("<C-u>gone.lua<CR>")
    assert.is_true(t:wait_for("vim.fn.filereadable('gone.lua') == 1 and vim.fn.filereadable('beta.lua') == 0", 3000))
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
    -- One wheel notch moves options.scroll.wheel (6) lines.
    local top = t:lua("return vim.fn.line('w0', ...)", editor)
    t:scroll(pos[1] + 5, pos[2] + 10, "down")
    assert.is_true(t:wait_for(("vim.fn.line('w0', %d) == %d"):format(editor, top + 6), 2000))
    t:scroll(pos[1] + 5, pos[2] + 10, "down")
    assert.is_true(t:wait_for(("vim.fn.line('w0', %d) == %d"):format(editor, top + 12), 2000))

    t:drag(pos[1] + 2, pos[2] + 8, pos[1] + 2, pos[2] + 14)
    assert.is_true(t:wait_for("vim.fn.mode() == 'v'", 2000))
  end)

  it("moves fast with the keyboard in files and in the explorer", function()
    t = tui.spawn({ cwd = dir, args = { "long.txt" } })
    assert.is_true(t:wait_for("package.loaded['neo-tree'] ~= nil", 8000))
    t:sleep(300)
    t:lua("vim.api.nvim_win_set_cursor(0, { 1, 0 })")
    t:send("\27j") -- Alt+j as a terminal sends it
    assert.is_true(t:wait_for("vim.fn.line('.') == 11", 2000))
    t:send("\4") -- Ctrl+d: half page, cursor kept in the middle
    assert.is_true(t:wait_for("vim.fn.line('.') > 11", 2000))
    assert.is_true(t:wait_for("math.abs(vim.fn.winline() - math.floor(vim.fn.winheight(0) / 2)) <= 1", 2000))

    local win = tree_win(t)
    -- .git is shown too (nothing is hidden), right above sub/.
    local git_line = tree_line(t, ".git")
    assert.is_truthy(git_line)
    t:lua("local w, l = ...; vim.api.nvim_set_current_win(w); vim.api.nvim_win_set_cursor(0, { l, 0 })", win, git_line)
    t:keys("}")
    local sub = tree_line(t, "sub")
    assert.is_true(t:wait_for(("vim.fn.line('.') == %d"):format(sub), 2000))
    t:keys("{")
    assert.is_true(t:wait_for(("vim.fn.line('.') < %d"):format(sub), 2000))
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

  it("shows the graph, changes and terminal in a side panel and moves between panels with Alt+number", function()
    t = tui.spawn({ cwd = dir, args = { "alpha.lua" } })
    assert.is_true(t:wait_for("package.loaded['neo-tree'] ~= nil", 8000))
    local side = "(require('wraithvim.features.panels').visible() or {}).view"
    -- Let the explorer finish its startup render (it puts focus back when done).
    assert.is_true(vim.wait(5000, function()
      return tree_win(t) ~= nil
    end, 50))
    t:sleep(300)
    t:keys(" sg")
    assert.is_true(t:wait_for("vim.bo.filetype == 'floggraph'", 5000))
    -- On the right edge of the screen.
    assert.equals(t:lua("return vim.o.columns"), t:lua("return vim.fn.win_screenpos(0)[2] + vim.fn.winwidth(0) - 1"))
    -- Alt+3 (ESC 3 in any terminal): the terminal, ready to type.
    t:send("\0273")
    assert.is_true(t:wait_for("vim.bo.buftype == 'terminal' and vim.fn.mode() == 't'", 3000))
    -- Alt+1 from inside the shell: back to the code.
    t:send("\0271")
    assert.is_true(t:wait_for("vim.fn.expand('%:t') == 'alpha.lua' and vim.fn.mode() == 'n'", 2000))
    t:send("\0272")
    assert.is_true(t:wait_for("vim.bo.filetype == 'floggraph'", 2000))
    -- One view at a time: changes replace the graph.
    t:keys(" sc")
    assert.is_true(t:wait_for(side .. " == 'changes'", 5000))
    assert.equals(
      0,
      t:lua([[return #vim.tbl_filter(function(w)
        return vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "floggraph"
      end, vim.api.nvim_tabpage_list_wins(0))]])
    )
    -- The bottom terminal moves to the side with the same shell.
    local shell = t:lua("return require('wraithvim.features.terminal').panel.buf")
    t:send("\0271")
    t:keys(" st")
    assert.is_true(t:wait_for(side .. " == 'terminal'", 3000))
    assert.equals(shell, t:lua("return require('wraithvim.features.terminal').panel.buf"))
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

  it("runs actions by name from the palette (Space p)", function()
    t = tui.spawn({ cwd = dir, args = { "alpha.lua" } })
    assert.is_true(t:wait_for("package.loaded['which-key'] ~= nil", 8000))
    t:sleep(300)
    t:keys(" p")
    assert.is_true(t:wait_for("vim.bo.filetype == 'TelescopePrompt'", 5000))
    t:sleep(200)
    t:send("graph")
    t:sleep(400)
    t:keys("<CR>")
    assert.is_true(t:wait_for("vim.bo.filetype == 'floggraph'", 5000))
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
