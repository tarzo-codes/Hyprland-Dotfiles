----------------------
---- WINDOW RULES ----
----------------------

-- Pavucontrol Volume Control
hl.window_rule({
    name = "pavucontrol-float",
    match = { class = "^(org\\.pulseaudio\\.pavucontrol)$" },
    float = true,
    size = "680 480",
    center = true,
})

hl.window_rule({
    name = "volume-control-title",
    match = { title = "^(Volume Control)$" },
    float = true,
})

-- Network Connections Editor
hl.window_rule({
    name = "nm-connection-editor-float",
    match = { class = "^(nm-connection-editor)$" },
    float = true,
    size = "620 480",
    center = true,
})

hl.window_rule({
    name = "network-connections-title",
    match = { title = "^(Network Connections)$" },
    float = true,
})

-- KDE System Settings & Plasma Windowed
hl.window_rule({
    name = "systemsettings-float",
    match = { class = "^(systemsettings)$" },
    float = true,
})

hl.window_rule({
    name = "kcmshell6-float",
    match = { class = "^(kcmshell6)$" },
    float = true,
})

hl.window_rule({
    name = "plasmawindowed-float",
    match = { class = "^(org\\.kde\\.plasmawindowed)$" },
    float = true,
    size = "450 550",
    center = true,
})
