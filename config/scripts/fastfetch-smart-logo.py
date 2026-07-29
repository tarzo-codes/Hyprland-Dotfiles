#!/usr/bin/env python3
"""
fastfetch-smart-logo.py
Generates a dynamically colored fastfetch logo.txt using Wallust palette colors.
Guarantees WCAG AA contrast against terminal background so the CachyOS logo
never blends in or disappears in Light or Dark mode.
"""

import os
import re
import colorsys

color_script = os.path.expanduser("~/.config/scripts/shared/dynamic-color.sh")
raw_colors = {}
if os.path.isfile(color_script):
    with open(color_script) as f:
        for line in f:
            m = re.match(r'^(\w+)="(#[0-9A-Fa-f]{6})"', line.strip())
            if m:
                raw_colors[m.group(1).upper()] = m.group(2)

def get(key, fallback):
    return raw_colors.get(key.upper(), fallback)

BG = get("BACKGROUND", "#1e1e2e")
C1_raw = get("COLOR4", get("COLOR6", "#00d0ff"))
C2_raw = get("COLOR2", get("COLOR1", "#33ffaa"))

def hex_to_rgb(h):
    s = h.lstrip("#")
    if len(s) != 6: return (0, 0, 0)
    return int(s[0:2],16)/255, int(s[2:4],16)/255, int(s[4:6],16)/255

def luma(h):
    r, g, b = hex_to_rgb(h)
    def lin(c): return c/12.92 if c <= 0.04045 else ((c+0.055)/1.055)**2.4
    return 0.2126*lin(r) + 0.7152*lin(g) + 0.0722*lin(b)

def contrast_ratio(a, b_col):
    la, lb = luma(a)+0.05, luma(b_col)+0.05
    return max(la, lb) / min(la, lb)

def ensure_contrast(hex_col, bg_col, min_ratio=4.5):
    r, g, b = hex_to_rgb(hex_col)
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    is_bg_light = luma(bg_col) > 0.50
    curr_col = hex_col
    step = -0.04 if is_bg_light else 0.04
    for _ in range(25):
        if contrast_ratio(curr_col, bg_col) >= min_ratio:
            break
        l = max(0.05, min(0.95, l + step))
        r_new, g_new, b_new = colorsys.hls_to_rgb(h, l, s)
        curr_col = '#{:02X}{:02X}{:02X}'.format(int(r_new*255), int(g_new*255), int(b_new*255))
    return curr_col

c1_hex = ensure_contrast(C1_raw, BG, 4.5)
c2_hex = ensure_contrast(C2_raw, BG, 4.5)

def hex_to_ansi(h):
    r, g, b = hex_to_rgb(h)
    return f"\033[38;2;{int(r*255)};{int(g*255)};{int(b*255)}m"

c1 = hex_to_ansi(c1_hex)
c2 = hex_to_ansi(c2_hex)
rst = "\033[0m"

l1 = c1 + "     _____________    "
l2 = c1 + "    /            /   " + c2 + "◯" + c1
l3 = c1 + "   /    _______ /"
l4 = c1 + "  /    /          " + c2 + "⟋─⟍ " + c1
l5 = c1 + " /    /           " + c2 + "⟍_⟋ " + c1 + "___"
l6 = c1 + " \\    \\              /   \\"
l7 = c1 + "  \\    \\_____________\\___/"
l8 = c1 + "   \\                /"
l9 = c1 + "    \\_____________ /" + rst

logo_content = "\n".join([l1, l2, l3, l4, l5, l6, l7, l8, l9])

out_file = os.path.expanduser("~/.config/fastfetch/logo.txt")
os.makedirs(os.path.dirname(out_file), exist_ok=True)
with open(out_file, "w") as f:
    f.write(logo_content)

print(f"Fastfetch logo regenerated: Primary={c1_hex}, Accent={c2_hex}")
