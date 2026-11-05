--- Eligible-target discovery and deterministic number resolution.
--
-- Design decisions:
--   * A window is "eligible" when it is valid, displays a valid buffer, and is
--     focusable. Non-focusable floats are skipped because they can never be the
--     target of a jump anyway.
--   * Windows are ordered by (buffer number, window id). Neovim allocates buffer
--     numbers in creation order, so this reproduces "buffer creation order";
--     duplicate buffers shown in several windows are ordered by window id for
--     determinism.
--   * Manual assignments (made with :LatcherReassign) always win. Number
--     resolution happens fresh on every :Latcher activation from the visible
--     windows and the persistent override table, so deleted buffers and closed
--     windows simply drop out of the mapping instead of keeping stale numbers.
--   * There is no shifting or swapping: when a manual assignment takes a number,
--     the previous owner is marked "stripped" and shows no hint until it wins a
--     number again naturally. Other windows keep their numbers.

local M = {}

--- Maximum simultaneously hinted targets (numbers are single digits 1-9).
M.MAX_TARGETS = 9

--- Return the eligible window ids of the current tabpage, sorted by
-- (buffer creation order, window id).
function M.visible_sorted()
  local entries = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) then
      local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
      if ok and vim.api.nvim_buf_is_valid(buf) then
        -- nvim_win_get_config errors on some exotic window types in older
        -- releases; treat any failure as "not a float" (i.e. eligible).
        local cfg_ok, config = pcall(vim.api.nvim_win_get_config, win)
        local focusable = true
        if cfg_ok and config and config.focusable == false then
          focusable = false
        end
        if focusable then
          -- nvim_buf_get_number() only exists on Neovim >= 0.11. On 0.10 the
          -- buffer handle itself is the buffer number, so fall back to it.
          local bufnum = buf
          if vim.api.nvim_buf_get_number then
            bufnum = vim.api.nvim_buf_get_number(buf)
          end
          entries[#entries + 1] = { win = win, bufnum = bufnum }
        end
      end
    end
  end

  table.sort(entries, function(a, b)
    if a.bufnum ~= b.bufnum then
      return a.bufnum < b.bufnum
    end
    return a.win < b.win
  end)

  local wins = {}
  for i, entry in ipairs(entries) do
    wins[i] = entry.win
  end
  return wins
end

--- Resolve hint numbers for the visible windows.
-- @param wins   sorted list of eligible window ids (from visible_sorted)
-- @param manual {[winid] = number} persistent overrides from :LatcherReassign
-- @param stripped {[winid] = true} windows deliberately denied a number
-- @return assigned {[winid] = number}, bynum {[number] = winid}
-- Every number 1-MAX_TARGETS is used at most once; at most MAX_TARGETS
-- windows are highlighted. A corrupted `manual` table (two windows claiming
-- the same number) is a programming error, so it raises instead of picking a
-- winner silently.
function M.resolve(wins, manual, stripped)
  local assigned = {} -- [winid] = number
  local used = {}     -- [number] = winid

  -- Manual assignments take precedence over everything.
  for _, win in ipairs(wins) do
    local num = manual[win]
    if num then
      if type(num) ~= "number" or num < 1 or num > M.MAX_TARGETS then
        error(("Latcher: invalid manual number %s for window %d"):format(
          tostring(num), win))
      end
      if used[num] and used[num] ~= win then
        error(("Latcher: number %d is assigned to both window %d and %d"):format(
          num, used[num], win))
      end
      assigned[win] = num
      used[num] = win
    end
  end

  -- Auto-fill the remaining windows in creation order with the lowest free
  -- number. Stripped windows consume no number and block no one.
  for _, win in ipairs(wins) do
    if not assigned[win] and not stripped[win] then
      local num
      for n = 1, M.MAX_TARGETS do
        if not used[n] then
          num = n
          break
        end
      end
      if not num then
        break -- MAX_TARGETS targets already highlighted
      end
      assigned[win] = num
      used[num] = win
    end
  end

  local bynum = {}
  for win, num in pairs(assigned) do
    bynum[num] = win
  end
  return assigned, bynum
end

return M
