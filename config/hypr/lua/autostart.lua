local apps = {
    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
    "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
    "quickshell -n -p " .. os.getenv("HOME") .. "/.config/quickshell/shell.qml",
    "hyprpaper",
    "wallust run " .. os.getenv("HOME") .. "/.config/hypr/wallpapers/default.png",
    "dunst",
    "wl-paste --type text --watch cliphist store",
    "wl-paste --type image --watch cliphist store",
    "hypridle"
}

for _, app in ipairs(apps) do
    os.execute("hyprctl eval 'exec-once = " .. app .. "' >/dev/null 2>&1")
end
