from collections import deque
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(r"C:\Users\CYX\.cursor\projects\c-Users-CYX-OneDrive\assets")
DST_UI = Path(r"C:\Users\CYX\OneDrive\文档\小鸡股市\assets\ui")
DST_ROOT = Path(r"C:\Users\CYX\OneDrive\文档\小鸡股市")
TOOLS = Path(r"C:\Users\CYX\OneDrive\文档\小鸡股市\tools")


def is_chroma(r: int, g: int, b: int, a: int) -> bool:
	if a < 12:
		return True
	if max(r, g, b) < 18:
		return True
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


def tight_crop(im: Image.Image, pad: int = 6) -> Image.Image:
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


def is_beak_orange(r: int, g: int, b: int, a: int) -> bool:
	if a < 180:
		return False
	if r < 205 or g < 70 or g > 170 or b > 85:
		return False
	if r - g < 45 or r - b < 130:
		return False
	return True


def blobs(im: Image.Image, pred, min_pts: int = 20) -> list[list[tuple[int, int]]]:
	px = im.load()
	w, h = im.size
	seen = [[False] * w for _ in range(h)]
	out: list[list[tuple[int, int]]] = []
	for y in range(h):
		for x in range(w):
			if seen[y][x]:
				continue
			r, g, b, a = px[x, y]
			if not pred(r, g, b, a):
				seen[y][x] = True
				continue
			q = deque([(x, y)])
			seen[y][x] = True
			pts: list[tuple[int, int]] = []
			while q:
				cx, cy = q.popleft()
				pts.append((cx, cy))
				for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)):
					nx, ny = cx + dx, cy + dy
					if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx]:
						seen[ny][nx] = True
						rr, gg, bb, aa = px[nx, ny]
						if pred(rr, gg, bb, aa):
							q.append((nx, ny))
			if len(pts) >= min_pts:
				out.append(pts)
	return out


def fix_double_beak(im: Image.Image) -> Image.Image:
	im = im.copy()
	w, h = im.size
	px = im.load()
	# Darkest pixel in the inner field is the chick's eye.
	ex, ey = w // 2, h // 2
	best = 9999
	for y in range(int(h * 0.25), int(h * 0.65)):
		for x in range(int(w * 0.25), int(w * 0.65)):
			r, g, b, a = px[x, y]
			lum = r + g + b
			if a > 200 and lum < best:
				best = lum
				ex, ey = x, y

	zone = (max(0, ex - 140), max(0, ey - 50), min(w, ex + 10), min(h, ey + 120))

	def in_zone(x, y):
		return zone[0] <= x < zone[2] and zone[1] <= y < zone[3]

	face_blobs = []
	for pts in blobs(im, is_beak_orange, 80):
		cx = sum(p[0] for p in pts) // len(pts)
		cy = sum(p[1] for p in pts) // len(pts)
		if not in_zone(cx, cy):
			continue
		if len(pts) > 2800:
			continue
		face_blobs.append((cx, cy, pts))
	print("eye", ex, ey, "beak blobs", [(t[0], t[1], len(t[2])) for t in face_blobs])
	if not face_blobs:
		return im
	keep = min(face_blobs, key=lambda t: abs(t[1] - ey) * 2 + abs(t[0] - ex))
	keep_pts = keep[2]
	max_y = max(p[1] for p in keep_pts)
	min_x = min(p[0] for p in keep_pts)
	max_x = max(p[0] for p in keep_pts)
	# Paint out a stacked second beak sitting just under the real one.
	erase = set()
	for cx, cy, pts in face_blobs:
		if pts is keep_pts:
			continue
		erase.update(pts)
	# Also catch a pale leftover jaw: yellow/orange pixels in a wedge
	# under and left of the real beak, which should be coin gold instead.
	for y in range(max_y - 2, min(h, max_y + 62)):
		for x in range(min_x - 28, max_x + 8):
			if not (0 <= x < w and 0 <= y < h):
				continue
			if (x, y) in keep_pts:
				continue
			r, g, b, a = px[x, y]
			if a < 180:
				continue
			if r > 170 and g < 210 and b < 90 and (r - b) > 80:
				erase.add((x, y))
	for x, y in erase:
		samples = []
		for dx, dy in ((-14, 0), (-22, 4), (-18, -6), (-10, 10), (0, 16)):
			nx, ny = x + dx, y + dy
			if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in erase:
				rr, gg, bb, aa = px[nx, ny]
				if aa > 180 and rr > 200 and gg > 150:
					samples.append((rr, gg, bb))
		if not samples:
			for dx, dy in ((12, 8), (18, 4), (10, 14)):
				nx, ny = x + dx, y + dy
				if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in erase:
					rr, gg, bb, aa = px[nx, ny]
					if aa > 180 and rr > 200 and gg > 180:
						samples.append((rr, gg, bb))
		if samples:
			n = len(samples)
			px[x, y] = (
				sum(s[0] for s in samples) // n,
				sum(s[1] for s in samples) // n,
				sum(s[2] for s in samples) // n,
				255,
			)
	return im


def circular_mask(im: Image.Image) -> Image.Image:
	im = tight_crop(im, 2)
	side = max(im.size)
	canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
	canvas.paste(im, ((side - im.size[0]) // 2, (side - im.size[1]) // 2), im)
	mask = Image.new("L", (side, side), 0)
	ImageDraw.Draw(mask).ellipse((1, 1, side - 2, side - 2), fill=255)
	mask = mask.filter(ImageFilter.GaussianBlur(0.6))
	out = Image.new("RGBA", (side, side), (0, 0, 0, 0))
	out.paste(canvas, (0, 0))
	out.putalpha(ImageChops.multiply(canvas.getchannel("A"), mask))
	return out


def fit_square(im: Image.Image, size: int) -> Image.Image:
	im.thumbnail((size - 8, size - 8), Image.Resampling.LANCZOS)
	canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
	x = (size - im.size[0]) // 2
	y = (size - im.size[1]) // 2
	canvas.paste(im, (x, y), im)
	return canvas


DST_UI.mkdir(parents=True, exist_ok=True)

icon = knock_bg(Image.open(ROOT / "game-icon.png"))
icon = fix_double_beak(icon)
icon = circular_mask(icon)
icon = fit_square(icon, 512)
icon.save(DST_ROOT / "icon.png")
icon.save(DST_UI / "logo_icon.png")
print("icon.png", icon.size)

word = tight_crop(knock_bg(Image.open(ROOT / "game-wordmark.png")), 8)
word.thumbnail((1280, 360), Image.Resampling.LANCZOS)
word.save(DST_UI / "logo_wordmark.png")
print("logo_wordmark.png", word.size)

# Keep logo.png as the circular mark too so title lockups stay in sync.
icon.save(DST_UI / "logo.png")
print("logo.png (circular icon)")

for name in ("_face_crop.png", "_beak_crop.png"):
	p = TOOLS / name
	if p.exists():
		p.unlink()
