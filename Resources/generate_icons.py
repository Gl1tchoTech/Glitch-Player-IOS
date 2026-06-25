#!/usr/bin/env python3
"""Generate iOS app icon assets for MeloPlayer in all required sizes."""

import math
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUTPUT_DIR = os.path.join(
    "C:\\Users\\shado\\Downloads\\GlitchPlayer\\MeloPlayerClone",
    "Resources", "Assets.xcassets", "AppIcon.appiconset"
)
os.makedirs(OUTPUT_DIR, exist_ok=True)

# All required iOS icon sizes in pixels
ICON_SIZES = [
    # (pixel_size, idiomatic_name)
    (20,   "20x20-1x"),
    (40,   "20x20-2x"),
    (60,   "20x20-3x"),
    (29,   "29x29-1x"),
    (58,   "29x29-2x"),
    (87,   "29x29-3x"),
    (40,   "40x40-1x"),
    (80,   "40x40-2x"),
    (120,  "40x40-3x"),
    (60,   "60x60-1x"),
    (120,  "60x60-2x"),
    (180,  "60x60-3x"),
    (76,   "76x76-1x"),
    (152,  "76x76-2x"),
    (167,  "83.5x83.5-2x"),
    (1024, "1024x1024-1x"),
]


def rounded_rectangle_mask(size, radius):
    """Create a mask for rounded rectangle (squircle)."""
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), (size[0]-1, size[1]-1)], radius=radius, fill=255)
    return mask


def draw_music_note(draw, cx, cy, size, color):
    """Draw a stylized music note centered at (cx, cy)."""
    s = size  # base scale
    
    # Note head (filled ellipse)
    note_head_w = int(s * 0.22)
    note_head_h = int(s * 0.16)
    note_head_x = cx - int(s * 0.15)
    note_head_y = cy + int(s * 0.12)
    draw.ellipse(
        [(note_head_x - note_head_w//2, note_head_y - note_head_h//2),
         (note_head_x + note_head_w//2, note_head_y + note_head_h//2)],
        fill=color
    )
    
    # Note stem (vertical line)
    stem_x = note_head_x + note_head_w//2
    stem_top = cy - int(s * 0.35)
    stem_bottom = note_head_y
    draw.line([(stem_x, stem_top), (stem_x, stem_bottom)], fill=color, width=max(1, int(s * 0.035)))
    
    # Note flag (curved line)
    flag_x = stem_x
    flag_y = stem_top
    flag_end_x = flag_x + int(s * 0.15)
    flag_end_y = flag_y + int(s * 0.08)
    flag_mid_y = flag_y + int(s * 0.12)
    draw.line(
        [(flag_x, flag_y), (flag_end_x, flag_mid_y), (flag_x - int(s * 0.02), flag_mid_y + int(s * 0.04))],
        fill=color, width=max(1, int(s * 0.035)), joint="curve"
    )


def draw_equalizer_bars(draw, cx, cy, size, color):
    """Draw three equalizer bars (like a mini waveform) next to the note."""
    s = size
    bar_w = max(2, int(s * 0.04))
    spacing = max(3, int(s * 0.045))
    start_x = cx + int(s * 0.2)
    base_y = cy + int(s * 0.25)
    
    heights = [int(s * 0.2), int(s * 0.32), int(s * 0.14), int(s * 0.24)]
    
    for i, h in enumerate(heights):
        bx = start_x + i * spacing * 3
        draw.rounded_rectangle(
            [(bx, base_y - h), (bx + bar_w, base_y)],
            radius=max(1, int(s * 0.01)),
            fill=color
        )


def draw_icon(size):
    """Generate a single app icon at the given pixel size."""
    scale = size / 1024.0
    corner_radius = int(size * 0.225)  # iOS squircle ratio
    
    # Create canvas with dark background
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    
    # Squircle mask for the icon shape
    mask = rounded_rectangle_mask((size, size), corner_radius)
    
    # Draw gradient background
    bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bg_draw = ImageDraw.Draw(bg)
    
    # Vertical gradient from dark pink/purple to darker near-black
    steps = size
    for y in range(steps):
        ratio = y / steps
        # Gradient: deep magenta/pink (#2D0B3E) to near-black (#0A0A14) with pink tint
        r = int(45 + ratio * 10)   # 45 -> 10
        g = int(11 + ratio * 3)    # 11 -> 3
        b = int(62 * (1 - ratio) + 20 * ratio)  # 62 -> 20
        alpha = 255
        color = (r, g, b, alpha)
        bg_draw.line([(0, y), (size, y)], fill=color)
    
    # Apply squircle mask to background
    bg.putalpha(mask)
    
    # Create the icon canvas
    icon = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    icon.paste(bg, (0, 0), mask)
    
    # Draw the artwork on top
    draw = ImageDraw.Draw(icon)
    cx = size // 2
    cy = size // 2
    
    # Subtle glow circles behind the note
    glow_radius = int(size * 0.25)
    for r_offset in range(3):
        r = glow_radius + r_offset * int(size * 0.03)
        alpha = max(0, 40 - r_offset * 15)
        glow_color = (255, 70, 140, alpha)
        draw.ellipse(
            [(cx - r, cy - r), (cx + r, cy + r)],
            fill=glow_color
        )
    
    # Music note - white with slight pink tint
    note_color = (255, 255, 255, 245)
    draw_music_note(draw, cx, cy, size * 0.7, note_color)
    
    # Small equalizer bars on the right side
    eq_color = (255, 100, 160, 220)
    draw_equalizer_bars(draw, cx, cy, size, eq_color)
    
    # Apply squircle mask to final icon to ensure clean edges
    final = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    final.paste(icon, (0, 0), mask)
    
    return final


def main():
    print(f"Generating icons in: {OUTPUT_DIR}")
    print(f"Icon sizes: {len(ICON_SIZES)} variants")
    
    for px_size, name in ICON_SIZES:
        icon = draw_icon(px_size)
        filename = f"icon-{name}.png"
        filepath = os.path.join(OUTPUT_DIR, filename)
        icon.save(filepath, "PNG")
        print(f"  [OK] {filename} ({px_size}x{px_size})")
    
    # Also save the 1024 as the base icon.png for reference
    print(f"\nAll {len(ICON_SIZES)} icons generated successfully!")
    print(f"Output: {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
