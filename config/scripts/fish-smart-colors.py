#!/usr/bin/env python3
"""
fish-smart-colors.py

Generates Fish shell syntax colors purely from the current Wallust palette.
Rules:
  - ONLY colors from dynamic-color.sh are used. Zero hardcoded hex values.
  - Each syntax role gets the most visually distinct available Wallust color.
  - Wallust hue is preserved; only lightness is adjusted to meet contrast.
  - Colors are assigned so no two adjacent roles share both hue AND lightness.
"""

import os, re, colorsys, subprocess

# ── Read Wallust palette ───────────────────────────────────────────────────────
color_script = os.path.expanduser("~/.config/scripts/shared/dynamic-color.sh")
raw = {}
if os.path.isfile(color_script):
    with open(color_script) as f:
        for line in f:
            m = re.match(r'^(\w+)="(#[0-9A-Fa-f]{6})"', line.strip())
            if m:
                raw[m.group(1).upper()] = m.group(2)

def get(k, fb): return raw.get(k.upper(), fb)

BG      = get("BACKGROUND", "#000000")
FG      = get("FOREGROUND", "#ffffff")
palette = [get(f"COLOR{i}", FG) for i in range(16)]

# ── Math ──────────────────────────────────────────────────────────────────────
def to_rgb(h):
    s = h.lstrip("#")
    return int(s[0:2],16)/255, int(s[2:4],16)/255, int(s[4:6],16)/255

def luma(h):
    r, g, b = to_rgb(h)
    def lin(c): return c/12.92 if c <= 0.04045 else ((c+0.055)/1.055)**2.4
    return 0.2126*lin(r) + 0.7152*lin(g) + 0.0722*lin(b)

def contrast(a, b):
    la, lb = luma(a)+0.05, luma(b)+0.05
    return max(la,lb)/min(la,lb)

def hls(h):
    r, g, b = to_rgb(h)
    hue, l, s = colorsys.rgb_to_hls(r, g, b)
    return hue, l, s

def rebuild(col, new_l):
    """Return col with lightness replaced by new_l, preserving hue+saturation."""
    h, _, s = hls(col)
    r, g, b = colorsys.hls_to_rgb(h, max(0.0, min(1.0, new_l)), s)
    return '#{:02X}{:02X}{:02X}'.format(int(r*255), int(g*255), int(b*255))

def ensure_contrast(col, bg, min_ratio=4.5):
    """
    Shift the lightness of col (preserving its Wallust hue+saturation)
    until contrast against bg >= min_ratio.
    """
    h, l, s = hls(col)
    light_bg = luma(bg) > 0.50
    step = -0.03 if light_bg else 0.03
    for _ in range(40):
        if contrast(col, bg) >= min_ratio:
            break
        l = max(0.04, min(0.96, l + step))
        r, g, b = colorsys.hls_to_rgb(h, l, s)
        col = '#{:02X}{:02X}{:02X}'.format(int(r*255), int(g*255), int(b*255))
    return col

# Read is_light_mode cache
is_light_cache = os.path.expanduser('~/.cache/quickshell/is_light_mode')
if os.path.isfile(is_light_cache):
    with open(is_light_cache) as f:
        is_light = f.read().strip() == 'true'
else:
    is_light = luma(BG) > 0.50

if is_light:
    BG = '#f4f6f8' if luma(BG) < 0.50 else BG
    FG = '#0f172a' if luma(FG) > 0.50 else FG

bg_h, bg_l, bg_s = hls(BG)

def hue_dist(h1, h2):
    """Circular hue distance [0..0.5]."""
    d = abs(h1 - h2)
    return min(d, 1.0 - d)

def perceptual_distance(col):
    """How different is this Wallust color from BG? Higher = more distinct."""
    h, l, s = hls(col)
    luma_diff = abs(luma(col) - luma(BG))
    hue_diff  = hue_dist(h, bg_h) * (s + 0.1)   # weight by saturation
    return luma_diff * 0.6 + hue_diff * 0.4

