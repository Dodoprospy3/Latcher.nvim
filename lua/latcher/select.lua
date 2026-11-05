--- Blocking, single-keystroke input for navigation and reassignment.
--
-- Design decisions:
--   * vim.fn.getcharstr() blocks until a key arrives and pulls from typeahead,
--     which makes it trivial to drive from tests with vim.fn.feedkeys().
--   * <Esc> and <C-c> cancel (getcharstr raises on <C-c>, which we treat as a
--     cancellation rather than surfacing a confusing error).
--   * Every key that is not an accepted digit is ignored and swallowed: the
--     user stays in navigation mode until they pick a valid number or cancel.
--   * Acceptance is injected through the `accept` callback so the same loop
--     serves both navigation (must be a shown number) and reassignment
--     (any digit 1-9).

local M = {}

--- Wait until the user presses an acceptable digit, then return it.
-- Returns nil on cancellation (<Esc>, <C-c>, or an interrupt).
-- @param accept function(number) -> boolean: whether a digit is acceptable
function M.read_number(accept)
  while true do
    local ok, key = pcall(vim.fn.getcharstr)
    if not ok then
      -- <C-c> interrupts getcharstr() with an error; treat as cancel.
      return nil
    end
    if key == "\\e" or key == "\27" then
      -- "<Esc>" (legacy) and the raw escape byte returned by real terminals.
      return nil
    end
    local num = tonumber(key)
    if num and accept(num) then
      return num
    end
    -- any other key: swallowed, keep waiting
  end
end

--- Read any digit 1-9 for manual reassignment.
-- Returns the digit, or nil on cancel.
function M.read_digit()
  return M.read_number(function(num)
    return num >= 1 and num <= 9
  end)
end

--- Read one of the currently shown navigation numbers.
-- @param valid {[number] = true} numbers that currently have a target
-- Returns the chosen number, or nil on cancel.
function M.pick(valid)
  return M.read_number(function(num)
    return valid[num] == true
  end)
end

return M
