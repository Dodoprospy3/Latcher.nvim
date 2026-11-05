-- Resolve the repo root from this script's path so tests run from any cwd/CI.
local script = debug.getinfo(1, "S").source:sub(2)
local root = vim.fn.fnamemodify(script, ":p:h:h")
package.path = root .. "/lua/?.lua;" .. package.path
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

--- True if `w` is a Latcher hint float.
local function is_hint(w)
  local cfg = nvim.nvim_win_get_config(w)
  return cfg.relative == "editor"
    and cfg.width == 3 and cfg.height == 1
    and cfg.border ~= "none"
    and cfg.border ~= nil
    and cfg.focusable == false
    and cfg.zindex == 300
end

--- Return all hint window ids of the current tabpage.
local function hint_wins()
  local out = {}
  for _, w in ipairs(nvim.nvim_tabpage_list_wins(0)) do
    if is_hint(w) then
      out[#out + 1] = w
    end
  end
  return out
end

-- Regression guard: reproduce a user config with a line-number gutter.
nvim.nvim_set_option_value("number", true, {})
nvim.nvim_set_option_value("relativenumber", true, {})

-- two splits as targets
nvim.nvim_command("split")
local w1 = nvim.nvim_get_current_win()
nvim.nvim_command("split")
local w2 = nvim.nvim_get_current_win()

-- 1. show opens one hint per target, flush with each top-right corner
do
  local err = hints.show({ ["1"] = w1, ["2"] = w2 })
  check("no error showing hints", err == nil, tostring(err))

  local wins = hint_wins()
  check("two hint windows opened", #wins == 2)

  -- geometry: cfg.row/col are 0-based editor coords; win_screenpos is 1-based.
  local ok_geo = true
  local targets = { w1, w2 }
  for _, h in ipairs(wins) do
    local cfg = nvim.nvim_win_get_config(h)
    local matched = false
    for _, target in ipairs(targets) do
      local tw = nvim.nvim_win_get_width(target)
      local tsp = vim.fn.win_screenpos(target)
      local want_row = tsp[1] - 1
      local want_col = tsp[2] + tw - 4
      if cfg.row == want_row and cfg.col == want_col then
        matched = true
        break
      end
    end
    if not matched then
      ok_geo = false
      print("   misplaced hint: row=" .. cfg.row .. " col=" .. cfg.col)
    end
  end
  check("hints flush with top-right corner cells", ok_geo)

  -- Gutter regression: number/relativenumber in the parent window must NOT
  -- leak into the 3-cell hint float, otherwise the gutter renders "1" and
  -- hides the real "[N]" text.
  local gutters_off = true
  for _, h in ipairs(wins) do
    if nvim.nvim_get_option_value("number", { win = h })
      or nvim.nvim_get_option_value("relativenumber", { win = h })
      or nvim.nvim_get_option_value("signcolumn", { win = h }) ~= "no"
      or nvim.nvim_get_option_value("foldcolumn", { win = h }) ~= "0"
      or nvim.nvim_get_option_value("wrap", { win = h })
    then
      gutters_off = false
    end
  end
  check("hint windows disable inherited gutters", gutters_off)

  -- The badge buffer itself must contain the distinct "[N]" text.
  local seen = {}
  for _, h in ipairs(wins) do
    local buf = nvim.nvim_win_get_buf(h)
    local line = nvim.nvim_buf_get_lines(buf, 0, 1, false)[1]
    seen[line] = true
  end
  check("badges contain distinct [1] and [2]", seen["[1]"] and seen["[2]"],
    vim.inspect(seen))

  -- config fields
  for _, h in ipairs(wins) do
    local cfg = nvim.nvim_win_get_config(h)
    check("hint config: focusable=false, anchor=NW",
      cfg.focusable == false and cfg.anchor == "NW")
    check("hint is 3-wide badge", cfg.width == 3 and cfg.height == 1)
    check("hint has a visible border", cfg.border ~= "none" and cfg.border ~= nil)
  end
end

-- 2. floating target gets a hint too
do
  local f = nvim.nvim_open_win(0, false, {
    relative = "editor", width = 12, height = 4, row = 2, col = 2,
    focusable = true, style = "minimal",
  })
  local err = hints.show({ ["7"] = f })
  check("float hint no error", err == nil, tostring(err))
  local found_float_hint = false
  local fsp = vim.fn.win_screenpos(f)
  for _, h in ipairs(hint_wins()) do
    local cfg = nvim.nvim_win_get_config(h)
    -- only check the hint on the same row as the float (split hints are on
    -- different rows)
    if cfg.row == fsp[1] - 1 then
      found_float_hint = true
      local tw = nvim.nvim_win_get_width(f)
      check("float hint at top-right corner", cfg.col == fsp[2] + tw - 4)
    end
  end
  check("float hint opened", found_float_hint)
  nvim.nvim_win_close(f, true)
end

-- 3. close_all removes everything
do
  hints.close_all()
  check("no hint windows left after close_all", #hint_wins() == 0)
  check("close_all runs without error", true)
end

nvim.nvim_win_close(w2, true)
nvim.nvim_win_close(w1, true)

print(string.format("hints: %d passed, %d failed", passes, failures))
os.exit(failures > 0 and 1 or 0)
