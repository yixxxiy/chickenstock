# Slice the black-background UI sheet, knock out black, install runtime copies.
from collections import deque
from pathlib import Path
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SRC = Path(
    r"C:\Users\CYX\.cursor\projects\c-Users-CYX-OneDrive\assets"
    r"\c__Users_CYX_AppData_Roaming_Cursor_User_workspaceStorage_"
    r"ff936e3d8b1761b23622981fdf0ff024_images_exec-eb3c1d48-b903-4b9e-9242-4624adf95750-3cbf63f6-870e-4fd7-97d8-0e42c5239957.jpg"
)
GEN = ROOT / "assets/ui/farm-ui/generated-v2/kit-sheet-v3"
NAMED = GEN / "named"
SIMPLE = ROOT / "assets/ui/farm-ui/simple-ui"
FARM = ROOT / "assets/ui/farm-ui"
UI = ROOT / "assets/ui"
ICONS = ROOT / "icons"

NAMES = [
    "icon-coin-chick",
    "icon-arrow-up",
    "icon-arrow-down",
    "icon-egg",
    "icon-egg-cracked",
    "icon-chick",
    "icon-hen",
    "icon-cake",
    "icon-mail",
    "icon-gear",
    "icon-trophy",
    "icon-sun",
    "icon-moon",
    "icon-clock",
    "icon-lock",
    "icon-coop",
    "btn-green-wide",
    "btn-green-wide-b",
    "btn-gray-wide",
    "btn-beige-wide",
    "btn-beige-wide-b",
    "btn-red-wide",
    "chip-toggle-on",
    "chip-toggle-off",
    "seal-check-green",
    "seal-x-red",
    "icon-x",
    "icon-chevron",
    "bar-progress-fill",
    "bar-progress-track",
    "panel-tall",
    "panel-medium",
    "bubble-speech",
    "deco-flourish",
]


def knockout_black(im: Image.Image) -> Image.Image:
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()
    seen = bytearray(w * h)
    q = deque()

    def is_bg(c) -> bool:
        r, g, b, _a = c
        return (r + g + b) / 3.0 < 22

    def push(x: int, y: int) -> None:
        i = y * w + x
        if seen[i] or not is_bg(px[x, y]):
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
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a and (r + g + b) / 3.0 < 14:
                px[x, y] = (0, 0, 0, 0)
    return im


def components(im: Image.Image, min_px: int = 80) -> list[tuple[int, int, int, int]]:
    w, h = im.size
    px = im.load()
    lab = [-1] * (w * h)
    boxes: list[tuple[int, int, int, int, int]] = []
    n = 0
    for y in range(h):
        for x in range(w):
            i = y * w + x
            if lab[i] >= 0 or px[x, y][3] < 24:
                continue
            q = deque([(x, y)])
            lab[i] = n
            minx = maxx = x
            miny = maxy = y
            cnt = 0
            while q:
                cx, cy = q.popleft()
                cnt += 1
                for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
                    if nx < 0 or ny < 0 or nx >= w or ny >= h:
                        continue
                    j = ny * w + nx
                    if lab[j] >= 0 or px[nx, ny][3] < 24:
                        continue
                    lab[j] = n
                    q.append((nx, ny))
                    minx = min(minx, nx)
                    maxx = max(maxx, nx)
                    miny = min(miny, ny)
                    maxy = max(maxy, ny)
            if cnt >= min_px:
                boxes.append((minx, miny, maxx, maxy, cnt))
            n += 1
    return merge_boxes(boxes, gap=22)


