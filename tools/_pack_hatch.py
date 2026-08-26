from pathlib import Path

from PIL import Image, ImageChops, ImageFilter

SRC = Path(r"C:\Users\CYX\.cursor\projects\c-Users-CYX-OneDrive\assets\hatch-8-raw.png")
DST = Path(r"C:\Users\CYX\OneDrive\文档\小鸡股市\assets\sprites\hatch-8.png")
CELL = 128
PAD = 10
OUTLINE = 3


def knock_black(im: Image.Image) -> Image.Image:
	im = im.convert("RGBA")
	px = im.load()
	w, h = im.size
	for y in range(h):
		for x in range(w):
			r, g, b, _a = px[x, y]
			mx = max(r, g, b)
			if mx < 16:
				px[x, y] = (r, g, b, 0)
			elif mx < 38:
				px[x, y] = (r, g, b, int(255 * (mx - 16) / 22))
	return im


def content_bbox(im: Image.Image, thresh: int = 24) -> tuple[int, int, int, int]:
	a = im.split()[-1].point(lambda v: 255 if v > thresh else 0)
	bb = a.getbbox()
	if bb is None:
		return (0, 0, im.size[0], im.size[1])
	return bb


def column_runs(im: Image.Image) -> list[tuple[int, int]]:
	w, h = im.size
	px = im.load()
	occ = []
	for x in range(w):
		s = 0
		for y in range(h):
			if px[x, y][3] > 30:
				s += 1
		occ.append(s)
	runs: list[tuple[int, int]] = []
	start = None
	for x, v in enumerate(occ):
		if v > 8 and start is None:
			start = x
		elif v <= 8 and start is not None:
			runs.append((start, x - 1))
			start = None
	if start is not None:
		runs.append((start, w - 1))
	return runs


def add_outline(im: Image.Image, radius: int) -> Image.Image:
	alpha = im.getchannel("A")
	dilated = alpha
	for _ in range(radius):
		dilated = dilated.filter(ImageFilter.MaxFilter(3))
	ring = ImageChops.subtract(dilated, alpha)
	out = Image.new("RGBA", im.size, (0, 0, 0, 0))
	out.paste(Image.new("RGBA", im.size, (255, 255, 255, 255)), mask=ring)
	out.alpha_composite(im)
	# Keep outline inside the cell so frames do not share a white seam.
	px = out.load()
	for x in (0, im.size[0] - 1):
		for y in range(im.size[1]):
			px[x, y] = (0, 0, 0, 0)
	return out


def fit_cell(im: Image.Image) -> Image.Image:
	bb = content_bbox(im)
	cropped = im.crop(bb)
	inner = CELL - PAD * 2
	scale = min(inner / cropped.size[0], inner / cropped.size[1])
	nw = max(1, int(cropped.size[0] * scale))
	nh = max(1, int(cropped.size[1] * scale))
	fitted = cropped.resize((nw, nh), Image.Resampling.LANCZOS)
	cell = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
	# Sit sprites on a shared ground line so the egg does not jump.
	x = (CELL - nw) // 2
	y = CELL - nh - PAD
	cell.paste(fitted, (x, y), fitted)
	return add_outline(cell, OUTLINE)


raw = knock_black(Image.open(SRC))
runs = column_runs(raw)
if len(runs) != 8:
	raise SystemExit(f"expected 8 frames, got {len(runs)}: {runs}")

_x0, y0, _x1, y1 = content_bbox(raw)
sheet = Image.new("RGBA", (CELL * 8, CELL), (0, 0, 0, 0))
w = raw.size[0]
for i, (left, right) in enumerate(runs):
	pad_x = 6
	frame = raw.crop((max(0, left - pad_x), y0, min(w, right + pad_x + 1), y1))
	sheet.paste(fit_cell(frame), (i * CELL, 0))

DST.parent.mkdir(parents=True, exist_ok=True)
sheet.save(DST)
