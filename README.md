# Latcher.nvim

**Numbered window navigation for Neovim.** Run `:Latcher`, see `[1]`–`[9]` in
the top-right corner of every visible window, type a number, and jump there.

![Latcher demo: three Neovim windows with [1], [2], and [3] badges in their top-right corners](assets/demo.gif)
> NOTE: this GIF is a simluation and real visual styles or functionality may differ 

[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Neovim 0.10+](https://img.shields.io/badge/Neovim-0.10%2B-green.svg)](https://neovim.io)

## Features

- **`:Latcher`** — number every eligible visible window (splits *and*
  floating windows), then type `1`–`9` to jump. `<Esc>` cancels.
- **`:LatcherReassign`** — pin a number `1`–`9` to the current window. The
  assignment persists for the session.
- **No shifting, no swapping** — if you reassign a number that belongs to
  another window, that window simply loses its hint. Every other number stays
  put.
- **Zero dependencies** — pure Lua, built-in Neovim API only, Neovim 0.10+.
- **Never touches your buffers** — hints are floating windows, not extmarks or
  virtual text, so no buffer contents are ever modified.
- **Always cleans up** — hints are removed after a jump, a cancel, or an error.

## How it differs

Most window switchers use letter labels or search-driven jumps. Latcher is
deliberately numeric and persistent:

| | Latcher | Letter/search pickers |
|---|---|---|
| Labels | `1`–`9`, one keystroke | letters (plugin-dependent) |
| Floating windows | included | varies |
| Persistent manual numbers | yes | usually no |
| Dependencies | none | varies |
| Buffer modifications | none | some use extmarks |

If you want fuzzy search or letter-based labels, tools like
[nvim-window-picker](https://github.com/s1n7ax/nvim-window-picker),
[flash.nvim](https://github.com/folke/flash.nvim), or
[harpoon](https://github.com/ThePrimeagen/harpoon) are excellent. Latcher is
for people who want the same window to always answer to the same digit.

## Requirements

- Neovim **0.10+** (tested on 0.10, 0.11, and 0.12)
- No external dependencies

## Installation

### lazy.nvim

```lua
{
  "Dodoprospy3/Latcher.nvim",
  lazy = false, -- tiny plugin: registers :Latcher at startup
  opts = {},
  keys = {
    { "<leader>w", "<cmd>Latcher<cr>", desc = "Jump to a visible window" },
    { "<leader>W", "<cmd>LatcherReassign<cr>", desc = "Assign a window number" },
  },
}
```

`opts = {}` calls `require("latcher").setup()`. The plugin also calls setup
automatically from `plugin/latcher.lua`, so it works with any plugin manager.

### vim.pack (Neovim 0.12+)

```lua
vim.pack.add({ "https://github.com/Dodoprospy3/Latcher.nvim" })
require("latcher").setup()
```

### Manual

```sh
git clone https://github.com/Dodoprospy3/Latcher.nvim \
  ~/.local/share/nvim/site/pack/latcher/start/Latcher.nvim
```

Then restart Neovim. The startup entry point defines the commands for you.

## Usage

1. Open two or more windows (`:split`, `:vsplit`, or a floating window).
2. Run `:Latcher` (or your mapping).
3. A bright `[N]` badge appears at the top-right of each eligible window.
4. Type the number of the window you want. `<Esc>` or `<C-c>` cancels.
5. Run `:LatcherReassign`, then type a digit, to pin that number to the current
   window.

Keys that are not shown numbers are ignored while Latcher waits, so a stray
keypress will not break the session.

## How numbering works

1. Every visible, focusable window displaying a valid buffer is eligible
   (splits and floats alike).
2. Windows are ordered by buffer number, then by window id, and the first nine
   receive `1`–`9`.
3. Manual assignments from `:LatcherReassign` always win and persist for the
   Neovim session.
4. If a manual assignment takes a number from another window, that window is
   *stripped*: it shows no hint until it wins a number again naturally.
   Nothing else shifts or swaps.

## Commands

| Command | Description |
|---|---|
| `:Latcher` | Show hints and wait for a digit `1`–`9`. `<Esc>` cancels. |
| `:LatcherReassign` | Assign the next typed digit `1`–`9` to the current window. |

## Lua API

```lua
require("latcher").setup({})   -- define commands and highlight
require("latcher").start()     -- same as :Latcher
require("latcher").reassign()  -- same as :LatcherReassign
```

`setup()` accepts an empty table. Unknown keys raise an error instead of being
silently ignored; the table is reserved for future options.

## Customization

Hints use the `LatcherHint` highlight group — white bold text on a red
background by default:

```lua
vim.api.nvim_set_hl(0, "LatcherHint", {
  fg = "#ffffff",
  bg = "#d20f39",
  bold = true,
})
```

The highlight can also be overridden per colorscheme in the usual way.

## Development

```sh
git clone https://github.com/Dodoprospy3/Latcher.nvim
cd Latcher.nvim

for t in test/0*.lua; do
  nvim -u NONE -i NONE -N --headless --cmd 'set rtp+=.' \
    -c "luafile $t" -c 'qa!'
done
```

## Contributing

Issues and pull requests are welcome. Please run the test suite above before
opening a PR.

## License

[MIT](LICENSE) — Copyright (c) 2026 Dodoprospy3
