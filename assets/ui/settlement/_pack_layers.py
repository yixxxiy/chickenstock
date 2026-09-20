# Knock out generated white backgrounds, trim, slice pips, copy into the project.
from collections import deque
from pathlib import Path
from PIL import Image

SRC = Path(r"C:\Users\CYX\.cursor\projects\c-Users-CYX-OneDrive\assets")
DST = Path(r"C:\Users\CYX\OneDrive\文档\小鸡股市\assets\ui\settlement")
LAYERS = DST / "layers"
MOCKS = DST / "mockups"
LAYERS.mkdir(parents=True, exist_ok=True)
MOCKS.mkdir(parents=True, exist_ok=True)

COPY = {
    "settlement-daily-mockup.png": (MOCKS / "daily.png", False),
    "settlement-finale-mockup.png": (MOCKS / "finale.png", False),
    "layer-moon.png": (LAYERS / "00-moon.png", True),
    "layer-paper-stack.png": (LAYERS / "01-paper-stack.png", True),
    "layer-card-body.png": (LAYERS / "02-card-body.png", True),
    "layer-hang-tag.png": (LAYERS / "03-hang-tag.png", True),
    "layer-news-chip.png": (LAYERS / "10-news-chip.png", True),
    "layer-price-well.png": (LAYERS / "11-price-well.png", True),
    "layer-ledger-cell.png": (LAYERS / "12-ledger-cell.png", True),
    "layer-footnote-strip.png": (LAYERS / "13-footnote-strip.png", True),
    "layer-score-cell.png": (LAYERS / "20-score-cell.png", True),
    "layer-chart-well.png": (LAYERS / "21-chart-well.png", True),
    "layer-quest-stamp.png": (LAYERS / "22-quest-stamp.png", True),
}


def knockout(im: Image.Image, thresh: float = 36) -> Image.Image:
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()
    samples = [
        px[1, 1][:3], px[w - 2, 1][:3], px[1, h - 2][:3], px[w - 2, h - 2][:3],
        px[w // 2, 1][:3], px[w // 2, h - 2][:3], px[1, h // 2][:3], px[w - 2, h // 2][:3],
    ]
    bg = tuple(sum(s[i] for s in samples) // len(samples) for i in range(3))

    def is_bg(c) -> bool:
        r, g, b = c[:3]
        dist = ((r - bg[0]) ** 2 + (g - bg[1]) ** 2 + (b - bg[2]) ** 2) ** 0.5
        lum = (r + g + b) / 3.0
        sat = max(r, g, b) - min(r, g, b)
        return dist < thresh and lum > 208 and sat < 22

    seen = bytearray(w * h)
    q = deque()

    def push(x: int, y: int) -> None:
        i = y * w + x
        if seen[i]:
            return
        if not is_bg(px[x, y]):
            return
        seen[i] = 1
        q.append((x, y))

    for x in range(w):
        push(x, 0)
        push(x, h - 1)
    for y in range(h):
        push(0, y)
        push(w - 1, y)
    while q:
        x, y = q.popleft()
        px[x, y] = (0, 0, 0, 0)
        if x:
            push(x - 1, y)
        if x + 1 < w:
            push(x + 1, y)
        if y:
            push(x, y - 1)
        if y + 1 < h:
            push(x, y + 1)

    # Soft fringe: leftover near-white next to empty pixels fade out.
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            lum = (r + g + b) / 3.0
            sat = max(r, g, b) - min(r, g, b)
            if lum < 218 or sat > 28:
                continue
            near = False
            for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] == 0:
                    near = True
                    break
            if near:
                fade = max(0, int(255 * (1.0 - (lum - 218) / 37.0)))
                px[x, y] = (r, g, b, fade)
    return im


def trim(im: Image.Image, pad: int = 8) -> Image.Image:
    im = im.convert("RGBA")
    bbox = im.split()[-1].getbbox()
    if not bbox:
        return im
    l, t, r, b = bbox
    l, t = max(0, l - pad), max(0, t - pad)
    r, b = min(im.width, r + pad), min(im.height, b + pad)
    return im.crop((l, t, r, b))


def save(im: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path)
    a = im.split()[-1]
    zeros = a.histogram()[0]
    print(f"{path.name:24s} {im.size[0]:4d}x{im.size[1]:<4d}  empty={zeros}")


for src_name, (dest, knock) in COPY.items():
    p = SRC / src_name
    if not p.exists():
        print("MISSING", src_name)
        continue
    im = Image.open(p)
    if knock:
        im = trim(knockout(im))
    else:
        im = im.convert("RGBA")
    save(im, dest)

pips_src = SRC / "layer-rank-pips.png"
if pips_src.exists():
    pips = trim(knockout(Image.open(pips_src)))
    w, h = pips.size
    alpha = pips.split()[-1]
    runs = []
    inside = False
    start = 0
    for x in range(w):
        hit = any(alpha.getpixel((x, y)) > 24 for y in range(0, h, 2))
        if hit and not inside:
            inside, start = True, x
        elif not hit and inside:
            runs.append((start, x))
            inside = False
    if inside:
        runs.append((start, w))
    names = ["23-pip-empty.png", "24-pip-hit.png", "25-pip-now.png"]
    print("pip runs:", [(a, b, b - a) for a, b in runs])
    for i, name in enumerate(names):
        if i >= len(runs):
            break
        x0, x1 = runs[i]
        gap = 6
        sl = trim(pips.crop((max(0, x0 - gap), 0, min(w, x1 + gap), h)), pad=4)
        save(sl, LAYERS / name)

print("ok")
