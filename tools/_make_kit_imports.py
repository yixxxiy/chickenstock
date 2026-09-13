# -*- coding: utf-8 -*-
from pathlib import Path
import hashlib

root = Path(__file__).resolve().parents[1]
kit = root / "assets" / "ui" / "settlement" / "kit"
template = """[remap]

importer=\"texture\"
type=\"CompressedTexture2D\"
uid=\"uid://kit{uid}\"
path=\"res://.godot/imported/{dest}\"
metadata={{
\"vram_texture\": false
}}

[deps]

source_file=\"res://assets/ui/settlement/kit/{name}\"
dest_files=[\"res://.godot/imported/{dest}\"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=\"\"
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
"""
for png in sorted(kit.glob("*.png")):
    src = f"res://assets/ui/settlement/kit/{png.name}"
    h = hashlib.md5(src.encode()).hexdigest()
    dest = f"{png.name}-{h}.ctex"
    (kit / f"{png.name}.import").write_text(
        template.format(uid=h[:12], dest=dest, name=png.name), encoding="utf-8"
    )
    print(png.name)
print("imports", len(list(kit.glob("*.import"))))
