#!/bin/bash
# Quickshell startup script — launched by Hyprland exec-once
# After restart: reopens wallpaper picker and/or shows light mode prompt if flagged.

sleep 0.5

# Kill any existing quickshell instance
killall -9 quickshell 2>/dev/null || pkill -9 -x quickshell 2>/dev/null || true
sleep 0.3

# Launch quickshell completely detached
nohup quickshell -n -p "$HOME/.config/quickshell/shell.qml" >/dev/null 2>&1 &
disown

# Wait for quickshell IPC to be ready (up to 5s)
for i in $(seq 1 25); do
  sleep 0.2
  quickshell ipc --any-display show >/dev/null 2>&1 && break
done

# If the wallpaper picker was open before theme reload, reopen it
if [ -f "$HOME/.cache/quickshell/wp_selector_open" ]; then
  rm -f "$HOME/.cache/quickshell/wp_selector_open"
  quickshell ipc --any-display call WallpaperController openSelector 2>/dev/null || true
fi

# If the Rice Editor was open before theme reload, reopen it
if [ -f "$HOME/.cache/quickshell/rice_editor_open" ]; then
  READ_VAL=$(cat "$HOME/.cache/quickshell/rice_editor_open" 2>/dev/null || echo "false")
  if [ "$READ_VAL" = "true" ]; then
    quickshell ipc --any-display call RiceEditorController open 2>/dev/null || true
  fi
fi

# If a bright wallpaper was detected, show the light mode prompt
if [ -f "$HOME/.cache/quickshell/prompt_light_mode" ]; then
  rm -f "$HOME/.cache/quickshell/prompt_light_mode"
  quickshell ipc --any-display call ThemeController promptLightMode 2>/dev/null || true
fi
