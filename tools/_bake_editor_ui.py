# One-shot: write current runtime layout fractions into Game.tscn.
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TSCN = ROOT / "scenes" / "Game.tscn"

# (parent, name) -> (l, t, r, b, extra_offsets dict)
LAYOUTS = {
    ("StartMenuLayer", "Card"): (0.17, 0.08, 0.83, 0.75, {}),
    ("StartMenuLayer/Card", "Box"): (0.0, 0.0, 1.0, 1.0, {}),
    ("StartMenuLayer/Card/Box", "LogoIcon"): (0.28, -0.02, 0.72, 0.22, {}),
    ("StartMenuLayer/Card/Box", "LogoWordmark"): (0.04, 0.22, 0.96, 0.38, {}),
    ("StartMenuLayer/Card/Box", "Direct"): (0.07, 0.40, 0.93, 0.51, {}),
    ("StartMenuLayer/Card/Box", "Tutorial"): (0.07, 0.515, 0.93, 0.61, {}),
    ("StartMenuLayer/Card/Box", "Challenge"): (0.07, 0.615, 0.93, 0.71, {}),
    ("StartMenuLayer/Card/Box", "Endless"): (0.07, 0.715, 0.93, 0.81, {}),
    ("StartMenuLayer/Card/Box", "Settings"): (0.07, 0.855, 0.485, 0.96, {}),
    ("StartMenuLayer/Card/Box", "Trophies"): (0.515, 0.855, 0.93, 0.96, {}),
    (".", "EggThought"): (0.16, 0.25, 0.29, 0.315, {}),
    (".", "CakeThought"): (0.80, 0.29, 0.93, 0.29, {"offset_bottom": 64.0}),
    (".", "BakeryUpgrade"): (0.70, 0.355, 0.94, 0.397, {}),
    (".", "BakeryEggs"): (0.68, 0.49, 0.96, 0.52, {}),
    (".", "HatchThought"): (0.70, 0.58, 0.82, 0.645, {}),
    (".", "ChickThought"): (0.70, 0.58, 0.82, 0.645, {}),
    (".", "HatchEgg"): (0.70, 0.62, 0.85, 0.72, {}),
    (".", "Toasts"): (0.12, 0.175, 0.88, 0.255, {}),
    ("Night", "Moon"): (0.045, 0.02, 0.225, 0.13, {}),
    ("SettingsPop", "Card"): (0.14, 0.08, 0.86, 0.90, {}),
    ("TrophyPop", "Card"): (0.07, 0.15, 0.93, 0.91, {}),
    ("QuestPop", "Card"): (0.07, 0.17, 0.93, 0.82, {}),
    (".", "TutorialLayer"): (0.0, 0.0, 1.0, 1.0, {}),
    ("TutorialLayer", "Card"): (0.19, 0.48, 0.94, 0.74, {}),
    ("TutorialLayer", "TutorWolf"): (-0.06, 0.47, 0.22, 0.70, {}),
}

# Close X stays a sibling of PanelContainer cards (containers ignore overlay anchors).
# Anchors match each card's top-right so dragging the card in the editor is one group-select.
CLOSE_BY_PARENT = {
    "QuestPop": (0.93, 0.17),
    "SettingsPop": (0.86, 0.08),
    "TrophyPop": (0.93, 0.15),
}

GUIDE_CLOSE = """layout_mode = 1
anchors_preset = 1
anchor_left = 1.0
anchor_top = 0.0
anchor_right = 1.0
anchor_bottom = 0.0
offset_left = -58.0
offset_top = 6.0
offset_right = -6.0
offset_bottom = 58.0
grow_horizontal = 0
"""


def close_layout(ax: float, ay: float) -> str:
    return (
        "layout_mode = 1\n"
        "anchors_preset = -1\n"
        f"anchor_left = {ax}\n"
        f"anchor_top = {ay}\n"
        f"anchor_right = {ax}\n"
        f"anchor_bottom = {ay}\n"
        "offset_left = -58.0\n"
        "offset_top = 6.0\n"
        "offset_right = -6.0\n"
        "offset_bottom = 58.0\n"
        "grow_horizontal = 0\n"
    )


def split_nodes(text: str) -> list[str]:
    parts = []
    start = 0
    idx = text.find("\n[node ")
    if idx < 0:
        return [text]
    parts.append(text[: idx + 1])
    start = idx + 1
    while True:
        nxt = text.find("\n[node ", start)
        if nxt < 0:
            parts.append(text[start:])
            break
        parts.append(text[start : nxt + 1])
        start = nxt + 1
    return parts


