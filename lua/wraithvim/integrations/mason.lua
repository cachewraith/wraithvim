-- Optional Mason support. System executables always win: Mason's bin
-- directory is appended to PATH, and tools are only installed after the user
-- runs :WraithInstallTools and confirms the list.

local utils = require("wraithvim.core.utils")

local M = {}

---@return string
function M.bin_dir()
  return vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "bin")
end

function M.add_to_path()
  local bin = M.bin_dir()
  local path = vim.env.PATH or ""
  for entry in path:gmatch("[^:]+") do
    if entry == bin then
      return
    end
  end
  vim.env.PATH = path == "" and bin or (path .. ":" .. bin)
  utils.reset_executable_cache()
end

--- Servers and formatters of enabled languages that are missing from PATH
--- and have a Mason package.
---@return { name: string, cmd: string, mason: string, kind: string }[]
function M.missing_tools()
  local languages = require("wraithvim.languages")
  local out, seen = {}, {}
  local function add(entry, kind)
    if entry.mason and not seen[entry.mason] and not utils.executable(entry.cmd) then
      seen[entry.mason] = true
      out[#out + 1] = { name = entry.name, cmd = entry.cmd, mason = entry.mason, kind = kind }
    end
  end
  for _, s in ipairs(languages.servers()) do
    add(s, "LSP")
  end
  for _, f in ipairs(languages.formatters()) do
    add(f, "formatter")
  end
  return out
end

--- Install missing tools through Mason after confirmation.
function M.install_missing()
  local cfg = require("wraithvim.core.config").get()
  if not cfg.options.mason.enabled then
    vim.notify(
      "Mason is disabled. Enable it in ~/.config/wraithvim/options.lua with `mason = { enabled = true }`,\nor install tools with your package manager (see :WraithHealth).",
      vim.log.levels.WARN,
      { title = "WraithVim" }
    )
    return
  end
  local tools = M.missing_tools()
  if #tools == 0 then
    vim.notify("All tools for enabled languages are available.", vim.log.levels.INFO, { title = "WraithVim" })
    return
  end
  local names = vim.tbl_map(function(t)
    return ("%s (%s)"):format(t.mason, t.kind)
  end, tools)
  local choice = vim.fn.confirm("Install with Mason?\n  " .. table.concat(names, "\n  "), "&Install\n&Cancel", 2)
  if choice ~= 1 then
    return
  end
  local registry = require("mason-registry")
  registry.refresh(function()
    for _, t in ipairs(tools) do
      if not registry.has_package(t.mason) then
        vim.notify("Mason has no package " .. t.mason, vim.log.levels.WARN, { title = "Mason" })
      else
        local pkg = registry.get_package(t.mason)
        if not pkg:is_installed() and not pkg:is_installing() then
          pkg:install({}, function(success, err)
            vim.schedule(function()
              utils.reset_executable_cache()
              if success then
                vim.notify(
                  "Installed " .. t.mason .. ". Restart Neovim to enable it.",
                  vim.log.levels.INFO,
                  { title = "Mason" }
                )
              else
                vim.notify(
                  "Failed to install " .. t.mason .. ": " .. tostring(err),
                  vim.log.levels.ERROR,
                  { title = "Mason" }
                )
              end
            end)
          end)
        end
      end
    end
  end)
end

return M
