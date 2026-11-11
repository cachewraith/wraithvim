-- Runtime benchmarks driven through a real TUI in a pseudo-terminal.
-- Invoked by scripts/benchmark.sh:
--   nvim --headless --clean -l scripts/benchmark.lua [--installed] [--idle-seconds N]
--
-- Measures idle CPU and memory, time to open a file, LSP initialisation time
-- (when clangd or lua-language-server is installed) and Git operations on a
-- generated repository. Prints one line per metric.

local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
package.path = root .. "/?.lua;" .. package.path

local tui = require("tests.helpers.tui")
local env = require("tests.helpers.env")

local installed = vim.tbl_contains(arg, "--installed")
local idle_seconds = 10
for i, a in ipairs(arg) do
  if a == "--idle-seconds" then
    idle_seconds = tonumber(arg[i + 1]) or idle_seconds
  end
end

local function out(fmt, ...)
  io.stdout:write(fmt:format(...) .. "\n")
end

local CLK_TCK = tonumber(vim.trim(vim.fn.system({ "getconf", "CLK_TCK" }))) or 100

---@param pid integer
---@return integer ticks, integer rss_kib
local function proc_stats(pid)
  local stat = assert(io.open("/proc/" .. pid .. "/stat")):read("*a")
  local fields = vim.split(stat:match("%) (.*)"), " ")
  local status = assert(io.open("/proc/" .. pid .. "/status")):read("*a")
  return tonumber(fields[12]) + tonumber(fields[13]), tonumber(status:match("VmRSS:%s+(%d+)"))
end

local function spawn(args, cwd)
  return tui.spawn({ args = args, cwd = cwd, installed = installed })
end

-- Generated repository: 40 directories x 50 files, 3 commits, 25 modified files.
local function make_repo()
  local dir = env.tmpdir("bench-repo")
  local function git(...)
    local r = vim.system({ "git", "-C", dir, ... }, { text = true }):wait()
    assert(r.code == 0, r.stderr)
  end
  git("init", "-q")
  git("config", "user.email", "bench@example.invalid")
  git("config", "user.name", "bench")
  for d = 1, 40 do
    for f = 1, 50 do
      local lines = {}
      for l = 1, 40 do
        lines[l] = ("local value_%d_%d_%d = %d"):format(d, f, l, l)
      end
      env.write(("%s/pkg%02d/file%02d.lua"):format(dir, d, f), table.concat(lines, "\n") .. "\n")
    end
  end
  git("add", "-A")
  git("commit", "-qm", "initial")
  for c = 1, 2 do
    env.write(dir .. "/CHANGELOG.md", ("change %d\n"):format(c))
    git("add", "-A")
    git("commit", "-qm", "change " .. c)
  end
  for f = 1, 25 do
    local path = ("%s/pkg01/file%02d.lua"):format(dir, f)
    env.write(path, env.read(path) .. "-- edited\n")
  end
  return dir
end

out("WraithVim runtime benchmark (%s, Neovim %s)", installed and "installed" or "checkout", tostring(vim.version()))

-- 1. Idle CPU and memory with a file open (explorer, statusline, gitsigns active).
do
  local t = spawn({ root .. "/lua/wraithvim/init.lua" }, root)
  t:sleep(4000)
  local pid = t:lua("return vim.fn.getpid()")
  local t0, rss0 = proc_stats(pid)
  local w0 = vim.uv.hrtime()
  t:sleep(idle_seconds * 1000)
  local t1, rss1 = proc_stats(pid)
  local secs = (vim.uv.hrtime() - w0) / 1e9
  local cpu_ms = (t1 - t0) / CLK_TCK * 1000
  out("idle_cpu: %.0f ms CPU over %.1f s (%.3f%%)", cpu_ms, secs, cpu_ms / 10 / secs)
  out("memory_rss: %.1f MiB after startup, %.1f MiB after idle", rss0 / 1024, rss1 / 1024)
  local loaded = t:lua(
    [[local n=0 for _,p in pairs(require('lazy.core.config').plugins) do if p._.loaded then n=n+1 end end return n]]
  )
  out("plugins_loaded_after_ui: %d", loaded)
  t:close()
end

