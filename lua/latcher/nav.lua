--- Navigation orchestration and persistent reassignment state.
--
-- Design decisions:
--   * Only one navigation session may run at a time. Re-invoking :Latcher while
--     one is active is reported instead of stacking input loops.
--   * Reassignment state lives for the whole Neovim session (not just one
--     navigation), so numbers survive across :Latcher invocations. Manual
--     assignments always win over auto-assignment.
--   * Window ids are never reused by Neovim, and every resolve() re-checks
--     validity, so stale entries are harmless; they are pruned anyway for
--     tidiness.
--   * When :LatcherReassign takes a number away from its previous owner, that
--     window becomes "stripped" (shows no hint until it wins a number again);
--     nothing else shifts or swaps, per the requirements.

local targets = require("latcher.targets")
local hints = require("latcher.hints")
local select = require("latcher.select")

local M = {}

-- Session state. Keyed by window id; values are numbers 1-9.
local state = {
  manual = {},   -- [winid] = number   overrides from :LatcherReassign
  stripped = {}, -- [winid] = true     deliberately numberless windows
  active = false, -- true while a navigation input loop is running
}

local function notify(msg, level)
  vim.notify(msg, level, { title = "Latcher" })
end

local function prune()
  for win in pairs(state.manual) do
    if not vim.api.nvim_win_is_valid(win) then
      state.manual[win] = nil
    end
  end
  for win in pairs(state.stripped) do
    if not vim.api.nvim_win_is_valid(win) then
      state.stripped[win] = nil
    end
  end
end

--- Resolve the current number -> window mapping from visibility + overrides.
-- @return bynum {[number] = winid}, or raises on corrupted manual state.
function M.resolve()
  prune()
  local wins = targets.visible_sorted()
  local _, bynum = targets.resolve(wins, state.manual, state.stripped)
  return bynum
end

--- Enter navigation mode: show hints, wait for one key, jump, clean up.
function M.start()
  if state.active then
    notify("navigation is already active", vim.log.levels.WARN)
    return
  end

  local ok, bynum = pcall(M.resolve)
  if not ok then
    notify(tostring(bynum), vim.log.levels.ERROR)
    return
  end
  if not next(bynum) then
    notify("no eligible windows", vim.log.levels.WARN)
    return
  end

  local valid = {}
  for num in pairs(bynum) do
    valid[num] = true
  end

  state.active = true
  -- Build a clear on-screen message listing every available number. Numbers
  -- are not necessarily contiguous (manual assignments + stripped windows),
  -- so iterate the actual keys instead of 1..count.
  local nums = {}
  for num in pairs(bynum) do
    nums[#nums + 1] = num
  end
  table.sort(nums)
  local parts = {}
  for _, num in ipairs(nums) do
    parts[#parts + 1] = tostring(num)
  end
  local msg = ("Latcher: type %s to jump  |  <Esc> to cancel"):format(
    table.concat(parts, ", "))
  vim.api.nvim_echo({ { msg, "None" } }, true, {})
  local ok2, chosen = pcall(function()
    local hint_err = hints.show(bynum)
    if hint_err then
      notify(hint_err, vim.log.levels.WARN)
    end
    return select.pick(valid)
  end)

  -- Teardown happens no matter what: selection, cancellation, or error.
  pcall(hints.close_all)
  state.active = false

  if not ok2 then
    notify(tostring(chosen), vim.log.levels.ERROR)
    return
  end
  if chosen == nil then
    return -- cancelled with <Esc> or <C-c>
  end

  local win = bynum[chosen]
  if not vim.api.nvim_win_is_valid(win) then
    notify("target window was closed during navigation", vim.log.levels.ERROR)
    return
  end

  local okj, errj = pcall(vim.api.nvim_set_current_win, win)
  if not okj then
    notify(("could not jump to window %d: %s"):format(win, tostring(errj)),
      vim.log.levels.ERROR)
  end
end

--- Manually assign a number to the current window.
-- The number is read from the user as a single keystroke (1-9); <Esc> or
-- <C-c> cancels. If the number already belongs to another window, that window
-- loses the number and shows no hint until it wins one again. The current
-- window's previous number (if any) returns to the automatic pool.
function M.reassign()
  if state.active then
    notify("navigation is in progress", vim.log.levels.WARN)
    return
  end

  prune()
  local wins = targets.visible_sorted()
  local cur = vim.api.nvim_get_current_win()

  local eligible = false
  for _, win in ipairs(wins) do
    if win == cur then
      eligible = true
      break
    end
  end
  if not eligible then
    notify("current window cannot be assigned a number", vim.log.levels.ERROR)
    return
  end

  local ok, num = pcall(select.read_digit)
  if not ok or num == nil then
    if not ok then
      notify(tostring(num), vim.log.levels.ERROR)
    else
      notify("reassignment cancelled", vim.log.levels.INFO)
    end
    return
  end

  -- Resolve the current mapping to learn who owns `num` right now, so that
  -- window can be stripped even when navigation is not active.
  local ok2, assigned = pcall(function()
    local wins2 = targets.visible_sorted()
    local a, _ = targets.resolve(wins2, state.manual, state.stripped)
    return a
  end)
  if not ok2 then
    notify(tostring(assigned), vim.log.levels.ERROR)
    return
  end

  local victim = nil
  for w2, n in pairs(assigned) do
    if n == num and w2 ~= cur then
      victim = w2
      break
    end
  end

  if victim then
    -- Remove any manual claim the victim has, then deny it a number.
    if state.manual[victim] == num then
      state.manual[victim] = nil
    end
    state.stripped[victim] = true
  end

  state.stripped[cur] = nil
  state.manual[cur] = num

  local detail = ""
  if victim then
    detail = (" (taken from window %d)"):format(victim)
  end
  notify(("current window assigned to number %d%s"):format(num, detail),
    vim.log.levels.INFO)
end

return M
