local miscs = {
    "misc:force_default_wallpaper = -1",
    "misc:disable_hyprland_logo = false",
    "input:kb_layout = us",
    "input:follow_mouse = 1",
    "input:sensitivity = 0",
    "input:touchpad:natural_scroll = false"
}

for _, m in ipairs(miscs) do
    os.execute("hyprctl eval '" .. m .. "' >/dev/null 2>&1")
end
