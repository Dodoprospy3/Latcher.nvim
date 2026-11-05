package.path = "/home/adam/latcher.nvim/lua/?.lua;" .. package.path
local targets = require("latcher.targets")

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

local function pcall_resolve(wins, manual, stripped)
  return pcall(targets.resolve, wins, manual, {})
end

-- 1. pure creation-order auto-numbering
do
  local assigned, bynum = targets.resolve({ 10, 20, 30 }, {}, {})
  check("auto assigns 1..n in window order",
    assigned[10] == 1 and assigned[20] == 2 and assigned[30] == 3)
  check("bynum inverts assigned", bynum[1] == 10 and bynum[2] == 20 and bynum[3] == 30)
end

-- 2. manual always wins
do
  local assigned, bynum = targets.resolve({ 10, 20, 30 }, { [20] = 9 }, {})
  check("manual keeps its number", assigned[20] == 9 and bynum[9] == 20)
  check("autos take lowest free numbers", assigned[10] == 1 and assigned[30] == 2)
end

-- 3. stripped window consumes no number and blocks nobody
do
  local stripped = { [20] = true }
  local assigned, bynum = targets.resolve({ 10, 20, 30 }, {}, stripped)
  check("stripped window gets nothing", assigned[20] == nil)
  check("others still compact", assigned[10] == 1 and assigned[30] == 2)
end

-- 4. manual number stolen: previous owner loses it
do
  local manual = { [20] = 5 }
  local stripped = {}
  local assigned, _ = targets.resolve({ 10, 20, 30 }, manual, stripped)
  check("manual owner keeps number", assigned[20] == 5)
  -- now simulate reassignment stealing 5 from 20 to 10
  manual[20] = nil
  stripped[20] = true
  manual[10] = 5
  local assigned2, _ = targets.resolve({ 10, 20, 30 }, manual, stripped)
  check("stolen number moves, victim stripped",
    assigned2[10] == 5 and assigned2[20] == nil and assigned2[30] == 1)
end

-- 5. cap: no more than MAX_TARGETS highlighted
do
  local wins = {}
  for i = 1, 12 do wins[i] = 100 + i end
  local assigned, bynum = targets.resolve(wins, {}, {})
  local count = 0
  for _ in pairs(assigned) do count = count + 1 end
  check("cap at " .. targets.MAX_TARGETS, count == targets.MAX_TARGETS)
  check("first windows in order win the cap", assigned[101] == 1 and assigned[109] == 9)
end

-- 6. corrupted manual state (duplicate number) raises loudly
do
  local ok, err = pcall_resolve({ 10, 20 }, { [10] = 3, [20] = 3 }, {})
  check("duplicate manual number raises", not ok and type(err) == "string")
end

-- 7. out-of-range manual number raises
do
  local ok, err = pcall_resolve({ 10 }, { [10] = 0 }, {})
  check("number 0 raises", not ok)
  local ok2, err2 = pcall_resolve({ 10 }, { [10] = 10 }, {})
  check("number 10 raises", not ok2)
end

print(string.format("resolve: %d passed, %d failed", passes, failures))
os.exit(failures > 0 and 1 or 0)
