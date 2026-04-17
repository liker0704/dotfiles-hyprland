#!/usr/bin/env python3
"""
Fix wallust-generated palette:
  1. Compute balanced derived tones via blend().
  2. Auto-select accent/accent_secondary by saturation.
  3. Validate ANSI 16 — replace colors that are the wrong hue, too close
     to bg, or duplicates, with engineered fallbacks harmonized to seed.
  4. Rewrite palette file with stable accent_seed + accent fields.

Usage: theme-palette-postprocess.py <palette-path>
"""
import colorsys
import os
import re
import sys


def hex_to_rgb(h: str) -> tuple[float, float, float]:
    return tuple(int(h[i:i+2], 16) / 255 for i in (0, 2, 4))


def rgb_to_hex(r: float, g: float, b: float) -> str:
    return ''.join(f'{int(max(0, min(1, v)) * 255):02x}' for v in (r, g, b))


def hex_to_hls(h: str) -> tuple[float, float, float]:
    r, g, b = hex_to_rgb(h)
    return colorsys.rgb_to_hls(r, g, b)


def hls_to_hex(h: float, l: float, s: float) -> str:
    h = h % 1.0
    r, g, b = colorsys.hls_to_rgb(h, l, s)
    return rgb_to_hex(r, g, b)


def blend(c1: str, c2: str, ratio: float) -> str:
    return ''.join(
        f'{int(int(c1[i:i+2], 16) * (1 - ratio) + int(c2[i:i+2], 16) * ratio):02x}'
        for i in (0, 2, 4)
    )


# Canonical ANSI hue targets. Engineered colors land at these positions
# (with small ±12° harmonization toward seed for cohesion).
# Tolerance = how far wallust pick can deviate from target hue before fix.
ANSI_TARGETS = {
    'red':     (  5, 35),
    'yellow':  ( 48, 22),
    'green':   (130, 45),
    'cyan':    (180, 25),
    'blue':    (215, 30),
    'magenta': (300, 35),
}


def hue_dist(h1_deg: float, h2_deg: float) -> float:
    d = abs(h1_deg - h2_deg) % 360
    return min(d, 360 - d)


def engineer_ansi(target_hue_deg: float, seed_hue_deg: float,
                  is_bright: bool, is_dark_bg: bool,
                  strict: bool = False) -> str:
    """Engineer an ANSI color at canonical hue, harmonized 12° toward seed.
    Lightness/saturation tuned so:
      - normal vs bright differ by ~0.10 L (visible distinction)
      - all stay clear of black (L<0.3) and white (L>0.78)
      - moderate saturation keeps hues distinct without neon glow.
    strict=True disables seed-drift — used when re-engineering to resolve a
    cross-slot hue collision (drift may pull the color back into the collision
    zone, e.g. blue seed 203° drifts target 215° back down to 203°)."""
    if strict:
        shifted = target_hue_deg
    else:
        dist = ((seed_hue_deg - target_hue_deg + 540) % 360) - 180
        shifted = (target_hue_deg + max(-12, min(12, dist))) % 360

    if is_dark_bg:
        # Normal: L=0.55  Bright: L=0.65 (gap 0.10, far from white at ~0.85)
        s = 0.55 if is_bright else 0.50
        l = 0.65 if is_bright else 0.55
    else:
        s = 0.60 if is_bright else 0.55
        l = 0.38 if is_bright else 0.45
    return hls_to_hex(shifted / 360, l, s)


