# Subset Noto Sans SC (SIL OFL 1.1) to glyphs this game actually uses.
from __future__ import annotations

import re
from pathlib import Path

from fontTools.subset import Options, Subsetter
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

ROOT = Path(__file__).resolve().parents[1]
SRC = Path(__file__).resolve().parent / "_src_NotoSansSC.ttf"
OUT = Path(__file__).resolve().parent / "game_zh.ttf"

EXTRA = (
    "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    " !\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"
    "，。、！？：；·—…「」『』（）【】《》—～￥％"
    "▲▼×→←↑↓＋－＝／"
    "的一是不了人我在有他这中大为上个国说们到时要就出会可也你对生能而子那得于着下自之年过发后作里用道地"
    "晚间报告语言账目"
)

SKIP = {".godot", "export", "fonts", "__pycache__"}


def collect_text() -> str:
    chunks: list[str] = [EXTRA]
    for folder in (ROOT / "scripts", ROOT / "scenes", ROOT / "themes"):
        if not folder.exists():
            continue
        for path in folder.rglob("*"):
            if path.suffix.lower() not in {".gd", ".tscn", ".godot", ".txt"}:
                continue
            chunks.append(path.read_text(encoding="utf-8", errors="ignore"))
    chunks.append((ROOT / "project.godot").read_text(encoding="utf-8", errors="ignore"))
    return "".join(chunks)


def main() -> None:
    chars = "".join(sorted(set(collect_text())))
    print(f"unique chars: {len(chars)}")
    font = TTFont(SRC)
    if "fvar" in font:
        font = instantiateVariableFont(font, {"wght": 700}, inplace=False)
    tmp = Path(__file__).resolve().parent / "_bold_instance.ttf"
    font.save(tmp)
    opts = Options()
    opts.layout_features = ["*"]
    opts.glyph_names = True
    opts.legacy_cmap = True
    opts.notdef_glyph = True
    opts.notdef_outline = True
    opts.recommended_glyphs = True
    opts.name_IDs = ["*"]
    opts.name_legacy = True
    opts.name_languages = ["*"]
    opts.drop_tables = ["DSIG"]
    sub = Subsetter(options=opts)
    sub.populate(text=chars)
    baked = TTFont(tmp)
    sub.subset(baked)
    baked.save(OUT)
    tmp.unlink(missing_ok=True)
    print(f"wrote {OUT} ({OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
