-- Minimal configuration used to record assets/demo.gif (see demo.tape).
-- Run from the repository root:
--   nvim -u demo/init.lua lua/latcher/targets.lua
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.signcolumn = "no"
vim.opt.laststatus = 3
vim.opt.ruler = false
vim.opt.showcmd = false
vim.opt.wrap = false
vim.opt.fillchars = { eob = " " }

-- Make the plugin available without installing it.
vim.opt.runtimepath:prepend(vim.fn.getcwd())
vim.cmd.colorscheme("habamax")
vim.cmd("runtime plugin/latcher.lua")