def merge_boxes(boxes: list[tuple[int, int, int, int, int]], gap: int) -> list[tuple[int, int, int, int]]:
    # Do not union neighboring buttons (they sit ~12px apart).
    # Only glue tiny fragments (chart bars, flourish leaves) onto a host.
    hosts: list[list[int]] = []
    crumbs: list[list[int]] = []
    for b in boxes:
        x0, y0, x1, y1, c = b
        w, h = x1 - x0 + 1, y1 - y0 + 1
        if c >= 2500 or (w >= 70 and h >= 50):
            hosts.append(list(b))
        else:
            crumbs.append(list(b))

    def dist(a: list[int], b: list[int]) -> int:
        ax0, ay0, ax1, ay1, _ = a
        bx0, by0, bx1, by1, _ = b
        dx = 0 if ax1 >= bx0 and bx1 >= ax0 else min(abs(ax1 - bx0), abs(bx1 - ax0))
        dy = 0 if ay1 >= by0 and by1 >= ay0 else min(abs(ay1 - by0), abs(by1 - ay0))
        return max(dx, dy)

    leftover: list[list[int]] = []
    for crumb in crumbs:
        best_i = -1
        best_d = 10**9
        for i, host in enumerate(hosts):
            d = dist(crumb, host)
            if d < best_d:
                best_d = d
                best_i = i
        if best_i >= 0 and best_d <= 18:
            h = hosts[best_i]
            ox = max(0, min(h[2], crumb[2]) - max(h[0], crumb[0]) + 1)
            oy = max(0, min(h[3], crumb[3]) - max(h[1], crumb[1]) + 1)
            cw = crumb[2] - crumb[0] + 1
            # Same-row siblings (two progress bars) must stay split.
            if ox == 0 and oy > 0 and cw >= 40:
                leftover.append(crumb)
                continue
            h[0] = min(h[0], crumb[0])
            h[1] = min(h[1], crumb[1])
            h[2] = max(h[2], crumb[2])
            h[3] = max(h[3], crumb[3])
            h[4] += crumb[4]
        else:
            leftover.append(crumb)
    all_boxes = hosts + leftover
    # Flourish row: hairline + leaves sit far apart.
    flourish = [b for b in all_boxes if b[1] >= 930]
    rest = [b for b in all_boxes if b[1] < 930]
    if flourish:
        x0 = min(b[0] for b in flourish)
        y0 = min(b[1] for b in flourish)
        x1 = max(b[2] for b in flourish)
        y1 = max(b[3] for b in flourish)
        rest.append([x0, y0, x1, y1, sum(b[4] for b in flourish)])
    return [(a[0], a[1], a[2], a[3]) for a in rest]


def tight_crop(im: Image.Image, box: tuple[int, int, int, int], pad: int = 2) -> Image.Image:
    w, h = im.size
    x0, y0, x1, y1 = box
    x0 = max(0, x0 - pad)
    y0 = max(0, y0 - pad)
    x1 = min(w - 1, x1 + pad)
    y1 = min(h - 1, y1 + pad)
    crop = im.crop((x0, y0, x1 + 1, y1 + 1))
    a = crop.getchannel("A").point(lambda v: 255 if v > 20 else 0)
    bb = a.getbbox()
    if bb is None:
        return crop
    return crop.crop(bb)


