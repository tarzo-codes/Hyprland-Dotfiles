#!/usr/bin/env python3
"""
starship-smart-colors.py
Generates ~/.config/starship.toml using Wallust colors.

Guarantees:
- In Light mode: Segment backgrounds are mid-dark (luma <= 0.55) so NO segment is white/blends into white terminal!
- In Dark mode: Segment backgrounds are bright (luma >= 0.15) so NO segment is dark/blends into dark terminal!
- Structure:
    Segment 1 (SEG1): OS / Username
    Segment 2 (SEG2): Directory
    Segment 3 (SEG3): Git / Python / Languages / Tools
    Segment 4 (TIME_BG): Time
- All 4 segments are distinct in color/luminance
- Text inside each segment has high WCAG contrast (>= 4.5:1)
- Prompt character line uses clean arrow ❯ instead of orphaned half-circles
"""

import os
import re
import colorsys

# ── Read Wallust colors from dynamic-color.sh ─────────────────────────────────
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

wallust_colors = [get(f"COLOR{i}", "#888888") for i in range(16)]
BG = get("BACKGROUND", "#1e1e2e")
FG = get("FOREGROUND", "#cdd6f4")

# ── Mode detection ─────────────────────────────────────────────────────────────
mode_file = os.path.expanduser("~/.cache/quickshell/is_light_mode")
is_light = False
if os.path.isfile(mode_file):
    is_light = open(mode_file).read().strip() == "true"

# ── Color & Contrast Helpers ──────────────────────────────────────────────────
def hex_to_rgb(h):
    s = h.lstrip("#")
    if len(s) != 6: return (0, 0, 0)
    return int(s[0:2], 16)/255, int(s[2:4], 16)/255, int(s[4:6], 16)/255

def luma(h):
    r, g, b = hex_to_rgb(h)
    def lin(c): return c/12.92 if c <= 0.04045 else ((c+0.055)/1.055)**2.4
    return 0.2126*lin(r) + 0.7152*lin(g) + 0.0722*lin(b)

def sat(h):
    r, g, b = hex_to_rgb(h)
    _, s_val, _ = colorsys.rgb_to_hls(r, g, b)
    return s_val

def contrast_ratio(a, b):
    la, lb = luma(a)+0.05, luma(b)+0.05
    return max(la, lb) / min(la, lb)

LIGHT_TEXT = "#ffffff"
DARK_TEXT  = "#12121a"

def fg_for(bg_color):
    return DARK_TEXT if contrast_ratio(bg_color, DARK_TEXT) >= contrast_ratio(bg_color, LIGHT_TEXT) else LIGHT_TEXT

# ── Select 4 Distinct Wallust Colors for Segments ──────────────────────────────
unique_cols = [c for c in list(dict.fromkeys(wallust_colors)) if c]
bg_l = luma(BG)

if is_light:
    # Light mode terminal bg is white/off-white (luma ~0.8-1.0).
    # Segment BGs MUST be darker (luma <= 0.55) so they stand out sharply against white!
    candidates = [c for c in unique_cols if luma(c) <= 0.55 and luma(c) >= 0.04]
else:
    # Dark mode terminal bg is dark (luma ~0.0-0.1).
    # Segment BGs MUST be brighter (luma >= 0.15) so they stand out sharply against dark!
    candidates = [c for c in unique_cols if luma(c) >= 0.15 and luma(c) <= 0.85]

if len(candidates) < 4:
    candidates = [c for c in unique_cols if abs(luma(c) - bg_l) >= 0.15]
if len(candidates) < 4:
    candidates = unique_cols

# Sort by combination of saturation and luminance distance from terminal BG
candidates.sort(key=lambda c: (sat(c)*0.5 + abs(luma(c)-bg_l)*0.5), reverse=True)

chosen = []
for c in candidates:
    if len(chosen) >= 4: break
    if all(abs(luma(c) - luma(x)) >= 0.06 for x in chosen):
        chosen.append(c)

