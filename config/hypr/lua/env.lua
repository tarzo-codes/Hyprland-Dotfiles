-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("PATH", os.getenv("HOME") .. "/.local/bin:" .. (os.getenv("PATH") or ""))
hl.env("HYPRLAND_CONFIG", os.getenv("HOME") .. "/.config/hypr/hyprland.lua")
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("GTK_THEME", "Breeze-Dark")

-- Qt / KDE Platform Theme & Color Scheme Enforcers
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("QT_QUICK_CONTROLS_STYLE", "org.kde.desktop")
hl.env("KDE_COLOR_SCHEME", "FluxDots")
hl.env("PLASMA_THEME", "breeze-dark")
hl.env("QT_STYLE_OVERRIDE", "kvantum")
