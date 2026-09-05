from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(r"C:\Users\CYX\.cursor\projects\c-Users-CYX-OneDrive\assets")
DST = Path(r"C:\Users\CYX\OneDrive\文档\小鸡股市\assets\ui\farm-ui")

SPECS = {
	"dock-btn-green.png": ("dock_btn_green.png", 176, 132),
	"dock-btn-red.png": ("dock_btn_red.png", 176, 132),
	"dock-btn-green-wide.png": ("dock_btn_green_wide.png", 320, 120),
	"dock-panel.png": ("dock_panel.png", 384, 168),
}


def is_chroma(r: int, g: int, b: int, a: int) -> bool:
	if a < 12:
		return True
	if max(r, g, b) < 22:
		return True
	# Magenta / hot pink key, including anti-aliased fringes.
	if r >= 160 and b >= 150 and g <= 150 and (r - g) >= 30 and (b - g) >= 20:
		return True
	return False


def knock_bg(im: Image.Image) -> Image.Image:
	im = im.convert("RGBA")
	px = im.load()
	w, h = im.size
	seen = [[False] * w for _ in range(h)]
	q: deque[tuple[int, int]] = deque()
	for x in range(w):
		q.append((x, 0))
		q.append((x, h - 1))
	for y in range(h):
		q.append((0, y))
		q.append((w - 1, y))
	while q:
		x, y = q.popleft()
		if x < 0 or y < 0 or x >= w or y >= h or seen[y][x]:
			continue
		seen[y][x] = True
		r, g, b, a = px[x, y]
		if not is_chroma(r, g, b, a):
			continue
		px[x, y] = (0, 0, 0, 0)
		q.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
	for y in range(h):
		for x in range(w):
			r, g, b, a = px[x, y]
			if is_chroma(r, g, b, a) and r >= 160 and b >= 150:
				px[x, y] = (0, 0, 0, 0)
	return im


def tight_crop(im: Image.Image, pad: int = 1) -> Image.Image:
	a = im.getchannel("A").point(lambda v: 255 if v > 24 else 0)
	bb = a.getbbox()
	if bb is None:
		return im
	l, t, r, b = bb
	l = max(0, l - pad)
	t = max(0, t - pad)
	r = min(im.size[0], r + pad)
	b = min(im.size[1], b + pad)
	return im.crop((l, t, r, b))


def edge_inset(im: Image.Image, alpha_cut: int = 80) -> tuple[int, int, int, int]:
	px = im.load()
	w, h = im.size

	def col_solid(x: int) -> bool:
		hits = 0
		for y in range(h):
			if px[x, y][3] > alpha_cut:
				hits += 1
		return hits > h * 0.55

	def row_solid(y: int) -> bool:
		hits = 0
		for x in range(w):
			if px[x, y][3] > alpha_cut:
				hits += 1
		return hits > w * 0.55

	left = next((x for x in range(w) if col_solid(x)), 0)
	right = next((x for x in range(w - 1, -1, -1) if col_solid(x)), w - 1)
	top = next((y for y in range(h) if row_solid(y)), 0)
	bottom = next((y for y in range(h - 1, -1, -1) if row_solid(y)), h - 1)
	return left, top, w - 1 - right, h - 1 - bottom


DST.mkdir(parents=True, exist_ok=True)
for src_name, (dst_name, tw, th) in SPECS.items():
	im = tight_crop(knock_bg(Image.open(ROOT / src_name)))
	im.thumbnail((tw, th), Image.Resampling.LANCZOS)
	im.save(DST / dst_name)
	print(dst_name, im.size, "insets", edge_inset(im))
