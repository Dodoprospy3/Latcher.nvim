--- `:checkhealth latcher` support.
local M = {}

--- Emit a health report at `level`, tolerating both the 0.10+ short API and
--- the older `report_*` functions.
local function report(level, msg)
  local fn = vim.health[level] or vim.health["report_" .. level]
  if fn then
    fn(msg)
  end
end

function M.check()
  report("start", "latcher.nvim")

  if vim.fn.has("nvim-0.10") == 1 then
    report("ok", "Neovim >= 0.10 (" .. tostring(vim.version()) .. ")")
  else
    report("error", "Neovim >= 0.10 is required")
  end

  if vim.fn.exists(":Latcher") == 2 and vim.fn.exists(":LatcherReassign") == 2 then
    report("ok", "commands :Latcher and :LatcherReassign are defined")
  else
    report("error", "commands are missing; call require('latcher').setup()")
  end

  local hl_ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = "LatcherHint" })
  if not hl_ok then
    report("error", "could not read the LatcherHint highlight: " .. tostring(hl))
  elseif hl.fg or hl.bg or hl.link then
    report("ok", "LatcherHint highlight is defined")
  else
    report("warn", "LatcherHint has no attributes; hints may be hard to see")
  end

  local ok, targets = pcall(require, "latcher.targets")
  if not ok then
    report("error", "could not load latcher.targets: " .. tostring(targets))
    return
  end

  local wins_ok, wins = pcall(targets.visible_sorted)
  if not wins_ok then
    report("error", "could not enumerate windows: " .. tostring(wins))
    return
  end
  report("info", ("%d eligible window(s) in the current tabpage"):format(#wins))
end

return M