def fix_ansi(palette: dict[str, str], seed_hex: str, is_dark_bg: bool) -> None:
    bg_hex = palette.get('bg', '000000')
    fg_hex = palette.get('fg', 'ffffff')
    bg_l = hex_to_hls(bg_hex)[1]
    fg_l = hex_to_hls(fg_hex)[1]
    seed_h = hex_to_hls(seed_hex)[0] * 360

    # Forbidden lightness band: too close to bg or to fg/white
    def lightness_ok(l: float) -> bool:
        return abs(l - bg_l) > 0.22 and abs(l - fg_l) > 0.15

    finalized: set[str] = set()
    finalized_hues: list[float] = []  # degrees, for cross-slot hue-distance check

    # Minimum hue distance from any previously-finalized slot. If a wallust pick
    # is within this degree window of another slot, we re-engineer at canonical.
    # Prevents blue ≈ cyan or green ≈ cyan collisions (Fix 5).
    MIN_CROSS_HUE_DEG = 25

    for name, (target_h, tol) in ANSI_TARGETS.items():
        # Process the PAIR (normal, bright) together so we can enforce
        # bright > normal lightness gap (Fix 2).
        normal_key = name
        bright_key = f'bright_{name}'

        # Validate normal first
        for is_bright, key in [(False, normal_key), (True, bright_key)]:
            current = palette.get(key)
            needs_fix = True
            if current:
                ch, cl, cs = hex_to_hls(current)
                cur_h_deg = ch * 360
                hue_ok = hue_dist(cur_h_deg, target_h) <= tol
                light_ok = lightness_ok(cl)
                sat_ok = cs > 0.20
                unique_ok = current.lower() not in finalized
                # Fix 5: cross-slot hue distance — prevents blue ≈ cyan etc.
                # Only applied to "normal" slots; bright pair is allowed to
                # share a hue with its normal sibling.
                if not is_bright:
                    cross_ok = all(hue_dist(cur_h_deg, h) >= MIN_CROSS_HUE_DEG
                                   for h in finalized_hues)
                else:
                    cross_ok = True
                if hue_ok and light_ok and sat_ok and unique_ok and cross_ok:
                    needs_fix = False
            if needs_fix:
                # Use strict=True (no seed drift) when the reason we're fixing
                # is a cross-hue collision — otherwise drift can re-collide.
                needs_strict = current is not None and not cross_ok and not is_bright
                palette[key] = engineer_ansi(target_h, seed_h, is_bright,
                                             is_dark_bg, strict=needs_strict)
            finalized.add(palette[key].lower())
            if not is_bright:
                finalized_hues.append(hex_to_hls(palette[key])[0] * 360)

        # Fix 2: enforce bright is visibly brighter than normal (>0.06 L).
        # If wallust gave both as same/dark, replace bright with engineered version.
        n_l = hex_to_hls(palette[normal_key])[1]
        b_l = hex_to_hls(palette[bright_key])[1]
        if b_l - n_l < 0.06:
            palette[bright_key] = engineer_ansi(target_h, seed_h, True, is_dark_bg)
            # Re-engineer with explicit boost above normal_key's lightness
            ch_b = hex_to_hls(palette[bright_key])[0]
            new_l = min(0.78, n_l + 0.12)
            palette[bright_key] = hls_to_hex(ch_b, new_l, 0.58)
            finalized.discard(palette[bright_key].lower())  # don't block re-use
            finalized.add(palette[bright_key].lower())

    # Fix 4: grey-pair distinction (black/bright_black, white/bright_white).
    # ANSI_TARGETS only covers the 6 hues; wallust can leave white == bright_white
    # (or black == bright_black), making bold-white indistinguishable.
    # Anchor on dark_l/light_l (= min/max of bg_l, fg_l) so slots are semantic
    # regardless of theme mode: black always sits near the dark end, white near
    # the light end.
    dark_l = min(bg_l, fg_l)
    light_l = max(bg_l, fg_l)
    hue_frac = (seed_h / 360) if seed_h > 0 else 0
    for normal_key, bright_key, n_mix, b_mix in [
        ('black', 'bright_black', 0.20, 0.45),  # 20%/45% from dark anchor
        ('white', 'bright_white', 0.85, 1.00),  # 85%/100% toward light anchor
    ]:
        n_l = hex_to_hls(palette[normal_key])[1] if normal_key in palette else -1
        b_l = hex_to_hls(palette[bright_key])[1] if bright_key in palette else -1
        if abs(b_l - n_l) < 0.06 or n_l < 0 or b_l < 0:
            target_n_l = dark_l + (light_l - dark_l) * n_mix
            target_b_l = dark_l + (light_l - dark_l) * b_mix
            palette[normal_key] = hls_to_hex(hue_frac, target_n_l, 0.05)
            palette[bright_key] = hls_to_hex(hue_frac, target_b_l, 0.05)


