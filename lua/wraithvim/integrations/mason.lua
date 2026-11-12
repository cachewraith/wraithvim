-- Language tools through Mason: language servers (completion, errors),
-- linters, formatters, and Treesitter parsers for syntax colors.
--
-- When a file opens whose tools are missing, WraithVim offers to install
-- them once per language (`options.mason.auto_install`). A server starts in
-- the open file as soon as it is installed; no restart. Tools you installed
-- yourself always win: Mason's bin directory is appended to PATH.

local utils = require("wraithvim.core.utils")

local M = {}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Language tools" })
end

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

-- Program a Mason package source needs before it can install anything.
M.requirements = {
  npm = { cmd = "npm", name = "Node.js (npm)" },
  golang = { cmd = "go", name = "Go" },
  pypi = { cmd = "python3", name = "Python 3" },
  cargo = { cmd = "cargo", name = "Rust (cargo)" },
  gem = { cmd = "gem", name = "Ruby (gem)" },
  nuget = { cmd = "dotnet", name = ".NET SDK (dotnet)" },
  composer = { cmd = "composer", name = "PHP Composer" },
  luarocks = { cmd = "luarocks", name = "LuaRocks" },
  opam = { cmd = "opam", name = "OCaml (opam)" },
}

--- What a package source needs that is not installed, if anything.
---@param source_id string Mason source id, e.g. "pkg:npm/vtsls@1.0"
---@return string? name of the missing program
function M.missing_requirement(source_id)
  local kind = (source_id or ""):match("^pkg:([%w_]+)/")
  local req = kind and M.requirements[kind]
  if req and not utils.executable(req.cmd) then
    return req.name
  end
end

--- Tools of `profiles` that are not on PATH, deduplicated by Mason package.
--- Tools without a Mason package are returned with `mason = nil`.
---@param profiles? table[]
---@return { name: string, cmd: string, mason?: string, kind: string, language: string, install?: string }[]
function M.missing_tools(profiles)
  local languages = require("wraithvim.languages")
  profiles = profiles or languages.enabled()
  local out, seen = {}, {}
  local function add(entry, kind)
    local key = entry.mason or entry.cmd
    if not seen[key] and not utils.executable(entry.cmd) then
      seen[key] = true
      out[#out + 1] = {
        name = entry.name,
        cmd = entry.cmd,
        mason = entry.mason,
        kind = kind,
        language = entry.language,
        install = entry.install,
      }
    end
  end
  for _, s in ipairs(languages.servers(profiles)) do
    add(s, "language server")
  end
  for _, t in ipairs(languages.tools(profiles)) do
    add(t, "linter")
  end
  for _, f in ipairs(languages.formatters(profiles)) do
    add(f, "formatter")
  end
  return out
end

--- Treesitter parsers of `profile` that are missing and can be built here.
---@param profile table
---@return string[]
function M.missing_parsers(profile)
  local ts = require("wraithvim.integrations.treesitter")
  if not require("wraithvim.core.config").get().options.treesitter.highlight or #ts.missing_requirements() > 0 then
    return {}
  end
  local installed = ts.installed()
  return vim.tbl_filter(function(p)
    return not installed[p]
  end, profile.parsers or {})
end

-- "Never for this language" answers, kept across sessions.
local function state_path()
  return vim.fs.joinpath(vim.fn.stdpath("state"), "wraithvim", "tools.json")
end

---@return { never: table<string, boolean> }
function M.read_state()
  local ok, data = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(state_path()), "\n"))
  end)
  if ok and type(data) == "table" and type(data.never) == "table" then
    return data
  end
  return { never = {} }
end

---@param state table
local function write_state(state)
  local path = state_path()
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile({ vim.json.encode(state) }, path)
end

