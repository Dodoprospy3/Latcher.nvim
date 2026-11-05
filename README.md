# Latcher.nvim

Quick navigation between currently visible Neovim windows using numbered visual
hints. Pure Lua, no dependencies, Neovim 0.10+.

<img width="6px" height="6px" alt=""> <!-- kept intentionally minimal -->

## Features

- `:Latcher` — show a small numbered hint in the top-right corner of every
  eligible visible window (splits and floating windows), then type a number to
  jump to that window. `<Esc>` cancels. Maximum of 9 targets.
- `:LatcherReassign` — assign a number 1-9 to the buffer in the current
  window. If the number already belongs to another window, that window loses
  the number (it shows no hint until it wins one again); nothing else shifts or
  swaps.
- Numbers follow buffer creation order initially; manual assignments persist
  for the session.
- Hint windows never touch any buffer's contents, and are fully cleaned up
  after every selection or cancellation.

## Installation

### lazy.nvim

```lua
{
  "Dodoprospy3/Latcher.nvim",
  cmd = "Latcher",
  config = function()
    require("latcher").setup()
  end,
  keys = {
    { "<leader>w", "<cmd>Latcher<cr>", desc = "Jump to visible window" },
    { "<leader>W", "<cmd>LatcherReassign<cr>", desc = "Reassign window number" },
  },
}
```

The plugin also works when loaded eagerly (`lazy = false`) — the
`plugin/latcher.lua` entry point calls `setup()` automatically on startup.

### Manual

Copy the repository into your runtimepath, e.g.

```sh
git clone https://github.com/Dodoprospy3/Latcher.nvim \
  ~/.local/share/nvim/site/pack/latcher/start/Latcher.nvim
```

Then call `require("latcher").setup()` from your config (or rely on the
automatic startup entry point).

## Commands

| Command | Meaning |
|---------|---------|
| `:Latcher` | Enter navigation mode: show hints, type a number to jump. `<Esc>` cancels. |
| `:LatcherReassign` | Assign a number 1-9 to the current window (read as one keystroke). |

## Lua API

```lua
require("latcher").setup({})
```

`setup` accepts an empty table (reserved for future options; unknown keys are
rejected explicitly rather than silently ignored).

The same actions are exposed as `require("latcher").start()` and
`require("latcher").reassign()` for custom mappings.

## How numbering works

1. Every visible, focusable window displaying a valid buffer is eligible.
2. Windows are ordered by buffer creation order (buffer numbers) and then by
   window id, so duplicate buffers shown in several windows are deterministic.
3. The first 9 windows get numbers 1-9 in that order.
4. Manual assignments from `:LatcherReassign` always win. If you assign number
   N to the current window and N belonged to another window, that window is
   stripped: it shows no hint until it wins a number naturally again. No other
   window shifts or swaps.
5. Hints are floating windows anchored to each target's top-right corner —
   they track splits and float windows automatically.

## Customization

Hints use the `LatcherHint` highlight group (linked to `Visual` by default).
Override it in your colorscheme config, e.g.

```lua
vim.api.nvim_set_hl(0, "LatcherHint", { bold = true, fg = "#ffffff", bg = "#45475a" })
```

## Requirements

- Neovim 0.10+
- No external dependencies (pure Lua, built-in API only)

## License

[MIT](LICENSE) — Copyright (c) 2026 Dodoprospy3
