# Hard-trim white-matte fringe on wood UI slices, then reinstall runtime copies.
from pathlib import Path
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
NAMED = ROOT / "assets/ui/farm-ui/generated-v2/ui-kit-spreadsheet/named"
SIMPLE = ROOT / "assets/ui/farm-ui/simple-ui"
FARM = ROOT / "assets/ui/farm-ui"
GEN_SIMPLE = ROOT / "assets/ui/farm-ui/generated-v2/simple-ui"
UI = ROOT / "assets/ui"
ICONS = ROOT / "icons"
SETTLE = ROOT / "assets/ui/settlement/layers"

WOOD_ERODE = {
	"panel-tall-modal": 2,
	"panel-medium-dialog": 2,
	"panel-hud-bar": 2,
	"chip-value-slot": 2,
	"panel-dock": 2,
	"strip-news": 2,
	"btn-green-wide": 2,
	"btn-beige-wide": 2,
	"btn-red-medium": 2,
	"btn-green-short": 2,
	"btn-red-short": 2,
	"btn-square-icon": 2,
	"btn-close-x": 1,
	"chip-toggle-on": 2,
	"chip-toggle-off": 2,
	"bar-progress-track": 2,
	"ribbon-red": 2,
	"bar-progress-fill": 1,
	"seal-check-green": 1,
	"seal-x-red": 1,
}


def hard_trim(im: Image.Image, erode: int = 2) -> Image.Image:
	im = im.convert("RGBA")
	w, h = im.size
	spx = im.load()
	alpha = im.split()[-1]
	solid = alpha.point(lambda a: 255 if a > 32 else 0)
	core = solid
	for _ in range(erode):
		core = core.filter(ImageFilter.MinFilter(3))
	cpx = core.load()

	deep = core
	for _ in range(3):
		deep = deep.filter(ImageFilter.MinFilter(3))
	dpx = deep.load()
	woods: list[tuple[int, int, int]] = []
	for y in range(h):
		for x in range(w):
			if not dpx[x, y]:
				continue
			r, g, b, _a = spx[x, y]
			lum = (r + g + b) / 3
			if 25 <= lum <= 110:
				woods.append((r, g, b))
	if woods:
		woods.sort(key=lambda t: sum(t))
		wr, wg, wb = woods[len(woods) // 2]
	else:
		wr, wg, wb = 70, 55, 40

	out = Image.new("RGBA", im.size, (0, 0, 0, 0))
	opx = out.load()
	for y in range(h):
		for x in range(w):
			if not cpx[x, y]:
				continue
			r, g, b, _a = spx[x, y]
			touch = False
			for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
				nx, ny = x + dx, y + dy
				if nx < 0 or ny < 0 or nx >= w or ny >= h or cpx[nx, ny] == 0:
					touch = True
					break
			if touch and (r + g + b) / 3 > 95:
				opx[x, y] = (wr, wg, wb, 255)
			else:
				opx[x, y] = (r, g, b, 255)
	return out


def clean_light_icon(im: Image.Image) -> Image.Image:
	im = im.convert("RGBA")
	w, h = im.size
	px = im.load()
	for _ in range(3):
		kill: list[tuple[int, int]] = []
		for y in range(h):
			for x in range(w):
				r, g, b, a = px[x, y]
				if a == 0:
					continue
				touch = False
				for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (1, -1), (-1, 1), (1, 1)):
					nx, ny = x + dx, y + dy
					if nx < 0 or ny < 0 or nx >= w or ny >= h or px[nx, ny][3] == 0:
						touch = True
						break
				if not touch:
					continue
				lum = (r + g + b) / 3.0
				sat = max(r, g, b) - min(r, g, b)
				if lum >= 190 and sat <= 50:
					kill.append((x, y))
				elif lum >= 170 and sat <= 30:
					kill.append((x, y))
				elif a < 200 and lum >= 150:
					kill.append((x, y))
		for x, y in kill:
			px[x, y] = (0, 0, 0, 0)
	return im


