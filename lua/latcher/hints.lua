--- Visual hint windows: one tiny floating window per target, showing its
--- number in the top-right corner of the target window.
--
-- Design decisions:
--   * Hints are floating windows, not extmarks or virtual text. That guarantees
--     zero modification of any user buffer (extmarks can be written out with a
--     buffer in some workflows).
--   * Each hint is anchored to its target window with relative="win", anchor
--     "NE", col = target width - 1, so the single digit sits flush with the
--     target's top-right corner cell. Anchoring to another floating window is
--     supported, so floating targets work exactly like splits.
--   * The hint window borrows its colors from the user's colorscheme via the
--     `LatcherHint` highlight group (linked to `Visual` by default) mapped
--     through winhl, so the badge looks native in every colorscheme.
--   * All hint windows and their scratch buffers are tracked and closed/deleted
--     together, so nothing leaks after a selection or cancellation.

local M = {}

-- Currently open hints: { { win = winid, buf = bufid } } in creation order.
local open_hints = {}

local HINT_ZINDEX = 300

--- Open hint windows for every {number -> window} pair.
-- Returns nil on success, or a (possibly multi-line) string describing failures.
-- Partial failure is non-fatal: the hints that could be created are still shown.
function M.show(bynum)
  local errors = {}
  for num, win in pairs(bynum) do
    if not vim.api.nvim_win_is_valid(win) then
      errors[#errors + 1] = ("target window %d closed before hint could be shown"):format(win)
      goto continue
    end
    local width = vim.api.nvim_win_get_width(win)
    if width < 1 then
      errors[#errors + 1] = ("target window %d has no columns"):format(win)
      goto continue
    end

    -- Badge is 3 cells wide ("[N]"), flush right with the target window so it
    -- is easy to spot at a glance.
    local badge = ("[%d]"):format(num)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, { badge })

    local ok, hint_win = pcall(vim.api.nvim_open_win, buf, false, {
      relative = "win",
      win = win,
      anchor = "NE",
      row = 0,
      col = width - #badge, -- badge's right edge flush with target's right edge
      width = #badge,
      height = 1,
      border = "none",
      focusable = false,
      style = "minimal", -- no line numbers, foldcolumn, etc. inside the hint
      zindex = HINT_ZINDEX,
    })
    if not ok then
      errors[#errors + 1] = ("could not show hint for window %d: %s"):format(
        win, tostring(hint_win))
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
      goto continue
    end

    pcall(vim.api.nvim_set_option_value, "winhl", "Normal:LatcherHint", {
      win = hint_win,
    })
    open_hints[#open_hints + 1] = { win = hint_win, buf = buf }
    ::continue::
  end

  if #errors > 0 then
    return table.concat(errors, "\n")
  end
  return nil
end

--- Close every open hint window and delete its scratch buffer.
-- Safe to call multiple times; errors from individual closes are aggregated and
-- reported rather than silently swallowed.
function M.close_all()
  local errors = {}
  -- Close in reverse creation order so nested/stacked hints tear down cleanly.
  for i = #open_hints, 1, -1 do
    local entry = open_hints[i]
    if entry.win and vim.api.nvim_win_is_valid(entry.win) then
      local ok, err = pcall(vim.api.nvim_win_close, entry.win, true)
      if not ok then
        errors[#errors + 1] = ("failed to close hint window %d: %s"):format(
          entry.win, tostring(err))
      end
    end
    if entry.buf and vim.api.nvim_buf_is_valid(entry.buf) then
      local ok, err = pcall(vim.api.nvim_buf_delete, entry.buf, { force = true })
      if not ok then
        errors[#errors + 1] = ("failed to delete hint buffer %d: %s"):format(
          entry.buf, tostring(err))
      end
    end
  end
  open_hints = {}

  if #errors > 0 then
    vim.notify(table.concat(errors, "\n"), vim.log.levels.ERROR, { title = "Latcher" })
  end
end

return M