--- Start a freshly installed language server in the open buffers.
---@param name string server name
local function start_server(name)
  utils.reset_executable_cache()
  -- nvim-lspconfig only provides lsp/*.lua configs (its Lua module is never
  -- required), so ask lazy.nvim; loading it is a no-op when already loaded.
  pcall(function()
    require("lazy").load({ plugins = { "nvim-lspconfig" } })
  end)
  for _, server in ipairs(require("wraithvim.languages").servers()) do
    if server.name == name then
      require("wraithvim.integrations.lsp").enable(server)
    end
  end
end

--- Install tools with Mason. `on_done(ok_count, failed_names)` runs at the end.
---@param tools table[] entries from M.missing_tools() with a `mason` package
---@param on_done? fun(installed: string[], failed: string[])
function M.install(tools, on_done)
  local installed, failed, pending = {}, {}, #tools
  local function finish()
    pending = pending - 1
    if pending == 0 and on_done then
      on_done(installed, failed)
    end
  end
  if pending == 0 then
    if on_done then
      on_done(installed, failed)
    end
    return
  end
  local registry = require("mason-registry")
  registry.refresh(function()
    for _, t in ipairs(tools) do
      if not registry.has_package(t.mason) then
        failed[#failed + 1] = t.mason .. " (not in the Mason registry)"
        finish()
      else
        local pkg = registry.get_package(t.mason)
        if pkg:is_installed() then
          installed[#installed + 1] = t.mason
          start_server(t.name)
          finish()
        elseif pkg:is_installing() then
          finish()
        else
          pkg:install({}, function(success, err)
            vim.schedule(function()
              if success then
                installed[#installed + 1] = t.mason
                if t.kind == "language server" then
                  start_server(t.name)
                end
              else
                failed[#failed + 1] = ("%s: %s"):format(t.mason, tostring(err))
              end
              finish()
            end)
          end)
        end
      end
    end
  end)
end

--- Split missing tools into installable ones and ones needing something else.
---@param tools table[]
---@return table[] installable, string[] blocked "gopls needs Go" lines
local function classify(tools)
  local registry_ok, registry = pcall(require, "mason-registry")
  local installable, blocked = {}, {}
  for _, t in ipairs(tools) do
    if not t.mason then
      blocked[#blocked + 1] = ("%s: %s"):format(t.cmd, t.install or "see docs/languages.md")
    else
      local need
      if registry_ok and registry.has_package(t.mason) then
        local spec = registry.get_package(t.mason).spec
        need = M.missing_requirement(spec and spec.source and spec.source.id)
      end
      if need then
        blocked[#blocked + 1] = ("%s needs %s installed first"):format(t.mason, need)
      else
        installable[#installable + 1] = t
      end
    end
  end
  return installable, blocked
end

local asked = {}

--- Offer to install what `profile` is missing. Asks at most once per
--- language and session; "Never" is remembered.
---@param profile table
---@param mode? string "ask" | "always" (default: configuration)
function M.offer(profile, mode)
  local cfg = require("wraithvim.core.config").get()
  mode = mode or cfg.options.mason.auto_install
  if asked[profile.name] or mode == "never" or not cfg.options.mason.enabled then
    return
  end
  asked[profile.name] = true
  local state = M.read_state()
  if state.never[profile.name] then
    return
  end
  local tools, blocked = classify(M.missing_tools({ profile }))
  local parsers = M.missing_parsers(profile)
  if #tools == 0 and #parsers == 0 then
    if #blocked > 0 then
      notify(
        ("%s: completion and error checking need:\n  %s"):format(profile.description, table.concat(blocked, "\n  "))
      )
    end
    return
  end

  if mode ~= "always" then
    local lines = {}
    for _, t in ipairs(tools) do
      lines[#lines + 1] = ("  %s  (%s)"):format(t.mason, t.kind)
    end
    if #parsers > 0 then
      lines[#lines + 1] = ("  %s  (syntax colors)"):format(table.concat(parsers, ", "))
    end
    local msg = ("%s: install the tools for completion, error checking and formatting?\n%s"):format(
      profile.description,
      table.concat(lines, "\n")
    )
    if #blocked > 0 then
      msg = msg .. "\nSkipped:\n  " .. table.concat(blocked, "\n  ")
    end
    local choice = vim.fn.confirm(msg, "&Install\n&Not now\nNe&ver for " .. profile.description, 1)
    if choice == 3 then
      state.never[profile.name] = true
      write_state(state)
      notify(("Won't ask again for %s. :InstallTools installs them any time."):format(profile.description))
      return
    elseif choice ~= 1 then
      return
    end
  end

  if #parsers > 0 then
    require("wraithvim.integrations.treesitter").install(parsers, true)
  end
  if #tools == 0 then
    return
  end
  notify(("Installing %s for %s…"):format(
    table.concat(
      vim.tbl_map(function(t)
        return t.mason
      end, tools),
      ", "
    ),
    profile.description
  ))
  M.install(tools, function(installed, failed)
    if #installed > 0 then
      notify(
        ("%s ready: %s. Completion and error checking are on."):format(
          profile.description,
          table.concat(installed, ", ")
        )
      )
    end
    if #failed > 0 then
      notify(
        "Could not install:\n  " .. table.concat(failed, "\n  ") .. "\nSee :Mason for details.",
        vim.log.levels.ERROR
      )
    end
  end)
end

--- :InstallTools: everything missing for every enabled language, after one
--- confirmation.
function M.install_missing()
  local cfg = require("wraithvim.core.config").get()
  if not cfg.options.mason.enabled then
    notify(
      "Mason is disabled. Enable it in ~/.config/wraithvim/options.lua with `mason = { enabled = true }`,\nor install tools with your package manager (see :Health).",
      vim.log.levels.WARN
    )
    return
  end
  local tools, blocked = classify(M.missing_tools())
  if #tools == 0 then
    local msg = "All installable tools for enabled languages are available."
    if #blocked > 0 then
      msg = msg .. "\nNot installable here:\n  " .. table.concat(blocked, "\n  ")
    end
    notify(msg)
    return
  end
  local names = vim.tbl_map(function(t)
    return ("%s (%s, %s)"):format(t.mason, t.language, t.kind)
  end, tools)
  local choice = vim.fn.confirm("Install with Mason?\n  " .. table.concat(names, "\n  "), "&Install\n&Cancel", 2)
  if choice ~= 1 then
    return
  end
  M.install(tools, function(installed, failed)
    if #installed > 0 then
      notify("Installed: " .. table.concat(installed, ", "))
    end
    if #failed > 0 then
      notify("Could not install:\n  " .. table.concat(failed, "\n  "), vim.log.levels.ERROR)
    end
  end)
end

---@param cfg table effective configuration
function M.setup(cfg)
  if not cfg.options.mason.enabled then
    return
  end
  M.add_to_path()
  if cfg.options.mason.auto_install == "never" then
    return
  end
  local languages = require("wraithvim.languages")
  local by_ft = {}
  for _, p in ipairs(languages.enabled()) do
    for _, ft in ipairs(p.filetypes) do
      by_ft[ft] = by_ft[ft] or p
    end
  end
  local function check(buf, ft)
    local profile = by_ft[ft]
    if not profile or asked[profile.name] or vim.bo[buf].buftype ~= "" then
      return
    end
    -- Headless runs (scripts, CI) have nobody to answer and must not download.
    if #vim.api.nvim_list_uis() == 0 then
      return
    end
    -- After the file is drawn, and not while startup is still running.
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(buf) then
        M.offer(profile)
      end
    end, 300)
  end
  vim.api.nvim_create_autocmd("FileType", {
    group = utils.augroup("mason_offer"),
    pattern = vim.tbl_keys(by_ft),
    callback = function(args)
      check(args.buf, args.match)
    end,
  })
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      check(buf, vim.bo[buf].filetype)
    end
  end
end

return M
