#!/usr/bin/env python3
"""
Generate clean cartoon thumbnail PNGs for sonar2afc vessel displays.

Each thumbnail is a self-contained cartoon: black bg, outer border,
3 frequency rows, colored bands (no noise, no grid lines, no text).
Output size matches the on-screen display size at 1:1 so no stretching needed.

Output: thumbnails/thumb_v1.png and thumbnails/thumb_v2.png
"""

import os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUT_DIR    = os.path.join(SCRIPT_DIR, 'thumbnails')

# Vessel signatures from sonar2afc.pbl
#SIG1 = [50, 125, 340, 1200, 1541]   # Kilo-877 Mark 1
#SIG2 = [50, 125, 320, 1075, 1490]   # Kilo-877 Mark 2
#SIG2 = [50, 125, 320, 1075, 1490]   # Fishing boat

SIG1 = [50, 125, 340, 1200, 1541]   ## Sub Mark 1
SIG2 = [40, 135, 320, 1100, 1490]   ## Sub Mark 2
SIG3 = [75, 200, 500, 1000, 1700]   ## schooner

# Output pixel size — match gVideoWidth*0.125 at 1920px = 240px wide
THUMB_W = 240
THUMB_H = 120

# Layout inside the thumbnail
BORDER    = 2    # outer border thickness (px)
ROW_GAP   = 2    # gap between rows
PAD_LEFT  = 4    # content padding inside border
PAD_RIGHT = 4

# Frequency ranges per row (same as the real display)
ROWS = [
    {'flo': 0,    'fhi': 250},
    {'flo': 250,  'fhi': 750},
    {'flo': 750,  'fhi': 1750},
]

# Band appearance
BAND_SIGMA  = 3.0   # Gaussian half-width in pixels
BAND_PEAK   = 220   # peak green intensity (0-255)
BAND_COLOR  = (0, 1.0, 0.3)  # R/G/B multipliers for the band color


def draw_thumbnail(sig, out_path):
    img = np.zeros((THUMB_H, THUMB_W, 3), dtype=np.float32)

    # Outer border (green, dim)
    border_color = np.array([0, 60, 0], dtype=np.float32)
    img[:BORDER, :] = border_color
    img[-BORDER:, :] = border_color
    img[:, :BORDER] = border_color
    img[:, -BORDER:] = border_color

    # Compute row rects (y range inside border)
    inner_top = BORDER
    inner_bot = THUMB_H - BORDER
    inner_h   = inner_bot - inner_top
    n_rows    = len(ROWS)
    total_gap = ROW_GAP * (n_rows - 1)
    row_h     = (inner_h - total_gap) // n_rows

    row_rects = []
    y = inner_top
    for i in range(n_rows):
        row_rects.append((y, y + row_h))
        y += row_h + ROW_GAP

    content_left  = BORDER + PAD_LEFT
    content_right = THUMB_W - BORDER - PAD_RIGHT
    content_w     = content_right - content_left

    # Draw a very dim row background so rows are distinguishable
    row_bg = np.array([0, 8, 0], dtype=np.float32)
    for i, (ry0, ry1) in enumerate(row_rects):
        img[ry0:ry1, content_left:content_right] = row_bg

    # Row separator lines (single dim pixel between rows, inside border)
    sep_color = np.array([0, 30, 0], dtype=np.float32)
    y = inner_top
    for i in range(n_rows):
        rh = row_h
        y += rh
        if i < n_rows - 1:
            if 0 <= y < THUMB_H:
                img[y:y+ROW_GAP, BORDER:-BORDER] = sep_color
        y += ROW_GAP

    # Draw each band as a vertical Gaussian stripe
    for freq in sig:
        for i, row in enumerate(ROWS):
            if row['flo'] <= freq <= row['fhi']:
                ry0, ry1 = row_rects[i]
                t = (freq - row['flo']) / (row['fhi'] - row['flo'])
                xc = content_left + t * content_w

                # Gaussian profile across x
                xs = np.arange(THUMB_W, dtype=np.float32)
                gauss = np.exp(-0.5 * ((xs - xc) / BAND_SIGMA) ** 2)
                gauss *= BAND_PEAK

                # Add to all rows in that band's y range
                for y in range(ry0, ry1):
                    img[y, :, 0] = np.clip(img[y, :, 0] + gauss * BAND_COLOR[0], 0, 255)
                    img[y, :, 1] = np.clip(img[y, :, 1] + gauss * BAND_COLOR[1], 0, 255)
                    img[y, :, 2] = np.clip(img[y, :, 2] + gauss * BAND_COLOR[2], 0, 255)
                break

    out = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), 'RGB')
    out.save(out_path, 'PNG', optimize=True)
    print(f'  Written: {out_path}  ({THUMB_W}x{THUMB_H})')


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    print(f'Generating cartoon thumbnails ({THUMB_W}x{THUMB_H}) ...')
    draw_thumbnail(SIG1, os.path.join(OUT_DIR, 'thumb_v1.png'))
    draw_thumbnail(SIG2, os.path.join(OUT_DIR, 'thumb_v2.png'))
    draw_thumbnail(SIG3, os.path.join(OUT_DIR, 'thumb_v3.png'))
    print('Done.')


if __name__ == '__main__':
    main()
