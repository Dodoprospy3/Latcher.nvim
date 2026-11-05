-- latcher.nvim plugin entry point.
-- Sourced by Neovim's runtime on startup (from plugin/). Guards against being
-- sourced more than once so commands/highlights are defined exactly once.

if vim.g.loaded_latcher then
  return
end
vim.g.loaded_latcher = 1

require("latcher").setup()
