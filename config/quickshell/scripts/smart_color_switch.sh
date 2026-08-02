#!/bin/bash
# Smart Color Analysis Switch Script
# Granular control for smart color features
# Usage: ./smart_color_switch.sh [command]

CONFIG_DIR="$HOME/.config/quickshell"
CONFIG_FILE="$CONFIG_DIR/smart_color_config.json"
BACKUP_DIR="$CONFIG_DIR/Backup/smart-color-upgrade"

# Default configuration
DEFAULT_CONFIG='{
  "cielab": false,
  "kmeans": false,
  "hybrid_extraction": false,
  "semantic_classification": false,
  "temporal_smoothing": false,
  "context_awareness": false,
  "fallback_prompt": false,
  "version": "1.0"
}'

# Initialize config if not exists
init_config() {
  if [ ! -f "$CONFIG_FILE" ]; then
    echo "$DEFAULT_CONFIG" > "$CONFIG_FILE"
    echo "Config initialized at $CONFIG_FILE"
  fi
}

# Get current status
get_status() {
  init_config
  echo "=== Smart Color Feature Status ==="
  echo ""
  if command -v python3 &>/dev/null; then
    python3 -c "
import json
with open('$CONFIG_FILE', 'r') as f:
    config = json.load(f)
features = [
    ('CIELAB Color Space', 'cielab'),
    ('K-means Clustering', 'kmeans'),
    ('Hybrid Accent Extraction', 'hybrid_extraction'),
    ('Semantic Classification', 'semantic_classification'),
    ('Temporal Smoothing', 'temporal_smoothing'),
    ('Context Awareness', 'context_awareness'),
    ('Fallback Prompt', 'fallback_prompt')
]
for name, key in features:
    status = '✓ ENABLED' if config.get(key, False) else '✗ DISABLED'
    print(f'{name:.<40} {status}')
print(f'\nVersion: {config.get(\"version\", \"unknown\")}')
"
  else
    echo "Error: python3 required for config parsing"
    cat "$CONFIG_FILE"
  fi
}

# Set feature state
set_feature() {
  local feature="$1"
  local state="$2"
  init_config
  
  if command -v python3 &>/dev/null; then
    python3 -c "
import json
with open('$CONFIG_FILE', 'r') as f:
    config = json.load(f)
config['$feature'] = $state
with open('$CONFIG_FILE', 'w') as f:
    json.dump(config, f, indent=2)
print("Feature '$feature' set to $state")
"
  else
    echo "Error: python3 required"
    return 1
  fi
}

# Enable all features
enable_all() {
  echo "Enabling all smart color features..."
  set_feature "cielab" "true"
  set_feature "kmeans" "true"
  set_feature "hybrid_extraction" "true"
  set_feature "semantic_classification" "true"
  set_feature "temporal_smoothing" "true"
  set_feature "context_awareness" "true"
  set_feature "fallback_prompt" "true"
  echo "All features enabled. Restarting quickshell..."
  "$CONFIG_DIR/scripts/startup.sh"
}

# Disable all features (revert to original)
disable_all() {
  echo "Disabling all smart color features (reverting to original)..."
  set_feature "cielab" "false"
  set_feature "kmeans" "false"
  set_feature "hybrid_extraction" "false"
  set_feature "semantic_classification" "false"
  set_feature "temporal_smoothing" "false"
  set_feature "context_awareness" "false"
  set_feature "fallback_prompt" "false"
  
  # Restore original files
  if [ -d "$BACKUP_DIR" ]; then
    echo "Restoring original files from backup..."
    cp "$BACKUP_DIR/sync-theme-externals.sh.bak" "$CONFIG_DIR/scripts/sync-theme-externals.sh"
    cp "$BACKUP_DIR/wallpaper_cache_builder.py.bak" "$CONFIG_DIR/scripts/wallpaper_cache_builder.py"
    cp "$BACKUP_DIR/wallpaper_memory.py.bak" "$CONFIG_DIR/scripts/wallpaper_memory.py"
    cp "$BACKUP_DIR/wallpaper_picker.sh.bak" "$HOME/dotfiles/config/scripts/wallpaper_picker.sh"
    echo "Original files restored."
  fi
  
  echo "All features disabled. Restarting quickshell..."
  "$CONFIG_DIR/scripts/startup.sh"
}

