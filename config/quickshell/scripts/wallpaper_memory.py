#!/usr/bin/env python3
import os, sys, json, colorsys
from PIL import Image

MEMORY_FILE = os.path.expanduser('~/.config/quickshell/wallpaper_memory.json')

def load_memory():
    if os.path.isfile(MEMORY_FILE):
        try:
            with open(MEMORY_FILE) as f:
                return json.load(f)
        except Exception:
            pass
    return {}

def save_memory(data):
    os.makedirs(os.path.dirname(MEMORY_FILE), exist_ok=True)
    with open(MEMORY_FILE, 'w') as f:
        json.dump(data, f, indent=2)

def auto_recommend(wp_path):
    if not wp_path or not os.path.isfile(wp_path):
        return 'Tela-blue'
    try:
        from wallpaper_cache_builder import load_cache, analyze_image
        fn = os.path.basename(wp_path)
        cache = load_cache()
        if fn in cache:
            return cache[fn].get('recommendedIcon', 'Tela-blue')
        res = analyze_image(wp_path)
        if res:
            return res.get('recommendedIcon', 'Tela-blue')
        return 'Tela-blue'
    except Exception:
        return 'Tela-blue'

def get_wp_key(wp_path):
    if not wp_path: return ""
    return os.path.basename(wp_path)

def main():
    if len(sys.argv) < 2:
        print("{}")
        return

    cmd = sys.argv[1]
    mem = load_memory()

    if cmd == "get" and len(sys.argv) >= 3:
        wp_path = sys.argv[2]
        key = get_wp_key(wp_path)
        rec = auto_recommend(wp_path)
        if key and key not in mem:
            mem[key] = {
                "iconTheme": rec,
                "barTheme": ""
            }
            save_memory(mem)
        item = mem.get(key, {})
        result = {
            "key": key,
            "recommendedIcon": rec,
            "savedIcon": item.get("iconTheme", rec),
            "savedBar": item.get("barTheme", ""),
            "hasMemory": True
        }
        print(json.dumps(result))

    elif cmd == "set" and len(sys.argv) >= 4:
        wp_path = sys.argv[2]
        icon_theme = sys.argv[3]
        bar_theme = sys.argv[4] if len(sys.argv) >= 5 else ""
        key = get_wp_key(wp_path)
        if key:
            mem[key] = {
                "iconTheme": icon_theme,
                "barTheme": bar_theme
            }
            save_memory(mem)
            print(f"Memory saved for {key}: icon={icon_theme}, bar={bar_theme}")

    elif cmd == "rec" and len(sys.argv) >= 3:
        print(auto_recommend(sys.argv[2]))

if __name__ == "__main__":
    main()
