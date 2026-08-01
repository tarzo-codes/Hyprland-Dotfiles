local envs = {
    "XCURSOR_SIZE,24",
    "HYPRCURSOR_SIZE,24",
    "PATH," .. os.getenv("HOME") .. "/.local/bin:" .. (os.getenv("PATH") or ""),
    "GDK_BACKEND,wayland,x11,*",
    "QT_QPA_PLATFORM,wayland;xcb",
    "QT_AUTO_SCREEN_SCALE_FACTOR,1",
    "QT_WAYLAND_DISABLE_WINDOWDECORATION,1",
    "QT_QPA_PLATFORMTHEME,kde",
    "QT_QUICK_CONTROLS_STYLE,org.kde.desktop",
    "KDE_COLOR_SCHEME,FluxDots",
    "PLASMA_THEME,breeze-dark",
    "QT_STYLE_OVERRIDE,kvantum"
}

for _, e in ipairs(envs) do
    os.execute("hyprctl eval 'env = " .. e .. "' >/dev/null 2>&1")
end
