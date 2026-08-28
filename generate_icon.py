#!/usr/bin/env python3
"""Generate Anchor Learning app icons for Android and the Web."""
from PIL import Image, ImageDraw, ImageFilter
import math
from pathlib import Path

# Colors
GREEN = (88, 204, 2)       # #58CC02 - Anchor green
GREEN_DARK = (66, 160, 2)  # darker green for depth
WHITE = (255, 255, 255)
SHADOW = (40, 120, 0)

def create_icon(size):
    """Create a graduation cap icon at given size."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Draw rounded square background
    radius = int(size * 0.22)
    # Main green background
    draw.rounded_rectangle(
        [0, 0, size - 1, size - 1],
        radius=radius,
        fill=GREEN
    )
    
    # Add subtle gradient effect - lighter top, darker bottom
    overlay = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    overlay_draw = ImageDraw.Draw(overlay)
    for i in range(size):
        alpha = int(25 * (1 - i / size))
        overlay_draw.line([(0, i), (size, i)], fill=(255, 255, 255, alpha))
    img = Image.alpha_composite(img, overlay)
    draw = ImageDraw.Draw(img)
    
    # Center coordinates
    cx, cy = size // 2, size // 2
    
    # === Draw Graduation Cap (Mortarboard) ===
    
    # Scale factor
    s = size / 192.0  # base design is for 192px
    
    # Mortarboard (the flat square top) - diamond shape
    board_half_w = int(55 * s)
    board_half_h = int(18 * s)
    board_cy = int(78 * s)
    
    # Shadow under the board
    shadow_offset = int(4 * s)
    shadow_points = [
        (cx - board_half_w, board_cy + shadow_offset),
        (cx, board_cy + board_half_h + shadow_offset),
        (cx + board_half_w, board_cy + shadow_offset),
        (cx, board_cy - board_half_h + shadow_offset),
    ]
    # Draw shadow as semi-transparent
    shadow_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow_img)
    shadow_draw.polygon(shadow_points, fill=(0, 0, 0, 40))
    shadow_img = shadow_img.filter(ImageFilter.GaussianBlur(radius=int(3 * s)))
    img = Image.alpha_composite(img, shadow_img)
    draw = ImageDraw.Draw(img)
    
    # The mortarboard - white diamond
    board_points = [
        (cx - board_half_w, board_cy),
        (cx, board_cy + board_half_h),
        (cx + board_half_w, board_cy),
        (cx, board_cy - board_half_h),
    ]
    draw.polygon(board_points, fill=WHITE)
    
    # Add a line across the middle of the board for 3D effect
    draw.line(
        [(cx - board_half_w + int(4*s), board_cy),
         (cx + board_half_w - int(4*s), board_cy)],
        fill=(220, 220, 220),
        width=max(1, int(2 * s))
    )
    
    # Cap base (the part below the board) - rounded trapezoid
    base_top_w = int(28 * s)
    base_bottom_w = int(22 * s)
    base_top_y = board_cy + int(2 * s)
    base_bottom_y = board_cy + int(32 * s)
    
    base_points = [
        (cx - base_top_w, base_top_y),
        (cx + base_top_w, base_top_y),
        (cx + base_bottom_w, base_bottom_y),
        (cx - base_bottom_w, base_bottom_y),
    ]
    draw.polygon(base_points, fill=WHITE)
    
    # Round the bottom of the base
    draw.ellipse(
        [cx - base_bottom_w, base_bottom_y - int(6*s),
         cx + base_bottom_w, base_bottom_y + int(6*s)],
        fill=WHITE
    )
    
    # Tassel - from right corner of the board hanging down
    tassel_start_x = cx + board_half_w - int(2 * s)
    tassel_start_y = board_cy
    tassel_end_x = cx + board_half_w + int(8 * s)
    tassel_end_y = board_cy + int(50 * s)
    
    # Tassel cord
    draw.line(
        [(tassel_start_x, tassel_start_y),
         (tassel_end_x, tassel_end_y)],
        fill=GREEN_DARK,
        width=max(2, int(4 * s))
    )
    
    # Tassel knot at the end
    knot_x = tassel_end_x
    knot_y = tassel_end_y
    knot_r = int(5 * s)
    draw.ellipse(
        [knot_x - knot_r, knot_y - knot_r,
         knot_x + knot_r, knot_y + knot_r],
        fill=GREEN_DARK
    )
    
    # Tassel fringe (strings hanging down)
    for i in range(-3, 4):
        fx = knot_x + i * int(2 * s)
        fy_start = knot_y + int(3 * s)
        fy_end = knot_y + int(18 * s)
        draw.line(
            [(fx, fy_start), (fx + i * int(1*s), fy_end)],
            fill=GREEN_DARK,
            width=max(1, int(2 * s))
        )
    
    return img

def main():
    repo_root = Path(__file__).resolve().parent
    android_res_dir = repo_root / 'android' / 'app' / 'src' / 'main' / 'res'
    
    sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }
    
    for folder, size in sizes.items():
        img = create_icon(size)
        path = android_res_dir / folder / 'ic_launcher.png'
        path.parent.mkdir(parents=True, exist_ok=True)
        img.save(path, 'PNG')
        print(f'Saved {path} ({size}x{size})')
    
    # Also create a round icon variant (same design, just save as ic_launcher_round)
    for folder, size in sizes.items():
        img = create_icon(size)
        # Create circular mask
        mask = Image.new('L', (size, size), 0)
        mask_draw = ImageDraw.Draw(mask)
        mask_draw.ellipse([0, 0, size, size], fill=255)
        # Apply mask
        result = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        result.paste(img, (0, 0), mask)
        path = android_res_dir / folder / 'ic_launcher_round.png'
        result.save(path, 'PNG')
        print(f'Saved {path} ({size}x{size})')
    
    # Also save a high-res version for web/favicon
    web_dir = repo_root / 'web'
    (web_dir / 'icons').mkdir(parents=True, exist_ok=True)
    for web_size in [192, 512]:
        img = create_icon(web_size)
        path = web_dir / 'icons' / f'Icon-{web_size}.png'
        img.save(path, 'PNG')
        print(f'Saved {path} ({web_size}x{web_size})')
    
    # Maskable versions
    for web_size in [192, 512]:
        img = create_icon(web_size)
        path = web_dir / 'icons' / f'Icon-maskable-{web_size}.png'
        img.save(path, 'PNG')
        print(f'Saved {path} ({web_size}x{web_size})')
    
    # Favicon
    img = create_icon(32)
    path = web_dir / 'favicon.png'
    img.save(path, 'PNG')
    print(f'Saved {path} (32x32)')
    
    print('\nAll icons generated successfully!')

if __name__ == '__main__':
    main()
