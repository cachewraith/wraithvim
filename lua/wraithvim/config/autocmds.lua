-- Core autocommands. All live in named augroups (cleared on re-creation), so
-- sourcing twice never duplicates them. None of them poll or run on redraw.

local utils = require("wraithvim.core.utils")

local M = {}

---@param cfg table effective configuration
function M.setup(cfg)
  local group = utils.augroup("core")
  local au = vim.api.nvim_create_autocmd

  au("TextYankPost", {
    group = group,
    desc = "Highlight yanked text",
    callback = function()
      vim.hl.on_yank({ timeout = 150 })
    end,
  })

  au("BufReadPost", {
    group = group,
    desc = "Restore last cursor position",
    callback = function(args)
      local ft = vim.bo[args.buf].filetype
      if ft == "gitcommit" or ft == "gitrebase" or vim.b[args.buf].wraith_restored then
        return
      end
      vim.b[args.buf].wraith_restored = true
      local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
      local lines = vim.api.nvim_buf_line_count(args.buf)
      if mark[1] > 0 and mark[1] <= lines then
        pcall(vim.api.nvim_win_set_cursor, 0, mark)
      end
    end,
  })

  au({ "FocusGained", "TermClose", "TermLeave" }, {
    group = group,
    desc = "Reload files changed outside Neovim",
    callback = function()
      if vim.o.buftype ~= "nofile" then
        vim.cmd.checktime()
      end
    end,
  })

  au("VimResized", {
    group = group,
    desc = "Keep splits balanced on resize",
    callback = function()
      local tab = vim.api.nvim_get_current_tabpage()
      vim.cmd("tabdo wincmd =")
      vim.api.nvim_set_current_tabpage(tab)
    end,
  })

  au("FileType", {
    group = group,
    desc = "Close auxiliary windows with q",
    pattern = { "help", "qf", "man", "checkhealth", "wraithnotifications", "git", "fugitiveblame" },
    callback = function(args)
      vim.bo[args.buf].buflisted = false
      vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = args.buf, silent = true, desc = "Close window" })
    end,
  })

  au("FileType", {
    group = group,
    desc = "Wrap and spell-check prose",
    pattern = { "gitcommit", "markdown", "text" },
    callback = function()
      vim.opt_local.wrap = true
      vim.opt_local.spell = true
    end,
  })

  au("BufReadPre", {
    group = group,
    desc = "Reduce per-buffer work for large files",
    callback = function(args)
      if utils.is_large_file(args.buf, cfg.options.large_file_size) then
        vim.b[args.buf].wraith_large_file = true
        vim.opt_local.foldmethod = "manual"
        vim.opt_local.spell = false
        vim.opt_local.undofile = false
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(args.buf) then
            vim.bo[args.buf].syntax = "off"
          end
        end)
      end
    end,
  })

  au({ "WinEnter", "BufWinEnter" }, {
    group = group,
    desc = "Start typing when entering a WraithVim terminal (like VS Code)",
    callback = function()
      if vim.bo.filetype == "wraithterm" and vim.api.nvim_get_mode().mode ~= "t" then
        local job = vim.b.terminal_job_id
        if job and vim.fn.jobwait({ job }, 0)[1] == -1 then
          vim.cmd.startinsert()
        end
      end
    end,
  })

  au("TermOpen", {
    group = group,
    desc = "Terminal buffer defaults",
    callback = function(args)
      vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], { buffer = args.buf, desc = "Terminal normal mode" })
    end,
  })
end

return M
