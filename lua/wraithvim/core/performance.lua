-- Performance helpers: startup statistics and the benchmark runner.

local M = {}

--- lazy.nvim startup statistics, if available.
---@return { startuptime: number, loaded: integer, count: integer }?
function M.stats()
  local ok, lazy = pcall(require, "lazy")
  if not ok then
    return nil
  end
  local s = lazy.stats()
  return { startuptime = s.startuptime, loaded = s.loaded, count = s.count }
end

--- Parse a `nvim --startuptime` log and return the final timestamp (ms).
---@param path string
---@return number? total_ms
function M.parse_startuptime(path)
  local fd = io.open(path, "r")
  if not fd then
    return nil
  end
  local last
  for line in fd:lines() do
    local t = line:match("^(%d+%.%d+)%s+%d+%.%d+")
    if t then
      last = tonumber(t)
    end
  end
  fd:close()
  return last
end

--- Run scripts/benchmark.sh in a terminal split.
---@param args? string[]
function M.benchmark(args)
  local script = vim.fs.joinpath(vim.g.wraithvim_root, "scripts", "benchmark.sh")
  if not vim.uv.fs_stat(script) then
    vim.notify("Benchmark script not found: " .. script, vim.log.levels.ERROR)
    return
  end
  local cmd = { "bash", script }
  vim.list_extend(cmd, args or {})
  vim.cmd("botright new")
  vim.fn.jobstart(cmd, { term = true, cwd = vim.g.wraithvim_root })
  vim.bo.bufhidden = "wipe"
end

--- Open lazy.nvim's profiler, or print the startup summary without plugins.
function M.profile()
  if package.loaded["lazy"] then
    vim.cmd("Lazy profile")
    return
  end
  vim.notify("lazy.nvim is not loaded; run `nvim --startuptime /tmp/wraithvim-startup.log` instead.")
end

return M