def main(path: str) -> None:
    palette: dict[str, str] = {}
    with open(path) as fh:
        for line in fh:
            m = re.match(r'^(\w+)=([0-9A-Fa-f]{6})\s*$', line.strip())
            if m:
                palette[m.group(1)] = m.group(2).lower()

    bg = palette.get('bg', '000000')
    fg = palette.get('foreground', palette.get('fg', 'ffffff'))

    # Derived tones
    palette['bg_light'] = blend(bg, fg, 0.07)
    palette['bg_highlight'] = blend(bg, fg, 0.19)
    palette['fg_dim'] = blend(fg, bg, 0.33)
    palette['fg_muted'] = blend(fg, bg, 0.55)
    palette['border'] = blend(bg, fg, 0.28)

    # Auto-accent: highest saturation × contrast-with-bg from ANSI candidates
    bg_l = hex_to_hls(bg)[1]
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
        _, l, s = hex_to_hls(h)
        gap = abs(l - bg_l)
        if gap < 0.1:
            continue
        scored.append((s * 2 + gap * 0.5, h))
    scored.sort(reverse=True, key=lambda t: t[0])

    if scored:
        palette['accent'] = scored[0][1]
        palette['accent_secondary'] = scored[1][1] if len(scored) > 1 else scored[0][1]

    # Fix 3: minimum-saturation guard. If best accent is washed out (<0.25),
    # ALL wallust ANSI candidates are desaturated (e.g. monochrome wallpaper).
    # Engineer accent at the same hue but with forced saturation.
    if 'accent' in palette:
        ah, al, as_ = hex_to_hls(palette['accent'])
        if as_ < 0.25:
            target_h = ah if as_ > 0.05 else hex_to_hls(bg)[0]
            new_l = max(0.55, al) if bg_l < 0.5 else min(0.45, al)
            palette['accent'] = hls_to_hex(target_h, new_l, 0.55)

    # Fix 1: contrast guard. Even after best pick + saturation boost, the
    # accent's lightness may sit too close to bg. Force a 0.55 L gap toward
    # the readable end (light for dark theme, dark for light).
    if 'accent' in palette:
        ah, al, as_ = hex_to_hls(palette['accent'])
        if abs(al - bg_l) < 0.30:
            new_l = min(0.78, bg_l + 0.55) if bg_l < 0.5 else max(0.25, bg_l - 0.55)
            palette['accent'] = hls_to_hex(ah, new_l, max(as_, 0.40))

    # Smart ANSI fallback — fix wrong-hue / near-bg / duplicate slots
    seed_hex = palette.get('accent', '7aa2f7')
    is_dark = bg_l < 0.5
    fix_ansi(palette, seed_hex, is_dark)

    font = palette.get('font', 'JetBrainsMono Nerd Font')

    with open(path, 'w') as f:
        f.write('# Terminal color palette — single source of truth\n')
        f.write('# Theme: Wallpaper (wallust + smart ANSI fallback)\n')
        f.write('# Edit this file, then run: theme sync\n\n')
        f.write('# Base colors\n')
        for k in ['bg', 'bg_light', 'bg_highlight', 'fg', 'fg_dim', 'fg_muted', 'border']:
            f.write(f'{k}={palette.get(k, "000000")}\n')
        f.write('\n# Terminal 16 colors (wallust picks, with smart fallback for broken slots)\n')
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
        seed_val = palette.get('accent', '7aa2f7')
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
