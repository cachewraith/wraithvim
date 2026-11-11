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

  it("toggles the terminal panel with <leader>tt and focuses the editor on click", function()
    t = tui.spawn({ cwd = dir, args = { "alpha.lua" } })
    assert.is_true(t:wait_for("package.loaded['neo-tree'] ~= nil", 8000))
    t:keys(" tt")
    assert.is_true(t:wait_for("vim.bo.buftype == 'terminal'", 3000))
    t:keys("<Esc><Esc>")
    assert.is_true(t:wait_for("vim.fn.mode() == 'n'", 2000))
    local editor = t:lua([[
      for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.fn.bufname(vim.api.nvim_win_get_buf(w)):find("alpha.lua") then return w end
      end
    ]])
    local pos = t:lua("return vim.api.nvim_win_get_position(...)", editor)
    t:click(pos[1], pos[2] + 3)
    assert.is_true(t:wait_for("vim.fn.expand('%:t') == 'alpha.lua'", 2000))
    t:keys(" tt")
    assert.is_true(t:wait_for("vim.fn.bufwinid(require('wraithvim.features.terminal').panel.buf) == -1", 2000))
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
