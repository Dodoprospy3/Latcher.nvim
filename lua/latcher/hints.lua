--- Visual hint windows: one tiny floating window per target, showing its
--- number in the top-right corner of the target window.
--
-- Design decisions:
--   * Hints are floating windows, not extmarks or virtual text. That guarantees
--     zero modification of any user buffer (extmarks can be written out with a
--     buffer in some workflows).
--   * relative="win" anchored floats do not render in terminal Neovim, so hints
--     use relative="editor" with absolute screen positions computed via
--     vim.fn.win_screenpos(). During navigation the windows cannot move
--     (input is blocking), so screen positions stay valid.
--   * Hints have a visible border, explicit colors, and are refreshed on every
--     show so they stand out against any colorscheme.
--   * All hint windows and their scratch buffers are tracked and closed/deleted
--     together, so nothing leaks after a selection or cancellation.

local M = {}

-- Currently open hints: { { win = winid, buf = bufid } } in creation order.
local open_hints = {}

local HINT_ZINDEX = 300

local hint_ns = vim.api.nvim_create_namespace("latcher")

--- Compute editor-relative float config so the badge sits flush with the
--- target window's top-right corner cell.
-- @param win target window id
-- @param badge_width width of the hint badge (number of cells)
-- @return config table, or nil if the window position could not be determined
local function hint_config(win, badge_width)
  if not vim.api.nvim_win_is_valid(win) then
    return nil
  end

  local width = vim.api.nvim_win_get_width(win)
  if width < 1 then
    return nil
  end

  -- win_screenpos returns 1-based screen coordinates of the window's top-left.
  local ok, pos = pcall(vim.fn.win_screenpos, win)
  if not ok or type(pos) ~= "table" or #pos < 2 then
    return nil
  end
  local screen_row, screen_col = pos[1], pos[2]
  if screen_row < 1 or screen_col < 1 then
    return nil
  end

  -- editor coordinates are 0-based; win_screenpos returns 1-based.
  -- Badge's right edge flush with the target's right edge:
  -- left edge at screen_col + width - badge_width (1-based), minus 1 for
  -- 0-based editor coords.
  return {
    relative = "editor",
    anchor = "NW",
    row = screen_row - 1,
    col = screen_col + width - badge_width - 1,
    width = badge_width,
    height = 1,
    border = "single",
    focusable = false,
    zindex = HINT_ZINDEX,
    -- `style = "minimal"` turns off number/relativenumber/signcolumn/... for
    -- the hint window. Without it the float inherits the user's gutter
    -- settings: `number` + `relativenumber` draw "1" in the single-line hint
    -- buffer and push the actual "[N]" text out of the visible area, making
    -- every badge look like "1". See configure_hint_window() below for the
    -- explicit per-option fallback.
    style = "minimal",
  }
end

--- Window options that must be off in a hint window. New windows inherit
--- window-local options from the window they are opened from, and gutters
--- (number, signcolumn, foldcolumn, statuscolumn, winbar) would eat the
--- badge's few cells and hide its text.
local HINT_WIN_OPTIONS = {
  number = false,
  relativenumber = false,
  signcolumn = "no",
  foldcolumn = "0",
  cursorline = false,
  cursorcolumn = false,
  colorcolumn = "",
  statuscolumn = "",
  winbar = "",
  spell = false,
  wrap = false,
  list = false,
  scrolloff = 0,
  sidescrolloff = 0,
}

--- Disable inherited gutters/decorations so only the badge text is visible.
--- `style = "minimal"` normally does this at open time, but colorschemes and
--- autocmds can re-enable options afterwards, so enforce them explicitly.
-- @param hint_win hint window id
local function configure_hint_window(hint_win)
  for opt, value in pairs(HINT_WIN_OPTIONS) do
    -- pcall: some options (e.g. statuscolumn) do not exist on older releases.
    pcall(vim.api.nvim_set_option_value, opt, value, { win = hint_win })
  end
end

--- Open hint windows for every {number -> window} pair.
-- Returns nil on success, or a (possibly multi-line) string describing failures.
-- Partial failure is non-fatal: the hints that could be created are still shown.
function M.show(bynum)
  -- Set highlight fresh (colorschemes may reset it between invocations).
  vim.api.nvim_set_hl(0, "LatcherHint", {
    fg = "#ffffff",
    bg = "#ff0000",
    bold = true,
  })

  local errors = {}
  for num, win in pairs(bynum) do
    -- Badge is 3 cells wide ("[N]").
    local badge = ("[%d]"):format(num)
    local badge_width = #badge

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, { badge })

    -- Explicitly highlight the badge text with extmark.
    vim.api.nvim_buf_set_extmark(buf, hint_ns, 0, 0, {
      end_col = badge_width,
      hl_group = "LatcherHint",
    })

    local cfg = hint_config(win, badge_width)
    if not cfg then
      errors[#errors + 1] = ("could not determine screen position of window %d"):format(win)
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
      goto continue
    end

    local ok, hint_win = pcall(vim.api.nvim_open_win, buf, false, cfg)
    if not ok then
      errors[#errors + 1] = ("could not show hint for window %d: %s"):format(
        win, tostring(hint_win))
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
      goto continue
    end

    configure_hint_window(hint_win)
    pcall(vim.api.nvim_set_option_value, "winhl", "Normal:LatcherHint", {
      win = hint_win,
    })
    open_hints[#open_hints + 1] = { win = hint_win, buf = buf }
    ::continue::
  end

  if #errors > 0 then
    return table.concat(errors, "\n")
  end

  -- Force a redraw so the hints appear immediately while we block on input.
  vim.cmd("redraw")
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
