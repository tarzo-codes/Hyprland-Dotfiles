---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"
local terminal = "kitty"
local fileManager = "dolphin"

-- Application & System Launchers
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bindr(mainMod .. " + Super_L", hl.dsp.exec_cmd("vicinae toggle"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + F", hl.dsp.fullscreen())
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("~/.config/scripts/screenshot.sh"))
hl.bind("Print", hl.dsp.exec_cmd("~/.config/scripts/screenshot.sh"))

-- Web Browser (Zen Browser)
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("zen-browser"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("zen-browser --private-window"))

-- Quickshell & Wallpaper Management
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("quickshell ipc call ThemeController toggleWallpaperSelector"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("quickshell ipc call ThemeController toggleWallpaperSelector"))
hl.bind(mainMod .. " + SHIFT + ALT + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("quickshell ipc call ThemeController toggleThemeSelector"))
hl.bind(mainMod .. " + CTRL + SHIFT + T", hl.dsp.exec_cmd("quickshell ipc call ThemeController nextTheme"))
hl.bind("CTRL + SHIFT + ALT + T", hl.dsp.exec_cmd("quickshell ipc call ThemeController toggleTheme"))
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd("quickshell ipc call CheatSheetController toggle"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Move Window with mainMod shift + arrow keys
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

-- Resize the active window
hl.bindr(mainMod .. " + CTRL + right", hl.dsp.window.resize({ delta = {20, 0} }))
hl.bindr(mainMod .. " + CTRL + up",    hl.dsp.window.resize({ delta = {0, -20} }))
hl.bindr(mainMod .. " + CTRL + left",  hl.dsp.window.resize({ delta = {-20, 0} }))
hl.bindr(mainMod .. " + CTRL + down",  hl.dsp.window.resize({ delta = {0, 20} }))

-- Move active windows to a new workspace
hl.bind(mainMod .. " + CTRL + SHIFT + right", hl.dsp.window.move({ workspace = "r+1" }))
hl.bind(mainMod .. " + CTRL + SHIFT + left",  hl.dsp.window.move({ workspace = "r-1" }))

-- Move active windows between workspace
hl.bind(mainMod .. " + ALT + SHIFT + right", hl.dsp.window.move({ workspace = "e+1" }))
hl.bind(mainMod .. " + ALT + SHIFT + left",  hl.dsp.window.move({ workspace = "e-1" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + CTRL + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "r-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bindm(mainMod .. " + mouse:272", "movewindow")
hl.bindm(mainMod .. " + mouse:273", "resizewindow")

-- Laptop multimedia keys for volume and LCD brightness
hl.bindel("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"))
hl.bindel("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
hl.bindel("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bindel("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
hl.bindel("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"))
hl.bindel("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"))

-- Requires playerctl
hl.bindl("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"))
hl.bindl("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bindl("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"))
hl.bindl("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"))
