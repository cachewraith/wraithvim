-- lazy.nvim setup.

local bootstrap = require("wraithvim.core.bootstrap")
local logger = require("wraithvim.core.logger")

local M = {}

-- Built-in runtime plugins WraithVim does not use.
M.disabled_builtins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin", "rplugin" }

--- Name lazy.nvim uses for a spec (`name` field or repository basename).
---@param spec table|string
---@return string?
function M.spec_name(spec)
  if type(spec) == "string" then
    return (spec:match("[^/]+$"))
  end
  if type(spec) ~= "table" then
    return nil
  end
  if spec.name then
    return spec.name
  end
  local src = spec[1] or spec.dir or spec.url
  return src and src:gsub("%.git$", ""):match("[^/]+$") or nil
end

--- Mark specs whose name is listed in `disable` as disabled.
---@param specs table[]
---@param disable string[]
---@return table[]
function M.apply_disabled(specs, disable)
  local set = {}
  for _, name in ipairs(disable) do
    set[name] = true
  end
  for _, spec in ipairs(specs) do
    local name = M.spec_name(spec)
    if name and set[name] then
      spec.enabled = false
    end
  end
  return specs
end

--- Full spec list: WraithVim plugins followed by user plugins (which lazy.nvim
--- merges into existing specs with the same name, so users can override opts).
---@param cfg table
---@return table[]
function M.build_spec(cfg)
  local specs = require("wraithvim.plugins").specs(cfg)
  M.apply_disabled(specs, cfg.plugins.disable)
  for _, spec in ipairs(cfg.plugins.specs) do
    specs[#specs + 1] = spec
  end
  return specs
end

---@param cfg table
---@return boolean ok
function M.setup(cfg)
  local lazy_path, err = bootstrap.ensure_lazy()
  if not lazy_path then
    logger.notify(
      vim.log.levels.ERROR,
      "WraithVim: " .. err .. "\nRunning without plugins; restart Neovim once the network is available."
    )
    return false
  end
  vim.opt.rtp:prepend(lazy_path)

  local nerd = cfg.ui.icons.nerd_font
  local root = vim.g.wraithvim_root

  local ok, setup_err = pcall(require("lazy").setup, {
    spec = M.build_spec(cfg),
    root = bootstrap.plugin_root(),
    lockfile = vim.fs.joinpath(root, "lazy-lock.json"),
    defaults = { lazy = true, version = false },
    install = { missing = true, colorscheme = { cfg.ui.theme.colorscheme, "habamax" } },
    -- No background update checks and no config file watchers.
    checker = { enabled = false },
    change_detection = { enabled = false },
    rocks = { enabled = false },
    readme = { enabled = false },
    ui = {
      border = cfg.ui.border,
      icons = nerd and {} or {
        cmd = "cmd ",
        config = "cfg ",
        event = "event ",
        ft = "ft ",
        init = "init ",
        import = "import ",
        keys = "keys ",
        lazy = "lazy ",
        loaded = "*",
        not_loaded = "o",
        plugin = "plugin ",
        runtime = "rt ",
        require = "req ",
        source = "src ",
        start = "start ",
        task = "- ",
        list = { "*", "-", "+", "~" },
      },
    },
    performance = {
      rtp = {
        -- lazy.nvim resets the runtimepath; keep the WraithVim tree on it.
        paths = { root },
        disabled_plugins = M.disabled_plugins(cfg),
      },
    },
  })
  if not ok then
    logger.notify(vim.log.levels.ERROR, "WraithVim: lazy.nvim setup failed: " .. tostring(setup_err))
    return false
  end
  return true
end

---@param cfg table
---@return string[]
function M.disabled_plugins(cfg)
  local list = vim.list_extend({}, M.disabled_builtins)
  -- neo-tree replaces netrw; keep netrw when the explorer is disabled.
  if cfg.ui.explorer.enabled and not vim.tbl_contains(cfg.plugins.disable, "neo-tree.nvim") then
    vim.list_extend(list, { "netrw", "netrwPlugin", "netrwSettings", "netrwFileHandlers" })
  end
  return list
end

--- True when lazy.nvim knows an enabled plugin by this name.
---@param name string
---@return boolean
function M.has(name)
  local ok, lazy_config = pcall(require, "lazy.core.config")
  return ok and lazy_config.plugins[name] ~= nil
end

--- True when the plugin has been loaded.
---@param name string
---@return boolean
function M.is_loaded(name)
  local ok, lazy_config = pcall(require, "lazy.core.config")
  local plugin = ok and lazy_config.plugins[name]
  return plugin and plugin._.loaded ~= nil or false
end

return M
