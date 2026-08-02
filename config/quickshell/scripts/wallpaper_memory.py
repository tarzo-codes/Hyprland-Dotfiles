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
        im = Image.open(wp_path).convert('RGB')
        im_small = im.resize((150, 150))
        colors = im_small.getcolors(30000)
        if not colors:
            return 'Tela-blue'

        hue_scores = {
            'Tela-red': 0.0, 'Tela-pink': 0.0, 'Tela-ubuntu': 0.0,
            'Tela-orange': 0.0, 'Tela-yellow': 0.0, 'Tela-green': 0.0,
            'Tela-manjaro': 0.0, 'Tela-nord': 0.0, 'Tela-blue': 0.0,
            'Tela-dracula': 0.0, 'Tela-purple': 0.0, 'Tela-brown': 0.0,
            'Tela-grey': 0.0, 'Tela-black': 0.0
        }
        for count, (r, g, b) in colors:
            h, s, v = colorsys.rgb_to_hsv(r/255.0, g/255.0, b/255.0)
            luma = 0.299*(r/255.0) + 0.587*(g/255.0) + 0.114*(b/255.0)
            deg = h * 360.0

            if s < 0.22:
                weight = count * (1.0 - s) * 2.0
                if luma < 0.22:
                    hue_scores['Tela-black'] += weight
                else:
                    hue_scores['Tela-grey'] += weight
            elif s >= 0.22 and 0.06 <= luma <= 0.94:
                weight = count * (s ** 2.2)
                if deg >= 345 or deg < 12:
                    if s > 0.35 and luma < 0.60: hue_scores['Tela-red'] += weight * 1.5
                    else: hue_scores['Tela-pink'] += weight * 1.5
                elif 12 <= deg < 28:
                    hue_scores['Tela-ubuntu'] += weight * 1.5
                    hue_scores['Tela-orange'] += weight
                elif 28 <= deg < 48:
                    hue_scores['Tela-orange'] += weight * 1.5
                    hue_scores['Tela-ubuntu'] += weight * 0.8
                elif 48 <= deg < 70: hue_scores['Tela-yellow'] += weight * 1.5
                elif 70 <= deg < 140: hue_scores['Tela-green'] += weight * 1.5
                elif 140 <= deg < 175: hue_scores['Tela-manjaro'] += weight * 1.5
                elif 175 <= deg < 205:
                    hue_scores['Tela-nord'] += weight * 1.4
                    hue_scores['Tela-blue'] += weight * 0.8
                elif 205 <= deg < 255: hue_scores['Tela-blue'] += weight * 1.4
                elif 255 <= deg < 285: hue_scores['Tela-dracula'] += weight * 1.5
                elif 285 <= deg < 345: hue_scores['Tela-purple'] += weight * 1.5

        return max(hue_scores.items(), key=lambda x: x[1])[0]
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
        item = mem.get(key, {})
        result = {
            "key": key,
            "recommendedIcon": rec,
            "savedIcon": item.get("iconTheme", ""),
            "savedBar": item.get("barTheme", ""),
            "hasMemory": key in mem
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
