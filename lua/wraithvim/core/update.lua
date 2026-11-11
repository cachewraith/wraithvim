-- :WraithUpdate - fast-forward the distribution checkout, then sync plugins
-- to the pinned lazy-lock.json. User files in ~/.config/wraithvim are never
-- touched because they live outside the distribution directory.

local utils = require("wraithvim.core.utils")

local M = {}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "WraithUpdate" })
end

---@param root string
---@return boolean ok
local function handle_dirty_tree(root)
  local r = utils.run({ "git", "-C", root, "status", "--porcelain" })
  if r.code ~= 0 then
    notify("git status failed: " .. utils.trim(r.stderr), vim.log.levels.ERROR)
    return false
  end
  local dirty = utils.lines(r.stdout)
  if #dirty == 0 then
    return true
  end
  -- `:Lazy update` rewrites the lockfile; that is the only change we offer to discard.
  if #dirty == 1 and dirty[1]:match("lazy%-lock%.json$") then
    local choice = vim.fn.confirm(
      "lazy-lock.json has local changes (from :Lazy update).\nReset it to the distribution's pinned versions?",
      "&Reset\n&Cancel",
      2
    )
    if choice ~= 1 then
      return false
    end
    utils.run({ "git", "-C", root, "checkout", "--", "lazy-lock.json" })
    return true
  end
  notify(
    "The WraithVim checkout has local modifications:\n"
      .. table.concat(dirty, "\n")
      .. "\nCommit or stash them in "
      .. root
      .. ", or move personal changes to ~/.config/wraithvim/.",
    vim.log.levels.ERROR
  )
  return false
end

function M.run()
  local root = vim.g.wraithvim_root
  if not root or not vim.uv.fs_stat(vim.fs.joinpath(root, ".git")) then
    notify(
      "WraithVim is not a Git checkout (" .. tostring(root) .. "); update it with install.sh.",
      vim.log.levels.ERROR
    )
    return
  end
  if not handle_dirty_tree(root) then
    return
  end
  -- A checkout pinned to a release tag has no branch to fast-forward.
  if utils.run({ "git", "-C", root, "symbolic-ref", "-q", "HEAD" }).code ~= 0 then
    local ref = utils.trim(utils.run({ "git", "-C", root, "describe", "--tags", "--always" }).stdout)
    notify(
      ("WraithVim is pinned to %s (detached HEAD), so there is nothing to update.\n"):format(ref)
        .. "Follow updates again with: git -C "
        .. root
        .. " checkout main",
      vim.log.levels.WARN
    )
    return
  end
  local function head()
    return utils.trim(utils.run({ "git", "-C", root, "rev-parse", "HEAD" }).stdout)
  end
  local before = head()
  notify("Fetching updates...")
  vim.system({ "git", "-C", root, "pull", "--ff-only" }, { text = true }, function(r)
    vim.schedule(function()
      if r.code ~= 0 then
        notify("git pull failed (network or diverged history):\n" .. utils.trim(r.stderr), vim.log.levels.ERROR)
        return
      end
      -- Compare commits rather than parsing git's (localised) output.
      local after = head()
      if after == before then
        notify("WraithVim is up to date (" .. after:sub(1, 7) .. ").")
        return
      end
      local log = utils.run({ "git", "-C", root, "log", "--oneline", "--no-decorate", before .. ".." .. after })
      notify(("Updated %s..%s:\n%s"):format(before:sub(1, 7), after:sub(1, 7), utils.trim(log.stdout)))
      -- Sync plugins only when the update changed their pinned versions.
      local lock_changed = utils.run({ "git", "-C", root, "diff", "--quiet", before, after, "--", "lazy-lock.json" }).code
        ~= 0
      if lock_changed and package.loaded["lazy"] then
        notify("Plugin versions changed; installing the pinned versions...")
        require("lazy").restore({ wait = false })
      end
      notify("Restart Neovim to apply the update.")
    end)
  end)
end

return M
