local rules = {
    "general:gaps_in = 5",
    "general:gaps_out = 10",
    "general:border_size = 2",
    "general:col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg",
    "general:col.inactive_border = rgba(595959aa)",
    "general:resize_on_border = false",
    "general:allow_tearing = false",
    "general:layout = dwindle",
    "decoration:rounding = 10",
    "decoration:active_opacity = 1.0",
    "decoration:inactive_opacity = 1.0",
    "decoration:shadow:enabled = true",
    "decoration:shadow:range = 4",
    "decoration:shadow:render_power = 3",
    "decoration:shadow:color = rgba(1a1a1aee)",
    "decoration:blur:enabled = true",
    "decoration:blur:size = 3",
    "decoration:blur:passes = 1",
    "decoration:blur:vibrancy = 0.1696"
}

for _, r in ipairs(rules) do
    os.execute("hyprctl eval '" .. r .. "' >/dev/null 2>&1")
end
