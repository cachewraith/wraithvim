-- :checkhealth wraithvim  (also :WraithHealth)

local M = {}

local h = vim.health

---@param cmd string
---@return boolean
local function has(cmd)
  return vim.fn.executable(cmd) == 1
end

---@param cmd string[]
---@return string?
local function version_of(cmd)
  local ok, r = pcall(function()
    return vim.system(cmd, { text = true }):wait(2000)
  end)
  if not ok or not r or r.code ~= 0 then
    return nil
  end
  return vim.trim((r.stdout or ""):match("[^\n]*") or "")
end

local function check_core()
  h.start("WraithVim: core")
  local ok, msg = require("wraithvim.core.bootstrap").check_version()
  if ok then
    h.ok("Neovim " .. tostring(vim.version()))
  else
    h.error(msg)
  end
  if jit then
    h.ok("LuaJIT " .. (jit.version or ""))
  else
    h.warn("Neovim is not built with LuaJIT; WraithVim works but Lua code runs slower.")
  end

  local root = vim.g.wraithvim_root
  if not root then
    h.error("vim.g.wraithvim_root is not set; WraithVim was not started through its init.lua")
  else
    local missing = {}
    for _, rel in ipairs({ "init.lua", "lazy-lock.json", "lua/wraithvim/init.lua", "lua/wraithvim/config/defaults.lua" }) do
      if not vim.uv.fs_stat(vim.fs.joinpath(root, rel)) then
        missing[#missing + 1] = rel
      end
    end
    if #missing == 0 then
      h.ok(("WraithVim %s at %s"):format(require("wraithvim").version, root))
    else
      h.error("Installation at " .. root .. " is incomplete; missing: " .. table.concat(missing, ", "), {
        "Re-run install.sh or `git -C " .. root .. " checkout .`",
      })
    end
    if vim.uv.fs_stat(vim.fs.joinpath(root, ".git")) then
      h.ok("Git checkout: :WraithUpdate is available")
    else
      h.info("Not a Git checkout: update by re-running install.sh")
    end
  end

  local config = require("wraithvim.core.config")
  local dir = config.dir()
  if vim.uv.fs_stat(dir) then
    local present = {}
    for _, name in ipairs({ "options", "ui", "languages", "plugins", "keymaps" }) do
      if vim.uv.fs_stat(config.path(name)) then
        present[#present + 1] = name .. ".lua"
      end
    end
    h.ok(("User configuration: %s (%s)"):format(dir, #present > 0 and table.concat(present, ", ") or "no files"))
  else
    h.info("No user configuration directory (" .. dir .. "); defaults are used. :WraithConfig creates it.")
  end
  if #config.problems == 0 then
    h.ok("User configuration is valid")
  else
    for _, p in ipairs(config.problems) do
      h.warn(p)
    end
  end

  local log = require("wraithvim.core.logger").path()
  local stat = vim.uv.fs_stat(log)
  h.info(("Log file: %s (%s)"):format(log, stat and (stat.size .. " bytes") or "empty"))
end

local function check_tools()
  h.start("WraithVim: system tools")
  if has("git") then
    h.ok("git: " .. (version_of({ "git", "--version" }) or "found"))
  else
    h.error("git is required (plugin installation, Git features)", { "Install git with your package manager" })
  end

  local optional = {
    { { "rg" }, "ripgrep", "live grep / text search", "ripgrep" },
    { { "fd", "fdfind" }, "fd", "fast file finding", "fd (Arch/Fedora) or fd-find (Debian/Ubuntu/Kali)" },
    { { "make" }, "make", "builds telescope-fzf-native", "make" },
    { { "cc", "gcc", "clang" }, "C compiler", "telescope-fzf-native and Treesitter parsers", "gcc or clang" },
    {
      { "tree-sitter" },
      "tree-sitter CLI",
      "installing Treesitter parsers (:WraithTSInstall)",
      "tree-sitter-cli (>= 0.26.1)",
    },
    { { "curl" }, "curl", "Treesitter parser downloads, blink.cmp binary", "curl" },
    { { "tar" }, "tar", "Treesitter parser downloads", "tar" },
  }
  for _, item in ipairs(optional) do
    local found
    for _, c in ipairs(item[1]) do
      if has(c) then
        found = c
        break
      end
    end
    if found then
      h.ok(("%s (%s)"):format(item[2], found))
    else
      h.warn(("%s not found (optional): needed for %s"):format(item[2], item[3]), { "Install " .. item[4] })
    end
  end

  local clip = vim.fn.has("clipboard") == 1
  if clip then
    h.ok("Clipboard provider available")
  else
    h.warn("No clipboard provider (optional)", { "Install wl-clipboard (Wayland) or xclip/xsel (X11)" })
  end
end

local function check_plugins()
  h.start("WraithVim: plugins")
  local ok_lazy, lazy_config = pcall(require, "lazy.core.config")
  if not ok_lazy or not package.loaded["lazy"] then
    h.error("lazy.nvim is not loaded", { "Check network access and :WraithLog, then restart Neovim" })
    return
  end
  local installed, missing = 0, {}
  for name, plugin in pairs(lazy_config.plugins) do
    if plugin._.installed then
      installed = installed + 1
    else
      missing[#missing + 1] = name
    end
  end
  table.sort(missing)
  if #missing == 0 then
    h.ok(("%d plugins installed"):format(installed))
  else
    h.error("Plugins not installed: " .. table.concat(missing, ", "), { "Run :Lazy restore (requires network)" })
  end
  local stats = require("wraithvim.core.performance").stats()
  if stats and stats.startuptime > 0 then
    h.info(("%d/%d plugins loaded, startup %.1f ms"):format(stats.loaded, stats.count, stats.startuptime))
  end
  if vim.g.colors_name then
    h.ok("Colorscheme: " .. vim.g.colors_name)
  else
    h.warn("No colorscheme loaded")
  end
end

local function check_ui()
  h.start("WraithVim: UI")
  local ui = require("wraithvim.core.config").get().ui
  h.info("Preset: " .. ui.preset)
  if ui.icons.nerd_font then
    if has("fc-list") then
      local r = vim.system({ "fc-list", ":", "family" }, { text = true }):wait(3000)
      if r.code == 0 and (r.stdout or ""):lower():find("nerd") then
        h.ok("Nerd Font icons enabled; a Nerd Font is installed")
      else
        h.warn("Nerd Font icons enabled but no Nerd Font found by fc-list", {
          "Install a Nerd Font and select it in your terminal, or set icons = { nerd_font = false } in ui.lua",
        })
      end
    else
      h.info("Nerd Font icons enabled (fc-list unavailable; cannot verify the font)")
    end
  else
    h.ok("ASCII icons (nerd_font = false)")
  end
  if vim.o.termguicolors then
    h.ok("termguicolors enabled")
  end
end

local function check_languages()
  h.start("WraithVim: languages")
  local languages = require("wraithvim.languages")
  local profiles = languages.enabled()
  if #profiles == 0 then
    h.info("No languages enabled")
    return
  end
  local mason = require("wraithvim.core.config").get().options.mason.enabled
  h.info("Enabled: " .. table.concat(
    vim.tbl_map(function(p)
      return p.name
    end, profiles),
    ", "
  ))
  h.info(
    mason and "Mason enabled: missing tools can be installed with :WraithInstallTools"
      or "Mason disabled: install tools with your package manager (see docs/languages.md)"
  )
  for _, s in ipairs(languages.servers(profiles)) do
    if has(s.cmd) then
      h.ok(("LSP %s (%s): %s"):format(s.name, s.language, vim.fn.exepath(s.cmd)))
    else
      h.warn(("LSP %s (%s): `%s` not installed (optional)"):format(s.name, s.language, s.cmd), { s.install })
    end
  end
  for _, f in ipairs(languages.formatters(profiles)) do
    if has(f.cmd) then
      h.ok(("Formatter %s (%s): %s"):format(f.name, f.language, vim.fn.exepath(f.cmd)))
    else
      h.warn(
        ("Formatter %s (%s): `%s` not on PATH (optional; project-local installs are also detected)"):format(
          f.name,
          f.language,
          f.cmd
        ),
        { f.install }
      )
    end
  end
end

local function check_treesitter()
  h.start("WraithVim: Treesitter")
  local ts = require("wraithvim.integrations.treesitter")
  local installed = ts.installed()
  local have, missing = {}, {}
  for _, p in ipairs(ts.wanted_parsers()) do
    if installed[p] then
      have[#have + 1] = p
    else
      missing[#missing + 1] = p
    end
  end
  if #have > 0 then
    h.ok("Parsers available: " .. table.concat(have, ", "))
  end
  if #missing > 0 then
    h.warn("Parsers not installed (optional): " .. table.concat(missing, ", "), { "Run :WraithTSInstall" })
  end
  local req = ts.missing_requirements()
  if #req == 0 then
    h.ok("Parser build requirements present")
  else
    h.warn("Parser installation unavailable; missing: " .. table.concat(req, ", "), { "See docs/languages.md" })
  end
end

function M.check()
  check_core()
  check_tools()
  check_plugins()
  check_ui()
  check_languages()
  check_treesitter()
end

return M
