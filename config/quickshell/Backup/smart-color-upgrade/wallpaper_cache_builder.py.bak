#!/usr/bin/env python3
import os, sys, json, colorsys, subprocess
from PIL import Image

CACHE_FILE = os.path.expanduser('~/.cache/quickshell/wallpaper_spectrum_cache.json')
SETTING_FILE = os.path.expanduser('~/.cache/quickshell/wallpaper_caching_enabled')

def is_cache_enabled():
    if os.path.isfile(SETTING_FILE):
        try:
            with open(SETTING_FILE) as f:
                return f.read().strip() != 'false'
        except Exception:
            pass
    return True

def load_cache():
    if not is_cache_enabled():
        return {}
    if os.path.isfile(CACHE_FILE):
        try:
            with open(CACHE_FILE) as f:
                return json.load(f)
        except Exception:
            pass
    return {}

def save_cache(data):
    if not is_cache_enabled():
        return
    os.makedirs(os.path.dirname(CACHE_FILE), exist_ok=True)
    with open(CACHE_FILE, 'w') as f:
        json.dump(data, f, indent=2)

def hex_to_tela(hex_str):
    hex_str = hex_str.lstrip('#')
    if len(hex_str) != 6:
        return 'Tela-blue'
    try:
        r = int(hex_str[0:2], 16) / 255.0
        g = int(hex_str[2:4], 16) / 255.0
        b = int(hex_str[4:6], 16) / 255.0
        h, s, v = colorsys.rgb_to_hsv(r, g, b)
        luma = 0.299 * r + 0.587 * g + 0.114 * b
        deg = h * 360.0

        if s < 0.22:
            return 'Tela-black' if luma < 0.22 else 'Tela-grey'
        if deg >= 345 or deg < 12:
            return 'Tela-red' if s > 0.35 and luma < 0.60 else 'Tela-pink'
        elif 12 <= deg < 28:
            return 'Tela-ubuntu'
        elif 28 <= deg < 48:
            return 'Tela-orange'
        elif 48 <= deg < 70:
            return 'Tela-yellow'
        elif 70 <= deg < 140:
            return 'Tela-green'
        elif 140 <= deg < 175:
            return 'Tela-manjaro'
        elif 175 <= deg < 205:
            return 'Tela-nord'
        elif 205 <= deg < 255:
            return 'Tela-blue'
        elif 255 <= deg < 285:
            return 'Tela-dracula'
        elif 285 <= deg < 345:
            return 'Tela-purple'
        return 'Tela-blue'
    except Exception:
        return 'Tela-blue'

def analyze_image(wp_path):
    if not wp_path or not os.path.isfile(wp_path):
        return None
    try:
        im = Image.open(wp_path).convert('RGB')
        im_small = im.resize((150, 150))
        colors = im_small.getcolors(30000)
        if not colors:
            return None

        total_px = sum(c for c, _ in colors)
        avg_r = sum(c * r for c, (r, g, b) in colors) / total_px
        avg_g = sum(c * g for c, (r, g, b) in colors) / total_px
        avg_b = sum(c * b for c, (r, g, b) in colors) / total_px
        avg_luma = 0.299 * (avg_r / 255.0) + 0.587 * (avg_g / 255.0) + 0.114 * (avg_b / 255.0)

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

        top_rec = max(hue_scores.items(), key=lambda x: x[1])[0]
        return {
            'recommendedIcon': top_rec,
            'isLight': avg_luma > 0.50,
            'dominantRgb': [int(avg_r), int(avg_g), int(avg_b)]
        }
    except Exception:
        return None

def main():
    if len(sys.argv) < 2:
        print("{}")
        return

    cmd = sys.argv[1]

    if cmd == "clear":
        if os.path.isfile(CACHE_FILE):
            os.remove(CACHE_FILE)
        print("Wallpaper spectrum cache cleared.")

    elif cmd == "scan" and len(sys.argv) >= 3:
        folder = sys.argv[2]
        if not os.path.isdir(folder):
            print("Folder not found.")
            return
        cache = load_cache()
        scanned_count = 0
        valid_exts = ('.jpg', '.jpeg', '.png', '.webp', '.pnm', '.bmp')
        for root, _, files in os.walk(folder):
            for file in files:
                if file.lower().endswith(valid_exts):
                    wp_path = os.path.join(root, file)
                    fn = os.path.basename(wp_path)
                    if fn not in cache:
                        res = analyze_image(wp_path)
                        if res:
                            cache[fn] = res
                            scanned_count += 1
        save_cache(cache)
        print(f"Scanned {scanned_count} new wallpapers in {folder}.")

    elif cmd == "get_swatches" and len(sys.argv) >= 3:
        wp_path = sys.argv[2]
        if not os.path.isfile(wp_path):
            print("[]")
            return
        colors = []
        try:
            subprocess.run(["wallust", "run", "-T", "-s", wp_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=2)
            qml_file = os.path.expanduser("~/.config/quickshell/wallust-colors.qml")
            if os.path.isfile(qml_file):
                with open(qml_file) as f:
                    for line in f:
                        line = line.strip()
                        if line.startswith("readonly property string color"):
                            parts = line.split(":")
                            if len(parts) >= 2:
                                col = parts[1].replace('"', '').replace(';', '').strip()
                                colors.append(col)
        except Exception:
            pass

        if len(colors) < 16:
            try:
                im = Image.open(wp_path).convert('RGB')
                im_quant = im.quantize(colors=16)
                palette = im_quant.getpalette()
                colors = []
                for i in range(16):
                    r, g, b = palette[i*3], palette[i*3+1], palette[i*3+2]
                    colors.append(f"#{r:02x}{g:02x}{b:02x}")
            except Exception:
                pass

        result = []
        for i, c in enumerate(colors[:16]):
            result.append({
                "index": i,
                "hex": c,
                "isDefaultAccent": (i == 4),
                "telaTheme": hex_to_tela(c)
            })
        print(json.dumps(result))

    elif cmd == "get" and len(sys.argv) >= 3:
        wp_path = sys.argv[2]
        fn = os.path.basename(wp_path)
        cache = load_cache()
        if fn in cache:
            print(json.dumps(cache[fn]))
        else:
            res = analyze_image(wp_path)
            if res:
                if is_cache_enabled():
                    cache[fn] = res
                    save_cache(cache)
                print(json.dumps(res))
            else:
                print(json.dumps({"recommendedIcon": "Tela-blue", "isLight": False}))

if __name__ == "__main__":
    main()
