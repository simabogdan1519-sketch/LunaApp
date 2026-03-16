#!/usr/bin/env python3
"""Creates a simple white moon notification icon for Android."""
import os, struct, zlib

def create_white_moon_png(size=24):
    """Create a minimal white moon silhouette PNG."""
    import math
    
    width = height = size
    pixels = []
    cx, cy = size/2, size/2
    r_outer = size * 0.42
    r_inner = size * 0.28
    offset_x = size * 0.12
    
    for y in range(height):
        row = []
        for x in range(width):
            # Outer circle
            in_outer = (x - cx)**2 + (y - cy)**2 <= r_outer**2
            # Inner circle (shifted to create crescent)
            in_inner = (x - cx + offset_x)**2 + (y - cy)**2 <= r_inner**2
            
            if in_outer and not in_inner:
                row.extend([255, 255, 255, 255])  # white opaque
            else:
                row.extend([0, 0, 0, 0])  # transparent
        pixels.append(bytes(row))
    
    def png_chunk(name, data):
        c = zlib.crc32(name + data) & 0xffffffff
        return struct.pack('>I', len(data)) + name + data + struct.pack('>I', c)
    
    raw = b''
    for row in pixels:
        raw += b'\x00' + row
    
    compressed = zlib.compress(raw, 9)
    
    png = b'\x89PNG\r\n\x1a\n'
    png += png_chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0))
    png += png_chunk(b'IDAT', compressed)
    png += png_chunk(b'IEND', b'')
    return png

sizes = {
    'mipmap-mdpi': 24,
    'mipmap-hdpi': 36,
    'mipmap-xhdpi': 48,
    'mipmap-xxhdpi': 72,
    'mipmap-xxxhdpi': 96,
}

script_dir = os.path.dirname(os.path.abspath(__file__))
base = os.path.join(script_dir, '..', 'android', 'app', 'src', 'main', 'res')

for density, size in sizes.items():
    folder = os.path.join(base, density)
    os.makedirs(folder, exist_ok=True)
    path = os.path.join(folder, 'ic_luna_notif.png')
    with open(path, 'wb') as f:
        f.write(create_white_moon_png(size))
    print(f"Created {path}")

# Also create drawable/ic_luna_notif.png (fallback)
drawable = os.path.join(base, 'drawable')
os.makedirs(drawable, exist_ok=True)
path = os.path.join(drawable, 'ic_luna_notif.png')
with open(path, 'wb') as f:
    f.write(create_white_moon_png(24))
print(f"Created {path}")
