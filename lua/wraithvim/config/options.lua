-- Editor options. `apply_defaults` runs before user files are loaded so that
-- direct `vim.opt` calls in ~/.config/wraithvim/options.lua win; `apply_user`
-- runs afterwards for settings expressed as data.

local M = {}

function M.apply_defaults()
  local o = vim.opt

  -- Interaction
  o.mouse = "a"
  o.mousescroll = "ver:3,hor:6"
  o.confirm = true
  o.timeoutlen = 400
  o.updatetime = 300
  o.undofile = true
  o.swapfile = true
  o.shortmess:append({ I = true, c = true, W = true })

  -- Display
  o.number = true
  o.relativenumber = false
  o.signcolumn = "yes"
  o.cursorline = true
  o.termguicolors = true
  o.wrap = false
  o.linebreak = true
  o.scrolloff = 6
  o.sidescrolloff = 8
  o.showmode = false
  o.laststatus = 3
  o.cmdheight = 1
  o.pumheight = 12
  o.splitright = true
  o.splitbelow = true
  o.splitkeep = "screen"
  o.list = true
  o.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
  o.fillchars = { eob = " ", diff = "╱" }
  o.winborder = "rounded"

  -- Editing
  o.expandtab = true
  o.shiftwidth = 2
  o.tabstop = 2
  o.softtabstop = 2
  o.shiftround = true
  o.smartindent = true
  o.ignorecase = true
  o.smartcase = true
  o.inccommand = "split"
  o.completeopt = { "menu", "menuone", "noselect" }
  o.virtualedit = "block"

  -- Grep with ripgrep when present (checked once, no shell involved).
  if vim.fn.executable("rg") == 1 then
    o.grepprg = "rg --vimgrep --smart-case"
    o.grepformat = "%f:%l:%c:%m"
  end
end

---@param cfg table effective configuration
function M.apply_user(cfg)
  local opts = cfg.options
  vim.g.mapleader = opts.leader
  vim.g.maplocalleader = opts.localleader
  vim.opt.winborder = cfg.ui.border
  local scroll = opts.scroll
  vim.opt.mousescroll = ("ver:%d,hor:%d"):format(math.max(1, scroll.wheel), math.max(1, scroll.wheel_horizontal))

  for name, value in pairs(opts.opt) do
    local ok, err = pcall(function()
      vim.opt[name] = value
    end)
    if not ok then
      require("wraithvim.core.logger").notify(vim.log.levels.WARN, ("options.opt.%s: %s"):format(name, tostring(err)))
    end
  end

  if opts.system_clipboard then
    -- Deferred: clipboard provider detection may spawn processes.
    vim.schedule(function()
      vim.opt.clipboard = "unnamedplus"
    end)
  end
end

return M
