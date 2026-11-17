#!/usr/bin/env python3
"""
~/.vim/image_preview.py — render an image as ANSI truecolor blocks in the terminal.
Usage:  python3 ~/.vim/image_preview.py <image_file> [width_chars]
No external deps beyond Pillow (python3 -m pip install --user pillow).
"""
import sys
import os

try:
    from PIL import Image
except ImportError:
    print("Pillow not installed.  Run:  python3 -m pip install --user pillow")
    sys.exit(1)

if len(sys.argv) < 2:
    print("Usage: image_preview.py <image_file> [width_chars]")
    sys.exit(1)

path = sys.argv[1]
width = int(sys.argv[2]) if len(sys.argv) > 2 else 100

try:
    im = Image.open(path).convert("RGB")
except Exception as e:
    print("Cannot open image:", e)
    sys.exit(1)

# Terminal characters are roughly twice as tall as they are wide, so
# shrink the height to keep the aspect ratio looking right.
w, h = im.size
aspect = h / w
new_h = max(1, int(width * aspect * 0.5))
im = im.resize((width, new_h))

pixels = im.load()
lines = []
for y in range(new_h):
    line = ""
    for x in range(width):
        r, g, b = pixels[x, y]
        line += f"\x1b[48;2;{r};{g};{b}m  \x1b[0m"
    lines.append(line)

sys.stdout.write("\n".join(lines) + "\n")
