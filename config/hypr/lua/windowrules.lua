local windowrules = {
    "suppressevent maximize, class:.*",
    "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0",
    "float, class:^(org.pulseaudio.pavucontrol)$",
    "size 680 480, class:^(org.pulseaudio.pavucontrol)$",
    "center, class:^(org.pulseaudio.pavucontrol)$",
    "float, class:^(nm-connection-editor)$",
    "size 620 480, class:^(nm-connection-editor)$",
    "center, class:^(nm-connection-editor)$",
    "float, class:^(systemsettings)$",
    "float, class:^(kcmshell6)$",
    "float, class:^(org.kde.plasmawindowed)$",
    "size 450 550, class:^(org.kde.plasmawindowed)$",
    "center, class:^(org.kde.plasmawindowed)$"
}

for _, wr in ipairs(windowrules) do
    os.execute("hyprctl eval 'windowrulev2 = " .. wr .. "' >/dev/null 2>&1")
end