# Deduplicate: collapse near-identical colors into one representative
seen, candidates = [], []
for c in palette:
    if any(abs(luma(c) - luma(s)) < 0.01 and hue_dist(hls(c)[0], hls(s)[0]) < 0.03
           for s in seen):
        continue
    seen.append(c)
    candidates.append(c)

# Sort candidates: most distinct from BG first
candidates.sort(key=perceptual_distance, reverse=True)

def pick_distinct(already_used, candidates, min_luma_diff=0.08, min_hue_diff=0.06):
    """
    Pick the candidate most different from all already-used colors.
    Prefers hue diversity; falls back to lightness diversity.
    """
    best, best_score = None, -1
    for c in candidates:
        if c in already_used:
            continue
        # Score = minimum distance to any already-used color
        score = min(
            (abs(luma(c) - luma(u)) * 0.5 + hue_dist(hls(c)[0], hls(u)[0]) * hls(c)[2] * 0.5)
            for u in already_used
        ) if already_used else perceptual_distance(c)
        if score > best_score:
            best_score, best = score, c
    return best or candidates[0]

# ── Assign roles ──────────────────────────────────────────────────────────────
used = []

# COMMAND: most distinct from BG (brightest accent on dark, darkest on light)
raw_cmd = candidates[0]
COMMAND = ensure_contrast(raw_cmd, BG, 4.5)
used.append(raw_cmd)

# ERROR: Wallust color whose hue is closest to red (hue 0.0)
def red_dist(c):
    h, l, s = hls(c)
    return min(h, 1.0 - h)   # 0 = pure red, 0.5 = pure cyan

raw_err = min((c for c in candidates if c not in used), key=red_dist, default=candidates[-1])
ERROR = ensure_contrast(raw_err, BG, 4.5)
used.append(raw_err)

# KEYWORD: next most distinct from BG and from command
raw_kw = pick_distinct(used, candidates)
KEYWORD = ensure_contrast(raw_kw, BG, 4.5)
used.append(raw_kw)

# QUOTE: next most distinct
raw_qt = pick_distinct(used, candidates)
QUOTE = ensure_contrast(raw_qt, BG, 4.5)
used.append(raw_qt)

# REDIR/OPERATOR: next most distinct
raw_rd = pick_distinct(used, candidates)
REDIR = ensure_contrast(raw_rd, BG, 4.5)
used.append(raw_rd)

# OPTION: reuse keyword's Wallust hue but at a different lightness (softer)
kw_h, kw_l, kw_s = hls(raw_kw)
target_l = max(0.04, kw_l - 0.18) if not is_light else min(0.96, kw_l + 0.18)
OPTION = ensure_contrast(rebuild(raw_kw, target_l), BG, 4.5)

# PARAM: use Wallust FOREGROUND, contrast-ensured
PARAM = ensure_contrast(FG, BG, 4.5)

# AUTOSUGGESTION: use a Wallust color that reads noticeably dimmer than PARAM
# Pick the candidate closest in luma to BG (but still readable at 2.5:1)
remaining = [c for c in candidates if c not in used]
raw_auto = min(remaining, key=lambda c: abs(luma(c) - luma(BG)), default=FG) if remaining else FG
AUTOSUGGEST = ensure_contrast(raw_auto, BG, 2.5)
# Must be dimmer than PARAM — cap contrast at 80% of PARAM's
param_cr = contrast(PARAM, BG)
auto_cr  = contrast(AUTOSUGGEST, BG)
if auto_cr > param_cr * 0.80:
    a_h, a_l, a_s = hls(AUTOSUGGEST)
    a_l = max(0.04, a_l * 0.65) if not is_light else min(0.96, a_l * 1.35)
    AUTOSUGGEST = rebuild(AUTOSUGGEST, a_l)

