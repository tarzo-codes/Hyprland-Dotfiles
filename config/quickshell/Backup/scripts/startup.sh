#!/bin/bash
# Quickshell startup script - sets environment and launches quickshell

QUICK_CONFIG="$HOME/.config/quickshell"

# Create default saved-style file if it doesn't exist
mkdir -p "$QUICK_CONFIG"
if [ ! -f "$QUICK_CONFIG/.saved-style" ]; then
    echo "neon" > "$QUICK_CONFIG/.saved-style"
fi

# Launch quickshell
exec quickshell "$@"