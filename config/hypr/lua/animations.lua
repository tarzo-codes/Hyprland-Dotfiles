local anims = {
    "animations:enabled = true",
    "animations:bezier = myBezier, 0.05, 0.9, 0.1, 1.05",
    "animations:animation = windows, 1, 7, myBezier",
    "animations:animation = windowsOut, 1, 7, default, popin 80%",
    "animations:animation = border, 1, 10, default",
    "animations:animation = borderangle, 1, 8, default",
    "animations:animation = fade, 1, 7, default",
    "animations:animation = workspaces, 1, 6, default"
}

for _, a in ipairs(anims) do
    os.execute("hyprctl eval '" .. a .. "' >/dev/null 2>&1")
end
