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
hl.bind(mainMod .. " + Super_L", hl.dsp.exec_cmd("vicinae toggle"), { release = true })
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.exec_cmd("hyprctl dispatch layoutmsg togglesplit"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
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
hl.bind(mainMod .. " + left",  hl.dsp.exec_cmd("hyprctl dispatch movefocus l"))
hl.bind(mainMod .. " + right", hl.dsp.exec_cmd("hyprctl dispatch movefocus r"))
hl.bind(mainMod .. " + up",    hl.dsp.exec_cmd("hyprctl dispatch movefocus u"))
hl.bind(mainMod .. " + down",  hl.dsp.exec_cmd("hyprctl dispatch movefocus d"))

-- Move Window with mainMod shift + arrow keys
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.exec_cmd("hyprctl dispatch movewindow l"))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.exec_cmd("hyprctl dispatch movewindow r"))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.exec_cmd("hyprctl dispatch movewindow u"))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.exec_cmd("hyprctl dispatch movewindow d"))

-- Resize the active window
hl.bind(mainMod .. " + CTRL + right", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 20 0"), { release = true })
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 -20"), { release = true })
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.exec_cmd("hyprctl dispatch resizeactive -20 0"), { release = true })
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 20"), { release = true })

-- Move active windows to a new workspace
hl.bind(mainMod .. " + CTRL + SHIFT + right", hl.dsp.exec_cmd("hyprctl dispatch movetoworkspace r+1"))
hl.bind(mainMod .. " + CTRL + SHIFT + left",  hl.dsp.exec_cmd("hyprctl dispatch movetoworkspace r-1"))

-- Move active windows between workspace
hl.bind(mainMod .. " + ALT + SHIFT + right", hl.dsp.exec_cmd("hyprctl dispatch movetoworkspace e+1"))
hl.bind(mainMod .. " + ALT + SHIFT + left",  hl.dsp.exec_cmd("hyprctl dispatch movetoworkspace e-1"))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.exec_cmd("hyprctl dispatch workspace " .. i))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.exec_cmd("hyprctl dispatch movetoworkspace " .. i))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.exec_cmd("hyprctl dispatch togglespecialworkspace magic"))
hl.bind(mainMod .. " + CTRL + SHIFT + S", hl.dsp.exec_cmd("hyprctl dispatch movetoworkspace special:magic"))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.exec_cmd("hyprctl dispatch workspace r+1"))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.exec_cmd("hyprctl dispatch workspace r-1"))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { drag = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { drag = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true, locked = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true, locked = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { repeating = true, locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { repeating = true, locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { repeating = true, locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { repeating = true, locked = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"), { locked = true })