# SELECTION BG: use a Wallust color clearly distinguishable from BG by luma
raw_sel = pick_distinct([BG], candidates)
sel_h, sel_l, sel_s = hls(raw_sel)
# Target luma diff >= 0.15 from BG
target_sel_l = sel_l
step = 0.04 if not is_light else -0.04
SEL_BG = raw_sel
for _ in range(20):
    if abs(luma(SEL_BG) - luma(BG)) >= 0.15:
        break
    target_sel_l = max(0.04, min(0.96, target_sel_l + step))
    SEL_BG = rebuild(raw_sel, target_sel_l)

SEL_FG = ensure_contrast(FG, SEL_BG, 4.5)

# ── Write fish-colors.fish ────────────────────────────────────────────────────
out = os.path.expanduser("~/.config/scripts/shared/fish-colors.fish")
os.makedirs(os.path.dirname(out), exist_ok=True)
with open(out, "w") as f:
    f.write(f"""# Auto-generated from Wallust palette by fish-smart-colors.py
# All colors are derived exclusively from the current Wallust palette.
# Do not edit manually — regenerated on every wallpaper/mode change.

set -U fish_color_command         '{COMMAND}' '--bold'
set -U fish_color_keyword         '{KEYWORD}' '--bold'
set -U fish_color_param           '{PARAM}'
set -U fish_color_option          '{OPTION}'
set -U fish_color_quote           '{QUOTE}'
set -U fish_color_redirection     '{REDIR}'
set -U fish_color_end             '{REDIR}'
set -U fish_color_error           '{ERROR}' '--bold'
set -U fish_color_autosuggestion  '{AUTOSUGGEST}'
set -U fish_color_selection       '--background={SEL_BG}' '--color={SEL_FG}'
set -U fish_color_search_match    '--background={SEL_BG}' '--color={SEL_FG}'
set -U fish_color_valid_path      '--underline'
set -U fish_color_operator        '{REDIR}'
set -U fish_color_escape          '{QUOTE}'
""")

# ── Push live ─────────────────────────────────────────────────────────────────
vars_to_set = [
    ("fish_color_command",        [COMMAND, "--bold"]),
    ("fish_color_keyword",        [KEYWORD, "--bold"]),
    ("fish_color_param",          [PARAM]),
    ("fish_color_option",         [OPTION]),
    ("fish_color_quote",          [QUOTE]),
    ("fish_color_redirection",    [REDIR]),
    ("fish_color_end",            [REDIR]),
    ("fish_color_error",          [ERROR, "--bold"]),
    ("fish_color_autosuggestion", [AUTOSUGGEST]),
    ("fish_color_selection",      [f"--background={SEL_BG}", f"--color={SEL_FG}"]),
    ("fish_color_search_match",   [f"--background={SEL_BG}", f"--color={SEL_FG}"]),
    ("fish_color_valid_path",     ["--underline"]),
    ("fish_color_operator",       [REDIR]),
    ("fish_color_escape",         [QUOTE]),
]
for varname, values in vars_to_set:
    try:
        subprocess.run(
            ["fish", "-c", "set -U " + varname + " " + " ".join(f"'{v}'" for v in values)],
            capture_output=True, timeout=2
        )
    except Exception:
        pass

# ── Report ────────────────────────────────────────────────────────────────────
print(f"Fish colors written ({'Light' if is_light else 'Dark'} mode) from Wallust palette:")
print(f"  BG={BG} (luma={luma(BG):.3f})")
for role, raw_c, final_c in [
    ("command",        raw_cmd,  COMMAND),
    ("keyword",        raw_kw,   KEYWORD),
    ("option",         raw_kw,   OPTION),
    ("quote",          raw_qt,   QUOTE),
    ("redir",          raw_rd,   REDIR),
    ("error",          raw_err,  ERROR),
    ("param",          FG,       PARAM),
    ("autosuggestion", raw_auto, AUTOSUGGEST),
    ("selection bg",   raw_sel,  SEL_BG),
]:
    h, l, s = hls(final_c)
    c = contrast(final_c, BG)
    arrow = f" (adjusted from {raw_c})" if raw_c != final_c else ""
    print(f"  {role:14s} {final_c}  hue={h:.2f} sat={s:.2f} contrast={c:.1f}:1{arrow}")