def edge_max(im: Image.Image) -> tuple[int, int]:
	px = im.load()
	w, h = im.size
	mx = 0
	cnt = 0
	for y in range(h):
		for x in range(w):
			r, g, b, a = px[x, y]
			if a == 0:
				continue
			touch = False
			for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
				if nx < 0 or ny < 0 or nx >= w or ny >= h or px[nx, ny][3] == 0:
					touch = True
					break
			if touch:
				cnt += 1
				mx = max(mx, (r + g + b) // 3)
	return cnt, mx


def pad_square(im: Image.Image, size: int = 256) -> Image.Image:
	w0, h0 = im.size
	scale = min(size / w0, size / h0) * 0.92
	nw, nh = max(1, int(w0 * scale)), max(1, int(h0 * scale))
	resized = im.resize((nw, nh), Image.Resampling.LANCZOS)
	out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
	out.paste(resized, ((size - nw) // 2, (size - nh) // 2), resized)
	return out


def main() -> None:
	for key, erode in WOOD_ERODE.items():
		path = next(NAMED.glob(f"*-{key}.png"))
		im = hard_trim(Image.open(path), erode=erode)
		im.save(path)
		print(f"{key:24s} edge={edge_max(im)}")

	for path in NAMED.glob("*-icon-*.png"):
		im = clean_light_icon(Image.open(path))
		im.save(path)
		print(f"{path.stem:24s} edge={edge_max(im)}")

	saved = {p.stem.split("-", 1)[1]: Image.open(p).convert("RGBA") for p in NAMED.glob("*.png")}
	panel = saved["panel-tall-modal"]
	panel.save(SIMPLE / "panel.png")
	panel.save(GEN_SIMPLE / "panel.png")
	panel.save(FARM / "frame_tall_9slice.png")
	panel.save(FARM / "frame_tall.png")
	saved["panel-dock"].save(FARM / "dock_panel.png")

	g = saved["btn-green-wide"]
	b = saved["btn-beige-wide"]
	r = saved["btn-red-medium"]
	g.save(SIMPLE / "button-green.png")
	g.save(GEN_SIMPLE / "button-green.png")
	b.save(SIMPLE / "button-beige.png")
	b.save(GEN_SIMPLE / "button-beige.png")
	r.save(SIMPLE / "button-red.png")
	r.save(GEN_SIMPLE / "button-red.png")
	saved["chip-toggle-off"].save(SIMPLE / "tag.png")
	saved["chip-toggle-off"].save(GEN_SIMPLE / "tag.png")
	for dst in ("button_green.png", "button_empty_green.png", "dock_btn_green.png", "dock_btn_green_wide.png"):
		g.save(FARM / dst)
	for dst in ("button_empty_beige.png", "button_neutral.png"):
		b.save(FARM / dst)
	for dst in ("button_red.png", "button_empty_red.png", "dock_btn_red.png"):
		r.save(FARM / dst)

	saved["btn-close-x"].save(UI / "close.png")
	saved["icon-mail"].save(UI / "mail.png")
	saved["icon-gear"].save(FARM / "settings_gear.png")
	saved["bubble-action"].save(FARM / "thought_bubble.png")
	saved["icon-coin-chick"].save(FARM / "icon_coin.png")
	saved["icon-egg"].save(FARM / "icon_egg.png")
	saved["icon-chick"].save(FARM / "icon_chick.png")
	saved["icon-cake"].save(FARM / "icon_cake.png")

	pad_square(saved["icon-coin-chick"]).save(ICONS / "coin.png")
	pad_square(saved["icon-egg"]).save(ICONS / "egg.png")
	pad_square(saved["icon-cake"]).save(ICONS / "cake.png")
	pad_square(saved["icon-chick"]).save(ICONS / "chick.png")
	pad_square(saved["icon-hen"]).save(ICONS / "hen.png")
	pad_square(saved["icon-arrow-up"]).save(ICONS / "stock.png")
	pad_square(saved["pip-empty"], 232).save(SETTLE / "23-pip-empty.png")
	pad_square(saved["pip-filled-gold"], 232).save(SETTLE / "24-pip-hit.png")
	pad_square(saved["pip-filled-gold"], 232).save(SETTLE / "25-pip-now.png")

	print("FINAL panel", edge_max(panel), "green", edge_max(g), "egg", edge_max(saved["icon-egg"]))


if __name__ == "__main__":
	main()
