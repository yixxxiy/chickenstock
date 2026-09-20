# Check every player-facing string against game_zh.ttf cmap.
from __future__ import annotations

import re
from pathlib import Path

from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parents[1]
FONT = ROOT / "fonts" / "game_zh_full.otf"


def gd_unescape(s: str) -> str:
	return (
		s.replace(r"\n", "\n")
		.replace(r"\t", "\t")
		.replace(r"\"", '"')
		.replace(r"\\", "\\")
	)


def quoted(text: str) -> list[str]:
	return [gd_unescape(m) for m in re.findall(r'"((?:\\.|[^"\\])*)"', text)]


def is_checked(ch: str) -> bool:
	return ord(ch) >= 32


def scan(paths: list[Path], cmap: dict) -> dict[str, set[str]]:
	hits: dict[str, set[str]] = {}

	def add(src: str, text: str) -> None:
		for ch in text:
			if not is_checked(ch):
				continue
			if ord(ch) not in cmap:
				hits.setdefault(ch, set()).add(src)

	for p in paths:
		if not p.exists():
			continue
		body = p.read_text(encoding="utf-8", errors="ignore")
		rel = str(p.relative_to(ROOT)).replace("\\", "/")
		if p.suffix == ".tscn":
			for m in re.finditer(r'^text = "((?:\\.|[^"\\])*)"', body, re.M):
				add(rel + ":text", gd_unescape(m.group(1)))
			# multiline oven / label blocks
			for m in re.finditer(r'^text = "([\s\S]*?)"\n', body, re.M):
				add(rel + ":text", gd_unescape(m.group(1)))
		elif p.name == "project.godot":
			for m in re.finditer(r'config/name="([^"]+)"', body):
				add(rel, m.group(1))
		else:
			for s in quoted(body):
				add(rel, s)
	return hits


def main() -> None:
	cmap = TTFont(FONT).getBestCmap()
	play = [
		ROOT / "scripts" / "Loc.gd",
		ROOT / "scripts" / "Game.gd",
		ROOT / "scripts" / "SettlementCard.gd",
		ROOT / "scenes" / "Game.tscn",
		ROOT / "scenes" / "SettlementCard.tscn",
		ROOT / "project.godot",
	]
	editor = [
		ROOT / "scripts" / "AssetGallery.gd",
		ROOT / "scripts" / "ArtScene.gd",
		ROOT / "scripts" / "SettlementPreview.gd",
		ROOT / "scenes" / "ArtScene.tscn",
		ROOT / "scenes" / "SettlementPreview.tscn",
		ROOT / "icons_preview.tscn",
	]
	# runtime-only glyphs used in formatting
	extra = "×%/.,:;@+-*=·—…「」『』（）【】《》￥％▲▼→←↑↓＋－＝／"
	extra += "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz "

	print(f"font glyphs: {len(cmap)}  ({FONT.stat().st_size} bytes)")

	play_hits = scan(play, cmap)
	for ch in extra:
		if is_checked(ch) and ord(ch) not in cmap:
			play_hits.setdefault(ch, set()).add("runtime")

	if not play_hits:
		print("PLAYABLE: OK — every character is in game_zh_full.otf")
	else:
		print(f"PLAYABLE MISSING: {len(play_hits)}")
		for ch in sorted(play_hits, key=ord):
			srcs = ", ".join(sorted(play_hits[ch]))
			print(f"  U+{ord(ch):04X} [{ch}]  {srcs}")

	ed_hits = scan(editor, cmap)
	if not ed_hits:
		print("EDITOR: OK")
	else:
		print(f"EDITOR MISSING: {len(ed_hits)}")
		for ch in sorted(ed_hits, key=ord):
			srcs = ", ".join(sorted(ed_hits[ch]))
			print(f"  U+{ord(ch):04X} [{ch}]  {srcs}")


if __name__ == "__main__":
	main()