# Restore backup files
restore_backup() {
  if [ ! -d "$BACKUP_DIR" ]; then
    echo "Error: Backup directory not found: $BACKUP_DIR"
    return 1
  fi
  
  echo "Restoring files from backup..."
  cp "$BACKUP_DIR/sync-theme-externals.sh.bak" "$CONFIG_DIR/scripts/sync-theme-externals.sh"
  cp "$BACKUP_DIR/wallpaper_cache_builder.py.bak" "$CONFIG_DIR/scripts/wallpaper_cache_builder.py"
  cp "$BACKUP_DIR/wallpaper_memory.py.bak" "$CONFIG_DIR/scripts/wallpaper_memory.py"
  cp "$BACKUP_DIR/wallpaper_picker.sh.bak" "$HOME/dotfiles/config/scripts/wallpaper_picker.sh"
  echo "Backup restored."
}

# Show help
show_help() {
  cat << EOF
Smart Color Analysis Switch Script

Usage: $0 [command]

Commands:
  --status, -s              Show current feature status
  --enable-all              Enable all features
  --disable-all             Disable all features and restore originals
  --enable-cielab            Enable CIELAB color space
  --disable-cielab           Disable CIELAB color space
  --enable-kmeans            Enable K-means clustering
  --disable-kmeans           Disable K-means clustering
  --enable-hybrid            Enable hybrid accent extraction
  --disable-hybrid           Disable hybrid accent extraction
  --enable-semantic          Enable semantic classification
  --disable-semantic         Disable semantic classification
  --enable-temporal          Enable temporal smoothing
  --disable-temporal         Disable temporal smoothing
  --enable-context           Enable context awareness
  --disable-context          Disable context awareness
  --enable-fallback          Enable fallback prompt
  --disable-fallback         Disable fallback prompt
  --restore-backup           Restore files from backup only
  --help, -h                 Show this help

Examples:
  $0 --status
  $0 --enable-all
  $0 --enable-cielab --enable-kmeans
  $0 --disable-all
EOF
}

# Main command parsing
case "${1:-}" in
  --status|-s)
    get_status
    ;;
  --enable-all)
    enable_all
    ;;
  --disable-all)
    disable_all
    ;;
  --enable-cielab)
    set_feature "cielab" "true"
    ;;
  --disable-cielab)
    set_feature "cielab" "false"
    ;;
  --enable-kmeans)
    set_feature "kmeans" "true"
    ;;
  --disable-kmeans)
    set_feature "kmeans" "false"
    ;;
  --enable-hybrid)
    set_feature "hybrid_extraction" "true"
    ;;
  --disable-hybrid)
    set_feature "hybrid_extraction" "false"
    ;;
  --enable-semantic)
    set_feature "semantic_classification" "true"
    ;;
  --disable-semantic)
    set_feature "semantic_classification" "false"
    ;;
  --enable-temporal)
    set_feature "temporal_smoothing" "true"
    ;;
  --disable-temporal)
    set_feature "temporal_smoothing" "false"
    ;;
  --enable-context)
    set_feature "context_awareness" "true"
    ;;
  --disable-context)
    set_feature "context_awareness" "false"
    ;;
  --enable-fallback)
    set_feature "fallback_prompt" "true"
    ;;
  --disable-fallback)
    set_feature "fallback_prompt" "false"
    ;;
  --restore-backup)
    restore_backup
    ;;
  --help|-h|"")
    show_help
    ;;
  *)
    echo "Unknown command: $1"
    show_help
    exit 1
    ;;
esac