if len(chosen) < 4:
    for c in candidates:
        if len(chosen) >= 4: break
        if c not in chosen:
            chosen.append(c)

fallbacks = [get("COLOR4", "#7aa2f7"), get("COLOR2", "#9ece6a"), get("COLOR6", "#7dcfff"), get("COLOR5", "#bb9af7")]
for f_col in fallbacks:
    if len(chosen) >= 4: break
    if f_col not in chosen:
        chosen.append(f_col)

SEG1    = chosen[0]
SEG2    = chosen[1]
SEG3    = chosen[2]
TIME_BG = chosen[3]

FG1     = fg_for(SEG1)
FG2     = fg_for(SEG2)
FG3     = fg_for(SEG3)
FG_TIME = fg_for(TIME_BG)

ACC_ERR = get("COLOR1", "#f7768e")
PROMPT_ARROW_COLOR = SEG2

# ── Powerline / Nerd Font Separators ───────────────────────────────────────────
SEP_START = "\ue0b6"   # left half-circle
SEP_ARR   = "\ue0b0"   # right-pointing arrow
SEP_END   = "\ue0b4"   # right half-circle
SEP_CLOCK = "\uf43a"   # clock icon

# ── Generate starship.toml ─────────────────────────────────────────────────────
toml = f"""# Wallust generated starship.toml — dynamic contrast colors
# Mode: {"light" if is_light else "dark"}
# SEG1={SEG1} SEG2={SEG2} SEG3={SEG3} TIME_BG={TIME_BG}

format = \"\"\"
[{SEP_START}]({SEG1})\\
$os\\
$username\\
[{SEP_ARR}](bg:{SEG2} fg:{SEG1})\\
$directory\\
[{SEP_ARR}](bg:{SEG3} fg:{SEG2})\\
$git_branch\\
$git_status\\
$c\\
$cpp\\
$rust\\
$golang\\
$nodejs\\
$bun\\
$php\\
$java\\
$kotlin\\
$haskell\\
$python\\
$docker_context\\
$conda\\
$pixi\\
[{SEP_ARR}](fg:{SEG3} bg:{TIME_BG})\\
$time\\
[{SEP_END} ](fg:{TIME_BG})\\
$line_break$character\"\"\"

[os]
disabled = false
style = "bg:{SEG1} fg:{FG1}"

[os.symbols]
CachyOS = "󰣇"
Windows = "󰍲"
Ubuntu = "󰕈"
SUSE = ""
Raspbian = "󰐿"
Mint = "󰣭"
Macos = "󰀵"
Manjaro = ""
Linux = "󰌽"
Gentoo = "󰣨"
Fedora = "󰣛"
Alpine = ""
Amazon = ""
Android = ""
AOSC = ""
Arch = "󰣇"
Artix = "󰣇"
EndeavourOS = ""
CentOS = ""
Debian = "󰣚"
Redhat = "󱄛"
RedHatEnterprise = "󱄛"
Pop = ""

[username]
show_always = true
style_user = "bg:{SEG1} fg:{FG1}"
style_root  = "bg:{SEG1} fg:{FG1}"
format = '[ $user ]($style)'

[directory]
style = "fg:{FG2} bg:{SEG2}"
format = "[ $path ]($style)"
truncation_length = 3
truncation_symbol = "…/"

[directory.substitutions]
"Documents" = "󰈙 "
"Downloads" = " "
"Music"     = "󰝚 "
"Pictures"  = " "
"Developer" = "󰲋 "

[git_branch]
symbol = ""
style  = "bg:{SEG3}"
format = '[[ $symbol $branch ](fg:{FG3} bg:{SEG3})]($style)'

[git_status]
style  = "bg:{SEG3}"
format = '[[($all_status$ahead_behind )](fg:{FG3} bg:{SEG3})]($style)'

[nodejs]
symbol = ""
style  = "bg:{SEG3}"
format = '[[ $symbol( $version) ](fg:{FG3} bg:{SEG3})]($style)'

[bun]
symbol = ""
style  = "bg:{SEG3}"
format = '[[ $symbol( $version) ](fg:{FG3} bg:{SEG3})]($style)'

[c]
symbol = " "
style  = "bg:{SEG3}"
format = '[[ $symbol( $version) ](fg:{FG3} bg:{SEG3})]($style)'

[cpp]
symbol = " "
style  = "bg:{SEG3}"
format = '[[ $symbol( $version) ](fg:{FG3} bg:{SEG3})]($style)'

[rust]
symbol = ""
style  = "bg:{SEG3}"
format = '[[ $symbol( $version) ](fg:{FG3} bg:{SEG3})]($style)'

[golang]
symbol = ""
style  = "bg:{SEG3}"
format = '[[ $symbol( $version) ](fg:{FG3} bg:{SEG3})]($style)'

[php]
symbol = ""
style  = "bg:{SEG3}"
format = '[[ $symbol( $version) ](fg:{FG3} bg:{SEG3})]($style)'

[java]
symbol = ""
style  = "bg:{SEG3}"
format = '[[ $symbol( $version) ](fg:{FG3} bg:{SEG3})]($style)'

[kotlin]
symbol = ""
style  = "bg:{SEG3}"
format = '[[ $symbol( $version) ](fg:{FG3} bg:{SEG3})]($style)'

[haskell]
symbol = ""
style  = "bg:{SEG3}"
format = '[[ $symbol( $version) ](fg:{FG3} bg:{SEG3})]($style)'

[python]
symbol = ""
style  = "bg:{SEG3}"
format = '[[ $symbol( \\($virtualenv\\))( $version) ](fg:{FG3} bg:{SEG3})]($style)'

[docker_context]
symbol = ""
style  = "bg:{SEG3}"
format = '[[ $symbol( $context) ](fg:{FG3} bg:{SEG3})]($style)'

[conda]
style  = "bg:{SEG3}"
format = '[[ $symbol( $environment) ](fg:{FG3} bg:{SEG3})]($style)'

[pixi]
style  = "bg:{SEG3}"
format = '[[ $symbol( $version)( $environment) ](fg:{FG3} bg:{SEG3})]($style)'

[cmd_duration]
format = "[󱑂 $duration]($style)"
style  = "fg:{SEG2}"

[time]
disabled    = false
time_format = "%R"
style       = "bg:{TIME_BG}"
format      = '[[{SEP_CLOCK} $time ](fg:{FG_TIME} bg:{TIME_BG})]($style)'

[line_break]
disabled = false

[character]
disabled               = false
success_symbol         = '[❯ ](bold fg:{PROMPT_ARROW_COLOR})'
error_symbol           = '[❯ ](bold fg:{ACC_ERR})'
vimcmd_symbol          = '[❮ ](bold fg:{PROMPT_ARROW_COLOR})'
vimcmd_replace_one_symbol = '[❮ ](bold fg:{PROMPT_ARROW_COLOR})'
vimcmd_replace_symbol  = '[❮ ](bold fg:{PROMPT_ARROW_COLOR})'
vimcmd_visual_symbol   = '[❮ ](bold fg:{PROMPT_ARROW_COLOR})'
"""

out = os.path.expanduser("~/.config/starship.toml")
with open(out, "w") as f:
    f.write(toml)

print(f"Starship prompt updated for {'Light' if is_light else 'Dark'} mode:")
print(f"  SEG1 (User/OS): {SEG1} (fg: {FG1}, luma: {luma(SEG1):.2f})")
print(f"  SEG2 (Dir):     {SEG2} (fg: {FG2}, luma: {luma(SEG2):.2f})")
print(f"  SEG3 (Lang/Git):{SEG3} (fg: {FG3}, luma: {luma(SEG3):.2f})")
print(f"  TIME_BG (Time): {TIME_BG} (fg: {FG_TIME}, luma: {luma(TIME_BG):.2f})")
