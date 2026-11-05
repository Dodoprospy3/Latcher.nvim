package.path = "/home/adam/latcher.nvim/lua/?.lua;" .. package.path
local targets = require("latcher.targets")
local nvim = vim.api

local passes, failures = 0, 0
local function check(name, cond, extra)
  if cond then
    passes = passes + 1
    print("PASS: " .. name)
  else
    failures = failures + 1
    print("FAIL: " .. name .. (extra and (" :: " .. extra) or ""))
  end
end

local function bufs_count()
  return #vim.fn.getbufinfo({ buflisted = 1 })
end

-- Build three splits, each with its own freshly created buffer, in order.
nvim.nvim_command("split")
local w1 = nvim.nvim_get_current_win()
local b1 = nvim.nvim_win_get_buf(w1)
nvim.nvim_command("split")
local w2 = nvim.nvim_get_current_win()
local b2 = nvim.nvim_win_get_buf(w2)
nvim.nvim_command("split")
local w3 = nvim.nvim_get_current_win()
local b3 = nvim.nvim_win_get_buf(w3)

-- 1. ordering follows buffer creation order
do
  local wins = targets.visible_sorted()
  local order = {}
  for _, w in ipairs(wins) do
    order[#order + 1] = nvim.nvim_win_get_buf(w)
  end
  check("three visible windows listed", #wins >= 3)
  check("ordered by buffer creation order",
    order[1] == b1 and order[2] == b2 and order[3] == b3,
    vim.inspect(order))
end

-- 2. non-focusable floats are excluded
do
  local f = nvim.nvim_open_win(0, false, {
    relative = "editor", width = 10, height = 3, row = 5, col = 5,
    focusable = false, style = "minimal",
  })
  local wins = targets.visible_sorted()
  local has_float = false
  for _, w in ipairs(wins) do
    if w == f then has_float = true end
  end
  check("non-focusable float excluded", not has_float)
  nvim.nvim_win_close(f, true)
end

-- 3. focusable floats are included
do
  local f = nvim.nvim_open_win(0, false, {
    relative = "editor", width = 10, height = 3, row = 5, col = 5,
    focusable = true, style = "minimal",
  })
  local wins = targets.visible_sorted()
  local has_float = false
  for _, w in ipairs(wins) do
    if w == f then has_float = true end
  end
  check("focusable float included", has_float)
  nvim.nvim_win_close(f, true)
end

-- 4. closed window disappears from the list
do
  local wins_before = targets.visible_sorted()
  nvim.nvim_win_close(w3, true)
  local wins_after = targets.visible_sorted()
  local gone = true
  for _, w in ipairs(wins_after) do
    if w == w3 then gone = false end
  end
  check("closed window dropped", gone and #wins_after == #wins_before - 1)
end

-- 5. duplicate buffer in two windows: both listed, ordered by window id
do
  nvim.nvim_command("split")
  local w4 = nvim.nvim_get_current_win()
  nvim.nvim_command("setbuf " .. b1) -- show b1 again (already shown in w1)
  local wins = targets.visible_sorted()
  local pos1, pos4
  for i, w in ipairs(wins) do
    if w == w1 then pos1 = i end
    if w == w4 then pos4 = i end
  end
  check("duplicate buffer windows both present", pos1 and pos4)
  check("duplicate buffer ordered by window id", pos1 < pos4)
  nvim.nvim_win_close(w4, true)
end

-- close remaining splits
nvim.nvim_win_close(w2, true)
nvim.nvim_win_close(w1, true)

print(string.format("visible: %d passed, %d failed", passes, failures))
os.exit(failures > 0 and 1 or 0)
