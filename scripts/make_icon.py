#!/usr/bin/env python3
"""Draws the 1024x1024 app icon (RGB, no transparency) without third-party libraries:
a sunny meadow with a flower and a ladybug.

Usage: python3 scripts/make_icon.py Lernwiese/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
"""
import math
import struct
import sys
import zlib

SIZE = 1024


def clamp(value, low=0.0, high=1.0):
    return low if value < low else high if value > high else value


def mix(pixel, color, alpha):
    if alpha <= 0:
        return pixel
    return tuple(p * (1 - alpha) + c * alpha for p, c in zip(pixel, color))


def coverage(distance):
    return clamp(0.5 - distance)


def circle(px, py, cx, cy, r):
    return math.hypot(px - cx, py - cy) - r


def ellipse(px, py, cx, cy, rx, ry):
    # Approximate signed distance, good enough for anti-aliased edges.
    k = math.hypot((px - cx) / rx, (py - cy) / ry)
    return (k - 1) * min(rx, ry)


def segment(px, py, ax, ay, bx, by):
    dx, dy = bx - ax, by - ay
    t = clamp(((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy))
    return math.hypot(px - (ax + t * dx), py - (ay + t * dy))


SKY_TOP = (88, 182, 245)
SKY_BOTTOM = (190, 232, 255)
SUN = (255, 207, 51)
SUN_GLOW = (255, 236, 150)
CLOUD = (255, 255, 255)
HILL_BACK = (128, 204, 92)
HILL_FRONT = (82, 172, 70)
STEM = (46, 128, 58)
PETAL = (255, 255, 255)
PETAL_EDGE = (255, 140, 186)
CENTER = (255, 196, 30)
LADYBUG = (230, 52, 52)
BLACK = (34, 34, 40)
SHADOW = (20, 70, 30)

SUN_X, SUN_Y, SUN_R = 790, 230, 120
FLOWER_X, FLOWER_Y = 380, 470
PETAL_DIST, PETAL_R, CENTER_R = 104, 78, 70
BUG_X, BUG_Y, BUG_R = 735, 720, 92


def shade(x, y):
    t = clamp(y / 700)
    pixel = tuple(a + (b - a) * t for a, b in zip(SKY_TOP, SKY_BOTTOM))

    # Sun with rays
    ring = math.hypot(x - SUN_X, y - SUN_Y)
    if ring < 260:
        pixel = mix(pixel, SUN_GLOW, 0.45 * clamp((215 - ring) / 80))
        angle = math.atan2(y - SUN_Y, x - SUN_X)
        ray = abs(((angle / (2 * math.pi) * 12) % 1) - 0.5)
        if 150 < ring < 235 and ray > 0.32:
            pixel = mix(pixel, SUN, clamp((ray - 0.3) * 40) * clamp((235 - ring) / 10) * clamp((ring - 150) / 10))
        pixel = mix(pixel, SUN, coverage(ring - SUN_R))

    # Cloud
    if 90 < x < 480 and 80 < y < 340:
        d = min(circle(x, y, 210, 230, 70), circle(x, y, 300, 200, 90), circle(x, y, 380, 245, 60),
                ellipse(x, y, 290, 262, 170, 48))
        pixel = mix(pixel, CLOUD, coverage(d))

    # Hills
    pixel = mix(pixel, HILL_BACK, coverage(ellipse(x, y, 260, 1080, 760, 420)))
    pixel = mix(pixel, HILL_FRONT, coverage(ellipse(x, y, 860, 1150, 720, 420)))

    # Flower stem and leaf
    if 300 < x < 520 and 470 < y < 1024:
        stem = segment(x, y, FLOWER_X, FLOWER_Y + 40, FLOWER_X + 20, 1024) - 16
        pixel = mix(pixel, STEM, coverage(stem))
        leaf = ellipse(x, y, 450, 760, 70, 30)
        pixel = mix(pixel, STEM, coverage(leaf))

    # Flower head
    if abs(x - FLOWER_X) < 230 and abs(y - FLOWER_Y) < 230:
        shadow = circle(x, y, FLOWER_X + 8, FLOWER_Y + 14, PETAL_DIST + PETAL_R - 6)
        pixel = mix(pixel, SHADOW, 0.18 * clamp((20 - shadow) / 30))
        petals = min(circle(x, y, FLOWER_X + PETAL_DIST * math.cos(a), FLOWER_Y + PETAL_DIST * math.sin(a), PETAL_R)
                     for a in [i * math.pi / 3 + math.pi / 6 for i in range(6)])
        pixel = mix(pixel, PETAL_EDGE, coverage(petals))
        pixel = mix(pixel, PETAL, coverage(petals + 12))
        pixel = mix(pixel, CENTER, coverage(circle(x, y, FLOWER_X, FLOWER_Y, CENTER_R)))
        for dx, dy in [(-22, -18), (20, -24), (-4, 20), (26, 14), (-28, 16)]:
            pixel = mix(pixel, (232, 150, 20), coverage(circle(x, y, FLOWER_X + dx, FLOWER_Y + dy, 8)))

    # Ladybug
    if abs(x - BUG_X) < 160 and abs(y - BUG_Y) < 160:
        pixel = mix(pixel, SHADOW, 0.22 * clamp((24 - circle(x, y, BUG_X + 6, BUG_Y + 18, BUG_R)) / 30))
        pixel = mix(pixel, BLACK, coverage(circle(x, y, BUG_X - 88, BUG_Y - 34, 48)))
        pixel = mix(pixel, BLACK, coverage(circle(x, y, BUG_X, BUG_Y, BUG_R + 6)))
        pixel = mix(pixel, LADYBUG, coverage(circle(x, y, BUG_X, BUG_Y, BUG_R)))
        line = segment(x, y, BUG_X - 70, BUG_Y - 60, BUG_X + 60, BUG_Y + 70) - 5
        pixel = mix(pixel, BLACK, coverage(line) * coverage(circle(x, y, BUG_X, BUG_Y, BUG_R)))
        for dx, dy, r in [(-34, 10, 17), (12, -40, 16), (38, 30, 18), (-6, 52, 13), (52, -6, 12)]:
            pixel = mix(pixel, BLACK, coverage(circle(x, y, BUG_X + dx, BUG_Y + dy, r)))
        for dx, dy in [(-104, -46), (-82, -54)]:
            pixel = mix(pixel, (255, 255, 255), coverage(circle(x, y, BUG_X + dx, BUG_Y + dy, 8)))
    return pixel


def write_png(path, rows):
    raw = b"".join(b"\x00" + bytes(row) for row in rows)

    def chunk(kind, data):
        body = kind + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)

    header = struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0)
    with open(path, "wb") as handle:
        handle.write(b"\x89PNG\r\n\x1a\n")
        handle.write(chunk(b"IHDR", header))
        handle.write(chunk(b"IDAT", zlib.compress(raw, 9)))
        handle.write(chunk(b"IEND", b""))


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    rows = []
    for y in range(SIZE):
        row = bytearray()
        for x in range(SIZE):
            r, g, b = shade(x + 0.5, y + 0.5)
            row += bytes((int(round(r)), int(round(g)), int(round(b))))
        rows.append(row)
    write_png(sys.argv[1], rows)


if __name__ == "__main__":
    main()
