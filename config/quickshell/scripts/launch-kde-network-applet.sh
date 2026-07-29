#!/bin/bash
# Launches KDE Plasma Wi-Fi / Network Applet as a clean floating centered popup with dark Kirigami styling
pkill -f "plasmawindowed org.kde.plasma.networkmanagement" 2>/dev/null || true

export QT_QUICK_CONTROLS_STYLE=org.kde.desktop
export PLASMA_THEME=breeze-dark
export KDE_COLOR_SCHEME=FluxDots
export KDE_FULL_SESSION=true
export DESKTOP_SESSION=plasma

plasmawindowed org.kde.plasma.networkmanagement >/dev/null 2>&1 &
sleep 0.7
hyprctl dispatch togglefloating class:org.kde.plasmawindowed 2>/dev/null || true
hyprctl dispatch resizewindowpixel exact 450 550,class:org.kde.plasmawindowed 2>/dev/null || true
hyprctl dispatch centerwindow 2>/dev/null || true
