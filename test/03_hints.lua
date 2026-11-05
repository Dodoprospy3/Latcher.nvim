package.path = "/home/adam/latcher.nvim/lua/?.lua;" .. package.path
local hints = require("latcher.hints")
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

-- two splits as targets
nvim.nvim_command("split")
local w1 = nvim.nvim_get_current_win()
nvim.nvim_command("split")
local w2 = nvim.nvim_get_current_win()

-- 1. show opens one hint per target, flush with each top-right corner
do
  local err = hints.show({ ["1"] = w1, ["2"] = w2 })
  check("no error showing hints", err == nil and tostring(err))
  local count = 0
  for _, w in ipairs(nvim.nvim_tabpage_list_wins(0)) do
    local cfg = nvim.nvim_win_get_config(w)
    if cfg.relative == "editor" and cfg.width == 3 and cfg.height == 1
      and cfg.border == "none" and cfg.focusable == false and cfg.zindex == 300
    then
      count = count + 1
    end
  end
  check("two hint windows opened", count == 2)

  -- geometry: each hint sits at the target's top-right corner cell
  local ok_geo = true
  local targets = { [w1] = true, [w2] = true }
  for _, w in ipairs(nvim.nvim_tabpage_list_wins(0)) do
    local cfg = nvim.nvim_win_get_config(w)
    if cfg.relative == "editor" and cfg.width == 3 and cfg.height == 1
      and cfg.border == "none" and cfg.focusable == false and cfg.zindex == 300
    then
      -- find which target this hint belongs to by matching row + right edge
      local hsp = vim.fn.win_screenpos(w)
      local matched = false
      for target in pairs(targets) do
        local tw = nvim.nvim_win_get_width(target)
        local tsp = vim.fn.win_screenpos(target)
        local want_row = tsp[1]
        local want_col = tsp[2] + tw - 3
        if hsp[1] == want_row and hsp[2] == want_col then
          matched = true
          break
        end
      end
      if not matched then
        ok_geo = false
        print("   misplaced hint: hint=" .. vim.inspect(hsp) .. " targets="
          .. vim.inspect(targets))
      end
    end
  end
  check("hints flush with top-right corner cells", ok_geo)

  -- config fields
  local found = 0
  for _, w in ipairs(nvim.nvim_tabpage_list_wins(0)) do
    local cfg = nvim.nvim_win_get_config(w)
    if cfg.relative == "editor" and cfg.width == 3 and cfg.height == 1
      and cfg.border == "none" and cfg.focusable == false and cfg.zindex == 300
    then
      found = found + 1
      check("hint config: focusable=false, border=none, anchor=NW",
        cfg.focusable == false and cfg.border == "none" and cfg.anchor == "NW")
      check("hint is 3-wide badge", cfg.width == 3 and cfg.height == 1)
    end
  end
  check("found both hints via config", found == 2)
end

-- 2. floating target gets a hint too (relative-to-float anchoring)
do
  local f = nvim.nvim_open_win(0, false, {
    relative = "editor", width = 12, height = 4, row = 2, col = 2,
    focusable = true, style = "minimal",
  })
  local err = hints.show({ ["7"] = f })
  check("float hint no error", err == nil and tostring(err))
  local found_float_hint = false
  local fsp = vim.fn.win_screenpos(f)
  for _, w in ipairs(nvim.nvim_tabpage_list_wins(0)) do
    local cfg = nvim.nvim_win_get_config(w)
    if cfg.relative == "editor" and cfg.width == 3 and cfg.height == 1
      and cfg.border == "none" and cfg.focusable == false and cfg.zindex == 300
    then
      local hsp = vim.fn.win_screenpos(w)
      -- only check the hint on the same row as the float (split hints are on
      -- different rows)
      if hsp[1] == fsp[1] then
        found_float_hint = true
        local tw = nvim.nvim_win_get_width(f)
        check("float hint at top-right corner",
          hsp[1] == fsp[1] and hsp[2] == fsp[2] + tw - 3)
      end
    end
  end
  check("float hint opened", found_float_hint)
  nvim.nvim_win_close(f, true)
end

-- 3. close_all removes everything
do
  hints.close_all()
  local leftovers = 0
  for _, w in ipairs(nvim.nvim_tabpage_list_wins(0)) do
    local cfg = nvim.nvim_win_get_config(w)
    if cfg.relative == "editor" and cfg.width == 3 and cfg.height == 1
      and cfg.border == "none" and cfg.focusable == false and cfg.zindex == 300
    then
      leftovers = leftovers + 1
    end
  end
  check("no hint windows left after close_all", leftovers == 0)
  check("close_all runs without error", true)
end

nvim.nvim_win_close(w2, true)
nvim.nvim_win_close(w1, true)

print(string.format("hints: %d passed, %d failed", passes, failures))
os.exit(failures > 0 and 1 or 0)
