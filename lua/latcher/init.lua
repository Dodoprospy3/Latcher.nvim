--- latcher.nvim: numbered window navigation for Neovim.
--
-- Public interface:
--   require("latcher").setup({})        -- define commands and highlights
--   require("latcher").start()          -- :Latcher
--   require("latcher").reassign()       -- :LatcherReassign

local M = {}

local nav = require("latcher.nav")

--- Validate and store setup options. No options exist yet; unknown keys are
--- rejected explicitly instead of being silently ignored.
local function validate_options(opts)
  if opts == nil then
    return {}
  end
  if type(opts) ~= "table" then
    error("latcher.setup: expected a table of options", 2)
  end
  for key in pairs(opts) do
    error(("latcher.setup: unknown option %q"):format(tostring(key)), 2)
  end
  return opts
end

--- Define the user-facing commands (idempotent).
local function define_commands()
  if vim.fn.exists(":Latcher") == 0 then
    vim.api.nvim_create_user_command("Latcher", function()
      nav.start()
    end, { desc = "Latcher: jump to a visible window by number" })
  end
  if vim.fn.exists(":LatcherReassign") == 0 then
    vim.api.nvim_create_user_command("LatcherReassign", function()
      nav.reassign()
    end, { desc = "LatcherReassign: assign a number to the current window" })
  end
end

--- Initialize the plugin. Call once, e.g. `require("latcher").setup()`.
-- @param opts configuration table (currently empty; reserved for the future)
function M.setup(opts)
  validate_options(opts)

  -- Bright, unmissable hint color: white bold text on red background.
  -- Set explicitly (not `default`) so it survives colorscheme changes.
  vim.api.nvim_set_hl(0, "LatcherHint", {
    fg = "#ffffff",
    bg = "#ff0000",
    bold = true,
  })
  define_commands()
end

--- Enter navigation mode (same as :Latcher). Exposed for Lua users and keys.
function M.start()
  nav.start()
end

--- Assign a number to the current window (same as :LatcherReassign).
function M.reassign()
  nav.reassign()
end

return M
