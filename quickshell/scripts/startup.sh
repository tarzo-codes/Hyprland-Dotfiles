#!/bin/bash
# Quickshell startup script — launched by Hyprland exec-once
# Waits for Wayland socket, then starts quickshell

# Wait for Hyprland to be ready
sleep 0.5

# Kill any existing quickshell instance
pkill -x quickshell 2>/dev/null
sleep 0.2

# Launch quickshell
exec quickshell --path ~/.config/quickshell/shell.qml
