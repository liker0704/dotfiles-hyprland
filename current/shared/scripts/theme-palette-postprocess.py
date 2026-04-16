#!/usr/bin/env python3
"""
Fix wallust-generated palette: compute balanced derived colors via blend(),
auto-select accent/accent_secondary by saturation, rewrite palette file.

Usage: theme-palette-postprocess.py <palette-path>
"""
import colorsys
import os
import re
import sys


def blend(c1: str, c2: str, ratio: float) -> str:
    return ''.join(
        f'{int(int(c1[i:i+2], 16) * (1 - ratio) + int(c2[i:i+2], 16) * ratio):02x}'
        for i in (0, 2, 4)
    )


def main(path: str) -> None:
    palette: dict[str, str] = {}
    with open(path) as fh:
        for line in fh:
            m = re.match(r'^(\w+)=([0-9A-Fa-f]{6})\s*$', line.strip())
            if m:
                palette[m.group(1)] = m.group(2)

    bg = palette.get('bg', '000000')
    fg = palette.get('foreground', palette.get('fg', 'ffffff'))

    palette['bg_light'] = blend(bg, fg, 0.07)
    palette['bg_highlight'] = blend(bg, fg, 0.19)
    palette['fg_dim'] = blend(fg, bg, 0.33)
    palette['fg_muted'] = blend(fg, bg, 0.55)
    palette['border'] = blend(bg, fg, 0.28)

    bg_l = colorsys.rgb_to_hls(*[int(bg[i:i+2], 16) / 255 for i in (0, 2, 4)])[1]
    candidates = [
        (k, palette[k])
        for k in [
            'red', 'green', 'yellow', 'blue', 'magenta', 'cyan',
            'bright_red', 'bright_green', 'bright_yellow',
            'bright_blue', 'bright_magenta', 'bright_cyan',
        ]
        if k in palette
    ]
    scored = []
    for _name, h in candidates:
        r, g, b = [int(h[i:i+2], 16) / 255 for i in (0, 2, 4)]
        _, l, s = colorsys.rgb_to_hls(r, g, b)
        gap = abs(l - bg_l)
        if gap < 0.1:
            continue
        scored.append((s * 2 + gap * 0.5, h))
    scored.sort(reverse=True, key=lambda t: t[0])

    if scored:
        palette['accent'] = scored[0][1]
        palette['accent_secondary'] = scored[1][1] if len(scored) > 1 else scored[0][1]

    font = palette.get('font', 'JetBrainsMono Nerd Font')

    with open(path, 'w') as f:
        f.write('# Terminal color palette — single source of truth\n')
        f.write('# Theme: Wallpaper (wallust)\n')
        f.write('# Edit this file, then run: theme sync\n\n')
        f.write('# Base colors\n')
        for k in ['bg', 'bg_light', 'bg_highlight', 'fg', 'fg_dim', 'fg_muted', 'border']:
            f.write(f'{k}={palette.get(k, "000000")}\n')
        f.write('\n# Terminal 16 colors\n')
        for pair in [
            ('black', 'bright_black'), ('red', 'bright_red'),
            ('green', 'bright_green'), ('yellow', 'bright_yellow'),
            ('blue', 'bright_blue'), ('magenta', 'bright_magenta'),
            ('cyan', 'bright_cyan'), ('white', 'bright_white'),
        ]:
            for k in pair:
                f.write(f'{k}={palette.get(k, "000000")}\n')
        # accent_seed = wallust raw pick (saturation-weighted dominant ANSI).
        #   Used as matugen MD3 seed. Stable across theme syncs.
        # accent = matugen MD3 primary derived from seed (or = seed if matugen
        #   hasn't run yet). Final value consumed by all theme targets.
        seed_val = palette.get("accent", "7aa2f7")
        f.write(f'\n# Accent\naccent_seed={seed_val}\n')
        f.write(f'accent={seed_val}\n')
        f.write(f'accent_secondary={palette.get("accent_secondary", "bb9af7")}\n')
        f.write(f'cursor={palette.get("cursor", fg)}\n')
        f.write(f'url={palette.get("url", palette.get("blue", "7aa2f7"))}\n')
        f.write(f'\n# Font\nfont={font}\n')


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print('usage: theme-palette-postprocess.py <palette-path>', file=sys.stderr)
        sys.exit(2)
    main(os.path.expanduser(sys.argv[1]))
