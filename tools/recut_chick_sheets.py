from pathlib import Path

from PIL import Image

BASE = Path(r"C:\Users\CYX\OneDrive\文档\小鸡股市\assets\sprites")
ALPHA_MIN = 14


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


def crop_cell(im: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
	x0, y0, x1, y1 = box
	return im.crop((x0, y0, x1, y1))


def place_frame(src: Image.Image, cell_w: int, cell_h: int, feet_y: int, scale_to_h: int | None) -> Image.Image:
	frame = src.convert("RGBA")
	if scale_to_h and frame.size[1] > 0:
		ratio = scale_to_h / float(frame.size[1])
		nw = max(1, int(round(frame.size[0] * ratio)))
		nh = max(1, int(round(frame.size[1] * ratio)))
		frame = frame.resize((nw, nh), Image.Resampling.LANCZOS)
	cell = Image.new("RGBA", (cell_w, cell_h), (0, 0, 0, 0))
	x = (cell_w - frame.size[0]) // 2
	y = feet_y - frame.size[1]
	cell.paste(frame, (x, y), frame)
	return cell


def recut_even(name: str, cols: int, cell_w: int, cell_h: int, feet_y: int, scale_to_h: int | None) -> None:
	src = Image.open(BASE / name).convert("RGBA")
	w, h = src.size
	out = Image.new("RGBA", (cell_w * cols, cell_h), (0, 0, 0, 0))
	cw = w / cols
	for i in range(cols):
		x0 = int(round(i * cw))
		x1 = int(round((i + 1) * cw))
		bb = content_bbox(src, x0, 0, x1, h)
		if bb is None:
			continue
		sprite = crop_cell(src, bb)
		cell = place_frame(sprite, cell_w, cell_h, feet_y, scale_to_h)
		out.paste(cell, (i * cell_w, 0), cell)
	out.save(BASE / name)
	print(f"saved {name} {out.size} scale_h={scale_to_h}")


if __name__ == "__main__":
	# Walk is already even 256 cells; re-center on the same foot line.
	recut_even("chick-walk-8.png", 8, 256, 256, 238, None)
	# Idle frames were drawn at random scales; normalize body height and feet.
	recut_even("chick-idle-8.png", 8, 256, 256, 238, 210)
	# Old walk strip is 2172px wide (271.5 per frame). Pack into integer cells.
	recut_even("chick-walk-8frames.png", 8, 272, 400, 384, None)
