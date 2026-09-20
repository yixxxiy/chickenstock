from pathlib import Path

from PIL import Image

BASE = Path(r"C:\Users\CYX\OneDrive\文档\小鸡股市\assets\sprites")
BACKUP = Path(r"C:\Users\CYX\OneDrive\文档\小鸡股市\tools\_hen_src")
ALPHA_MIN = 18
CELL = 256
FEET_Y = 238
IDLE_H = 220


def knock_soft_white_halo(im: Image.Image) -> Image.Image:
	"""Drop the semi-transparent white fringe so the hen rim matches the chick."""
	im = im.convert("RGBA")
	pix = im.load()
	w, h = im.size
	for y in range(h):
		for x in range(w):
			r, g, b, a = pix[x, y]
			if a == 0 or a >= 210:
				continue
			luma = 0.2126 * r + 0.7152 * g + 0.0722 * b
			chroma = max(r, g, b) - min(r, g, b)
			if luma >= 210 and chroma <= 48:
				pix[x, y] = (r, g, b, 0)
	return im


def column_runs(im: Image.Image, min_col: int = 6) -> list[tuple[int, int]]:
	w, h = im.size
	pix = im.load()
	occ = []
	for x in range(w):
		s = 0
		for y in range(h):
			if pix[x, y][3] >= ALPHA_MIN:
				s += 1
		occ.append(s)
	runs: list[tuple[int, int]] = []
	start = None
	for x, v in enumerate(occ):
		if v >= min_col and start is None:
			start = x
		elif v < min_col and start is not None:
			runs.append((start, x - 1))
			start = None
	if start is not None:
		runs.append((start, w - 1))
	return runs


def content_bbox(im: Image.Image, x0: int, y0: int, x1: int, y1: int):
	pix = im.load()
	minx, miny, maxx, maxy = x1, y1, x0, y0
	found = False
	for y in range(y0, y1):
		for x in range(x0, x1):
			if pix[x, y][3] >= ALPHA_MIN:
				found = True
				if x < minx:
					minx = x
				if y < miny:
					miny = y
				if x > maxx:
					maxx = x
				if y > maxy:
					maxy = y
	if not found:
		return None
	return minx, miny, maxx + 1, maxy + 1


def place_frame(src: Image.Image, scale_to_h: int | None) -> Image.Image:
	frame = src.convert("RGBA")
	if scale_to_h and frame.size[1] > 0:
		ratio = scale_to_h / float(frame.size[1])
		nw = max(1, int(round(frame.size[0] * ratio)))
		nh = max(1, int(round(frame.size[1] * ratio)))
		frame = frame.resize((nw, nh), Image.Resampling.LANCZOS)
	cell = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
	x = (CELL - frame.size[0]) // 2
	y = FEET_Y - frame.size[1]
	if y < 4:
		y = 4
	cell.paste(frame, (x, y), frame)
	return cell


def extract_sprites(im: Image.Image, min_width: int, min_height: int) -> list[Image.Image]:
	sprites: list[Image.Image] = []
	for x0, x1 in column_runs(im):
		if x1 - x0 + 1 < min_width:
			continue
		bb = content_bbox(im, x0, 0, x1 + 1, im.size[1])
		if bb is None:
			continue
		if bb[3] - bb[1] < min_height:
			continue
		sprite = knock_soft_white_halo(im.crop(bb))
		bb2 = sprite.getbbox()
		if bb2:
			sprite = sprite.crop(bb2)
		sprites.append(sprite)
	return sprites


def pack(sprites: list[Image.Image], dest: Path, scale_to_h: int | None) -> None:
	out = Image.new("RGBA", (CELL * 8, CELL), (0, 0, 0, 0))
	for i, sprite in enumerate(sprites[:8]):
		cell = place_frame(sprite, scale_to_h)
		out.paste(cell, (i * CELL, 0), cell)
	out.save(dest)
	print(f"saved {dest.name} {out.size} frames={min(8, len(sprites))} scale_h={scale_to_h}")


def backup(name: str) -> None:
	BACKUP.mkdir(exist_ok=True)
	src = BASE / name
	dst = BACKUP / name
	if not dst.exists():
		Image.open(src).save(dst)


def recut_walk() -> None:
	backup("hen-walk-8.png")
	im = Image.open(BACKUP / "hen-walk-8.png").convert("RGBA")
	sprites = extract_sprites(im, min_width=80, min_height=180)
	if len(sprites) != 8:
		raise SystemExit(f"hen-walk expected 8 sprites, got {len(sprites)}")
	pack(sprites, BASE / "hen-walk-8.png", None)


def recut_idle() -> None:
	backup("hen-idle-8.png")
	im = Image.open(BACKUP / "hen-idle-8.png").convert("RGBA")
	full = extract_sprites(im, min_width=130, min_height=170)
	if len(full) < 3:
		raise SystemExit(f"hen-idle expected 3+ full hens, got {len(full)}")
	a, b, c = full[0], full[1], full[-1]
	# Same-size stands only, so idle does not pulse. Blink / chirp from the three full poses.
	sprites = [a, a, b, c, a, c, b, a]
	pack(sprites, BASE / "hen-idle-8.png", IDLE_H)


if __name__ == "__main__":
	recut_walk()
	recut_idle()