def parse_header(block: str) -> tuple[str, str]:
    line = block.splitlines()[0]
    name = ""
    parent = "."
    if 'name="' in line:
        name = line.split('name="', 1)[1].split('"', 1)[0]
    if 'parent="' in line:
        parent = line.split('parent="', 1)[1].split('"', 1)[0]
    return parent, name


def strip_layout(block: str) -> str:
    keys = (
        "layout_mode",
        "anchors_preset",
        "anchor_left",
        "anchor_top",
        "anchor_right",
        "anchor_bottom",
        "offset_left",
        "offset_top",
        "offset_right",
        "offset_bottom",
        "grow_horizontal",
        "grow_vertical",
    )
    out = []
    for line in block.splitlines(True):
        stripped = line.strip()
        if any(stripped.startswith(k + " ") or stripped.startswith(k + "=") for k in keys):
            continue
        out.append(line)
    return "".join(out)


def insert_after_header(block: str, layout: str) -> str:
    lines = block.splitlines(True)
    return lines[0] + layout + "".join(lines[1:])


def main() -> None:
    text = TSCN.read_text(encoding="utf-8")
    blocks = split_nodes(text)
    new_blocks = [blocks[0]]
    for block in blocks[1:]:
        parent, name = parse_header(block)
        key = (parent, name)
        if key in {("QuestPop", "CloseBtn"), ("SettingsPop", "CloseBtn"), ("TrophyPop", "CloseBtn")}:
            ax, ay = CLOSE_BY_PARENT[parent]
            block = strip_layout(block)
            block = insert_after_header(block, close_layout(ax, ay))
        elif key == ("GuidePop", "CloseBtn"):
            block = block.replace('parent="GuidePop"', 'parent="GuidePop/GuideCard"', 1)
            block = strip_layout(block)
            block = insert_after_header(block, GUIDE_CLOSE)
        elif key == ("StartMenuLayer/Card/Box", "Subtitle"):
            if "visible = false" not in block:
                block = insert_after_header(block, "visible = false\n")
        elif key in LAYOUTS:
            l, t, r, b, extra = LAYOUTS[key]
            layout = (
                "layout_mode = 1\n"
                "anchors_preset = -1\n"
                f"anchor_left = {l}\n"
                f"anchor_top = {t}\n"
                f"anchor_right = {r}\n"
                f"anchor_bottom = {b}\n"
                f"offset_left = {extra.get('offset_left', 0.0)}\n"
                f"offset_top = {extra.get('offset_top', 0.0)}\n"
                f"offset_right = {extra.get('offset_right', 0.0)}\n"
                f"offset_bottom = {extra.get('offset_bottom', 0.0)}\n"
            )
            block = strip_layout(block)
            block = insert_after_header(block, layout)
            if name == "LogoIcon":
                block = block.replace("custom_minimum_size = Vector2(0, 80)\n", "custom_minimum_size = Vector2(0, 0)\n")
            if name == "LogoWordmark":
                block = block.replace("custom_minimum_size = Vector2(0, 60)\n", "custom_minimum_size = Vector2(0, 0)\n")
            if name == "TutorWolf":
                block = block.replace("scale = Vector2(2, 2)\n", "scale = Vector2(1, 1)\n")
            if name == "BakeryUpgrade":
                block = block.replace(
                    "theme_override_font_sizes/font_size = 27\n",
                    "theme_override_font_sizes/font_size = 15\n",
                )
            if name in ("Direct", "Tutorial", "Challenge", "Endless"):
                if "clip_text" not in block:
                    block = block.rstrip() + "\nclip_text = true\nautowrap_mode = 3\n\n"
            if name in ("Settings", "Trophies"):
                if "clip_text" not in block:
                    block = block.rstrip() + "\nclip_text = true\n\n"
        new_blocks.append(block)
    text = "".join(new_blocks)
    marker = '[node name="LogoIcon" type="TextureRect" parent="StartMenuLayer/Card/Box"'
    surface = """[node name="MenuSurface" type="Panel" parent="StartMenuLayer/Card/Box"]
layout_mode = 1
anchors_preset = -1
anchor_left = 0.0
anchor_top = 0.35
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 0.0
offset_top = 0.0
offset_right = 0.0
offset_bottom = 0.0
mouse_filter = 2
theme_override_styles/panel = ExtResource("26_frame_tall")

"""
    if 'name="MenuSurface"' not in text:
        text = text.replace(marker, surface + marker, 1)
    TSCN.write_text(text, encoding="utf-8")
    print("baked", TSCN)


if __name__ == "__main__":
    main()
