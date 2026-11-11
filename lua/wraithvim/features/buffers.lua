-- Buffer management that keeps window layout intact.

local M = {}

---@param buf integer
---@return boolean
local function is_listed(buf)
  return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted
end

--- Pick a buffer to show instead of `buf` in its windows.
---@param buf integer
---@return integer? replacement
local function replacement(buf)
  local alt = vim.fn.bufnr("#")
  if alt > 0 and alt ~= buf and is_listed(alt) then
    return alt
  end
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if b ~= buf and is_listed(b) then
      return b
    end
  end
  return nil
end

--- Delete a buffer without closing the windows that display it. A modified
--- buffer asks before discarding changes unless `force` is set.
---@param buf? integer defaults to current buffer
---@param force? boolean
---@return boolean deleted
function M.delete(buf, force)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  if vim.bo[buf].modified and not force then
    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":~:.")
    local choice =
      vim.fn.confirm(("Save changes to %q?"):format(name ~= "" and name or "[No Name]"), "&Save\n&Discard\n&Cancel", 3)
    if choice == 1 then
      local ok, err = pcall(vim.api.nvim_buf_call, buf, function()
        vim.cmd.write()
      end)
      if not ok then
        vim.notify(tostring(err), vim.log.levels.ERROR)
        return false
      end
    elseif choice == 2 then
      force = true
    else
      return false
    end
  end

  local repl = replacement(buf)
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    vim.api.nvim_win_call(win, function()
      if repl then
        vim.api.nvim_win_set_buf(win, repl)
      else
        vim.cmd.enew()
      end
    end)
  end
  if vim.api.nvim_buf_is_valid(buf) then
    local ok, err = pcall(vim.api.nvim_buf_delete, buf, { force = force or false })
    if not ok then
      vim.notify(tostring(err), vim.log.levels.ERROR)
      return false
    end
  end
  return true
end

--- Delete every listed buffer except the current one. Modified buffers are kept.
---@return integer count deleted
function M.close_others()
  local current = vim.api.nvim_get_current_buf()
  local count = 0
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if b ~= current and is_listed(b) and not vim.bo[b].modified then
      if M.delete(b) then
        count = count + 1
      end
    end
  end
  return count
end

--- Delete listed buffers that are hidden (not shown in any window) and unmodified.
---@return integer count deleted
function M.cleanup()
  local count = 0
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if is_listed(b) and not vim.bo[b].modified and #vim.fn.win_findbuf(b) == 0 then
      if pcall(vim.api.nvim_buf_delete, b, {}) then
        count = count + 1
      end
    end
  end
  vim.notify(("Removed %d hidden buffer(s)"):format(count), vim.log.levels.INFO, { title = "WraithVim" })
  return count
end

return M
