# Record the demo GIF with VHS: https://github.com/charmbracelet/vhs
#   vhs demo.tape
# Produces assets/demo.gif.
Output assets/demo.gif

Set Shell "bash"
Set FontFamily "JetBrains Mono"
Set FontSize 18
Set Width 1200
Set Height 760
Set Padding 24
Set Theme "Catppuccin Mocha"
Set TypingSpeed 60ms

Hide
Type "nvim -u demo/init.lua lua/latcher/targets.lua"
Enter
Sleep 2s
Type ":vsplit lua/latcher/hints.lua"
Enter
Sleep 500ms
Type ":split lua/latcher/select.lua"
Enter
Sleep 500ms
Type ":echo"
Enter
Sleep 1s
Show

# 1. Three visible windows, no hints yet.
Sleep 1.5s

# 2. Latcher numbers every window.
Type ":Latcher"
Sleep 500ms
Enter
Sleep 2.5s

# 3. Type a number to jump.
Type "1"
Sleep 2s

# 4. Show hints again, then cancel with Escape.
Type ":Latcher"
Sleep 300ms
Enter
Sleep 1.5s
Type "Escape"
Sleep 1.5s
