-- Test runner: executes every *_spec.lua (optionally limited to the given
-- tests/ subdirectories or spec files) in its own headless Neovim with Plenary Busted.
--
--   nvim --headless --noplugin -u tests/minimal_init.lua -l tests/run.lua [dir ...]

local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local dirs = #arg > 0 and arg or { "core", "config", "features", "ui", "languages", "installer", "integration" }

-- Default to the .tests sandbox so `nvim -l tests/run.lua` works without make.
local sandbox = vim.fs.joinpath(root, ".tests")
local child_env = {
  XDG_CONFIG_HOME = vim.env.XDG_CONFIG_HOME or (sandbox .. "/config"),
  XDG_DATA_HOME = vim.env.XDG_DATA_HOME or (sandbox .. "/data"),
  XDG_STATE_HOME = vim.env.XDG_STATE_HOME or (sandbox .. "/state"),
  XDG_CACHE_HOME = vim.env.XDG_CACHE_HOME or (sandbox .. "/cache"),
  WRAITHVIM_CONFIG_DIR = vim.env.WRAITHVIM_CONFIG_DIR or (sandbox .. "/empty-user-config"),
}
for k, v in pairs(child_env) do
  vim.env[k] = v
end
local plenary = vim.fs.joinpath(child_env.XDG_DATA_HOME, "nvim", "wraithvim", "plugins", "plenary.nvim")
if not vim.uv.fs_stat(plenary) then
  io.stderr:write("plenary.nvim not found at " .. plenary .. "; run `make deps` first\n")
  os.exit(1)
end

local files = {}
for _, dir in ipairs(dirs) do
  local single = vim.fs.joinpath(root, "tests", dir)
  if dir:match("_spec%.lua$") and vim.uv.fs_stat(single) then
    files[#files + 1] = single
    goto continue
  end
  local found = vim.fs.find(function(name)
    return name:match("_spec%.lua$") ~= nil
  end, { path = vim.fs.joinpath(root, "tests", dir), type = "file", limit = math.huge })
  table.sort(found)
  vim.list_extend(files, found)
  ::continue::
end

if #files == 0 then
  io.stderr:write("no spec files found in: " .. table.concat(dirs, ", ") .. "\n")
  os.exit(1)
end

local failed = {}
local start = vim.uv.hrtime()
for _, file in ipairs(files) do
  local rel = file:sub(#root + 2)
  io.stdout:write(("\n=== %s\n"):format(rel))
  local result = vim
    .system({
      vim.v.progpath,
      "--headless",
      "--noplugin",
      "-u",
      vim.fs.joinpath(root, "tests", "minimal_init.lua"),
      "-c",
      -- plenary.busted exits by itself; any load error must exit too, not hang.
      (
        "lua local ok, err = pcall(require('plenary.busted').run, %q) "
        .. "if not ok then io.stderr:write(tostring(err) .. '\\n') vim.cmd('cquit 2') end"
      ):format(file),
    }, {
      cwd = root,
      env = child_env,
      text = true,
      stdout = function(_, data)
        if data then
          io.stdout:write(data)
        end
      end,
      stderr = function(_, data)
        if data then
          io.stderr:write(data)
        end
      end,
    })
    :wait(300000)
  if result.code ~= 0 then
    failed[#failed + 1] = rel .. (result.signal ~= 0 and " (killed: timeout)" or "")
  end
end

local secs = (vim.uv.hrtime() - start) / 1e9
io.stdout:write(("\n%d spec file(s), %d failed, %.2f s\n"):format(#files, #failed, secs))
for _, f in ipairs(failed) do
  io.stdout:write("  FAILED: " .. f .. "\n")
end
os.exit(#failed == 0 and 0 or 1)