def pad_square(im: Image.Image, size: int = 256) -> Image.Image:
    w0, h0 = im.size
    scale = min(size / w0, size / h0) * 0.92
    nw, nh = max(1, int(w0 * scale)), max(1, int(h0 * scale))
    resized = im.resize((nw, nh), Image.Resampling.LANCZOS)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(resized, ((size - nw) // 2, (size - nh) // 2), resized)
    return out


def sort_reading_order(boxes: list[tuple[int, int, int, int]]) -> list[tuple[int, int, int, int]]:
    rows: list[list[tuple[int, int, int, int]]] = []
    for b in sorted(boxes, key=lambda t: (t[1] + t[3]) / 2):
        cy = (b[1] + b[3]) / 2
        placed = False
        for row in rows:
            rcy = sum((x[1] + x[3]) / 2 for x in row) / len(row)
            if abs(cy - rcy) < 70:
                row.append(b)
                placed = True
                break
        if not placed:
            rows.append([b])
    ordered: list[tuple[int, int, int, int]] = []
    for row in rows:
        ordered.extend(sorted(row, key=lambda t: t[0]))
    return ordered


def copy(im: Image.Image, *paths: Path) -> None:
    for path in paths:
        path.parent.mkdir(parents=True, exist_ok=True)
        im.save(path)


def fit_height(im: Image.Image, height: int) -> Image.Image:
    w0, h0 = im.size
    width = max(1, round(w0 * height / h0))
    return im.resize((width, height), Image.Resampling.LANCZOS)


def scale2(im: Image.Image) -> Image.Image:
    w, h = im.size
    return im.resize((w * 2, h * 2), Image.Resampling.LANCZOS)


def main() -> None:
    NAMED.mkdir(parents=True, exist_ok=True)
    sheet = knockout_black(Image.open(SRC))
    sheet.save(GEN / "ui-kit-sheet.png")
    boxes = sort_reading_order(components(sheet))
    print("pieces", len(boxes))
    for i, b in enumerate(boxes):
        print(i, NAMES[i] if i < len(NAMES) else "?", b[2] - b[0] + 1, b[3] - b[1] + 1, b)
    if len(boxes) != len(NAMES):
        raise SystemExit(f"expected {len(NAMES)} pieces, got {len(boxes)}")
    saved: dict[str, Image.Image] = {}
    for name, box in zip(NAMES, boxes):
        im = tight_crop(sheet, box)
        saved[name] = im
        im.save(NAMED / f"{name}.png")

    g = fit_height(saved["btn-green-wide"], 64)
    b = fit_height(saved["btn-beige-wide"], 64)
    r = fit_height(saved["btn-red-wide"], 64)
    panel = scale2(saved["panel-tall"])
    medium = scale2(saved["panel-medium"])
    speech = scale2(saved["bubble-speech"])
    chip_on = fit_height(saved["chip-toggle-on"], 44)
    chip_off = fit_height(saved["chip-toggle-off"], 44)
    close = pad_square(saved["seal-x-red"], 128)
    copy(panel, SIMPLE / "panel.png", FARM / "frame_tall_9slice.png", FARM / "frame_tall.png")
    copy(g, SIMPLE / "button-green.png", FARM / "button_green.png", FARM / "button_empty_green.png", FARM / "dock_btn_green.png", FARM / "dock_btn_green_wide.png")
    copy(b, SIMPLE / "button-beige.png", FARM / "button_empty_beige.png", FARM / "button_neutral.png")
    copy(r, SIMPLE / "button-red.png", FARM / "button_red.png", FARM / "button_empty_red.png", FARM / "dock_btn_red.png")
    copy(chip_off, SIMPLE / "tag.png", SIMPLE / "chip-off.png")
    copy(chip_on, SIMPLE / "chip-on.png")
    copy(scale2(saved["deco-flourish"]), SIMPLE / "flourish.png")
    copy(saved["icon-mail"], UI / "mail.png")
    copy(saved["icon-gear"], FARM / "settings_gear.png")
    copy(speech, FARM / "speech.png", FARM / "thought_bubble.png")
    copy(saved["icon-coin-chick"], FARM / "icon_coin.png")
    copy(saved["icon-egg"], FARM / "icon_egg.png")
    copy(saved["icon-chick"], FARM / "icon_chick.png")
    copy(saved["icon-cake"], FARM / "icon_cake.png")
    copy(saved["seal-check-green"], ICONS / "check.png")
    copy(pad_square(saved["icon-coin-chick"]), ICONS / "coin.png")
    copy(pad_square(saved["icon-egg"]), ICONS / "egg.png")
    copy(pad_square(saved["icon-cake"]), ICONS / "cake.png")
    copy(pad_square(saved["icon-chick"]), ICONS / "chick.png")
    copy(pad_square(saved["icon-hen"]), ICONS / "hen.png", ICONS / "flock.png")
    copy(pad_square(saved["icon-arrow-up"]), ICONS / "stock.png", ICONS / "price_up.png")
    copy(pad_square(saved["icon-arrow-down"]), ICONS / "price_down.png")
    copy(pad_square(saved["icon-trophy"]), ICONS / "trophy.png")
    copy(pad_square(saved["icon-gear"]), ICONS / "settings.png")
    copy(pad_square(saved["icon-egg-cracked"]), ICONS / "rotten_egg.png")
    copy(pad_square(saved["icon-sun"]), ICONS / "sun.png")
    copy(pad_square(saved["icon-moon"]), ICONS / "moon.png")
    copy(pad_square(saved["icon-clock"]), ICONS / "clock.png")
    copy(close, UI / "close.png")
    settle = ROOT / "assets/ui/settlement/kit"
    copy(panel, settle / "01-panel-tall-modal.png")
    copy(medium, settle / "04-chip-value-slot.png", settle / "05-panel-stats-card.png")
    copy(g, settle / "09-btn-green-wide.png")
    copy(b, settle / "10-btn-beige-wide.png")
    copy(r, settle / "11-btn-red-wide.png")
    copy(saved["deco-flourish"], settle / "06-hairline-separator.png", settle / "07-deco-flourish.png")
    copy(saved["icon-coin-chick"], settle / "23-icon-coin-chick.png")
    copy(saved["icon-arrow-up"], settle / "24-icon-arrow-up.png")
    copy(saved["icon-egg"], settle / "28-icon-egg.png")
    copy(saved["icon-chick"], settle / "29-icon-chick.png")
    copy(saved["icon-hen"], settle / "30-icon-hen.png")
    copy(saved["icon-cake"], settle / "32-icon-cake.png")
    copy(saved["icon-egg-cracked"], settle / "33-icon-egg-cracked.png")
    print("installed", len(saved), "named slices")


if __name__ == "__main__":
    main()