-- 2. Time to open a file (edit + filetype + Treesitter start), median of 5.
do
  local t = spawn({}, root)
  t:sleep(2500)
  local samples = {}
  local files = {
    "lua/wraithvim/core/config.lua",
    "lua/wraithvim/features/conflicts.lua",
    "install.sh",
    "README.md",
    "lua/wraithvim/ui/dashboard.lua",
  }
  for _, f in ipairs(files) do
    samples[#samples + 1] =
      t:lua("local s = vim.uv.hrtime(); vim.cmd.edit(...); return (vim.uv.hrtime() - s) / 1e6", root .. "/" .. f)
  end
  table.sort(samples)
  out("file_open: median %.2f ms (min %.2f, max %.2f, n=%d)", samples[3], samples[1], samples[#samples], #samples)
  t:close()
end

-- 3. LSP initialisation: time from :edit until the client finished `initialize`.
do
  local candidates = {
    {
      exe = "clangd",
      file = "main.c",
      content = '#include <stdio.h>\nint main(void) { printf("hi\\n"); return 0; }\n',
    },
    { exe = "lua-language-server", file = "init.lua", content = "local x = 1\nreturn x\n" },
  }
  local chosen
  for _, c in ipairs(candidates) do
    if vim.fn.executable(c.exe) == 1 then
      chosen = c
      break
    end
  end
  if not chosen then
    out("lsp_init: skipped (neither clangd nor lua-language-server is installed)")
  else
    local dir = env.tmpdir("bench-lsp")
    env.write(dir .. "/" .. chosen.file, chosen.content)
    vim.system({ "git", "init", "-q", dir }):wait()
    local t = spawn({}, dir)
    t:sleep(2000)
    t:lua(
      [[
      _G.__bench = { start = vim.uv.hrtime() }
      vim.api.nvim_create_autocmd("LspAttach", { once = true, callback = function() _G.__bench.attach = vim.uv.hrtime() end })
      vim.cmd.edit(...)
    ]],
      dir .. "/" .. chosen.file
    )
    local ready = t:wait_for(
      "(function() local c = vim.lsp.get_clients({ bufnr = 0 })[1]; return c ~= nil and c.initialized == true end)()",
      20000
    )
    if ready then
      local ms = t:lua("return (vim.uv.hrtime() - _G.__bench.start) / 1e6")
      local attach = t:lua("return _G.__bench.attach and (_G.__bench.attach - _G.__bench.start) / 1e6 or -1")
      out(
        "lsp_init (%s): attached after %.0f ms, initialized within %.0f ms (includes plugin lazy-load)",
        chosen.exe,
        attach,
        ms
      )
    else
      out("lsp_init (%s): server did not initialize within 20 s", chosen.exe)
    end
    t:close()
    vim.fn.delete(dir, "rf")
  end
end

-- 4. Git operations on the generated repository (2000 files, 25 modified).
do
  local dir = make_repo()
  local t = spawn({}, dir)
  t:sleep(2500)
  local attach_ms = t:lua(
    [[
    local s = vim.uv.hrtime()
    vim.cmd.edit(...)
    vim.wait(5000, function() return vim.b.gitsigns_status_dict ~= nil end, 5)
    return (vim.uv.hrtime() - s) / 1e6
  ]],
    dir .. "/pkg01/file01.lua"
  )
  out("git_signs_attach: %.0f ms until hunks were available for a modified file", attach_ms)
  local status_ms = t:lua(
    [[
    local s = vim.uv.hrtime()
    require("wraithvim.features.git").git({ "status", "--porcelain" }, ...)
    return (vim.uv.hrtime() - s) / 1e6
  ]],
    dir
  )
  out("git_status: %.1f ms (git status --porcelain, 2000 tracked files)", status_ms)
  local diff_ms = t:lua([[
    local s = vim.uv.hrtime()
    vim.cmd("DiffviewOpen")
    vim.wait(10000, function()
      local view = require("diffview.lib").get_current_view()
      return view ~= nil and view.files ~= nil and #view.files.working > 0
    end, 5)
    return (vim.uv.hrtime() - s) / 1e6
  ]])
  out("git_diffview_open: %.0f ms until 25 changed files were listed", diff_ms)
  t:close()
  vim.fn.delete(dir, "rf")
end
