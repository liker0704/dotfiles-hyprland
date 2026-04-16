"""Shared color math for theme management."""
import colorsys


def from_hex(h):
    h = h.lstrip('#')
    if len(h) != 6:
        return (128, 128, 128)
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def to_hex_rgb(r, g, b):
    return f"{int(r):02x}{int(g):02x}{int(b):02x}"


def luminance(hex_color):
    r, g, b = from_hex(hex_color)
    return 0.299 * r + 0.587 * g + 0.114 * b


def rel_lum(r, g, b):
    def f(c):
        c = c / 255
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)


def contrast(c1, c2):
    l1 = rel_lum(*from_hex(c1))
    l2 = rel_lum(*from_hex(c2))
    hi, lo = max(l1, l2), min(l1, l2)
    return (hi + 0.05) / (lo + 0.05)


def is_dark(theme):
    bg = theme.get('background', '#808080').lstrip('#')
    return luminance(bg) < 128


def blend(c1, c2, ratio):
    r1, g1, b1 = from_hex(c1)
    r2, g2, b2 = from_hex(c2)
    return to_hex_rgb(
        r1 + (r2 - r1) * ratio,
        g1 + (g2 - g1) * ratio,
        b1 + (b2 - b1) * ratio,
    )


def quality_ok(theme):
    bg = theme.get('background', '').lstrip('#')
    fg = theme.get('foreground', '').lstrip('#')
    if len(bg) != 6 or len(fg) != 6:
        return False
    if contrast(bg, fg) < 4.5:
        return False
    hues = set()
    for i in range(2, 8):
        hc = theme.get(f'color_{i:02d}', '').lstrip('#')
        if len(hc) != 6:
            continue
        r, g, b = from_hex(hc)
        h, _l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
        if s > 0.10:
            hues.add(int(h * 6) % 6)
    return len(hues) >= 4
