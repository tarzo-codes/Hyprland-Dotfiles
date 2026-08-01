local binds = {
    "SUPER, RETURN, exec, kitty",
    "SUPER, Q, killactive",
    "SUPER, M, exec, command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit",
    "SUPER, E, exec, dolphin",
    "SUPER, V, togglefloating",
    "SUPER, r, exec, quickshell ipc call RiceEditorController toggle",
    "ALT, TAB, exec, quickshell ipc call TaskSwitcherController toggle",
    "SUPER, P, pseudo",
    "SUPER, J, layoutmsg, togglesplit",
    "SUPER, F, fullscreen",
    "SUPER SHIFT, S, exec, ~/.config/scripts/screenshot.sh",
    "Print, exec, ~/.config/scripts/screenshot.sh",
    "SUPER, B, exec, zen-browser",
    "SUPER SHIFT, B, exec, zen-browser --private-window",
    "SUPER, W, exec, quickshell ipc call ThemeController toggleWallpaperSelector",
    "SUPER SHIFT, ALT, L, exec, hyprlock",
    "SUPER, T, exec, quickshell ipc call ThemeController toggleThemeSelector",
    "SUPER SHIFT, V, exec, quickshell ipc call ClipboardController toggle",
    "SUPER ALT, M, exec, quickshell ipc call DesktopMenuController toggle",
    "SUPER CTRL SHIFT, T, exec, quickshell ipc call ThemeController nextTheme",
    "CTRL SHIFT ALT, T, exec, quickshell ipc call ThemeController toggleTheme",
    "SUPER, slash, exec, quickshell ipc call CheatSheetController toggle",
    "SUPER, left, movefocus, l",
    "SUPER, right, movefocus, r",
    "SUPER, up, movefocus, u",
    "SUPER, down, movefocus, d",
    "SUPER SHIFT, left, movewindow, l",
    "SUPER SHIFT, right, movewindow, r",
    "SUPER SHIFT, up, movewindow, u",
    "SUPER SHIFT, down, movewindow, d"
}

for i = 1, 10 do
    local key = tostring(i % 10)
    table.insert(binds, "SUPER, " .. key .. ", workspace, " .. i)
    table.insert(binds, "SUPER SHIFT, " .. key .. ", movetoworkspace, " .. i)
end

for _, b in ipairs(binds) do
    os.execute("hyprctl eval 'bind = " .. b .. "' >/dev/null 2>&1")
end
