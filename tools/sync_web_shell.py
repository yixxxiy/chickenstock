"""把 web/ 下的统计外壳文件同步到 export/web/。

为什么需要这一步：
- `export/web/*` 在 .gitignore 里被排除，那里是部署产物目录，不是源码目录。
- Godot 导出只会覆盖 index.html / .js / .wasm / .pck，不会动我们自己放的文件，
  但也不会帮我们创建它们。
- 所以源文件留在 web/（进仓库、可 diff），每次导出后同步一次。

用法（导出之后、拖去 Netlify 之前）：

    python tools/sync_web_shell.py

已存在的 export/web/posthog-config.js 不会被覆盖——那份里填着线上 token。
"""

import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "web"
DST = ROOT / "export" / "web"

# (文件名, 已存在时是否覆盖)
FILES = [
    ("analytics.js", True),
    ("notice.js", True),
    ("posthog-config.js", False),
]


def main() -> int:
    if not DST.exists():
        print(f"没有找到 {DST}，先在 Godot 里导出一次 Web 版。")
        return 1

    for name, overwrite in FILES:
        src = SRC / name
        dst = DST / name
        if not src.exists():
            print(f"缺少源文件 {src}")
            return 1
        if dst.exists() and not overwrite:
            print(f"跳过 {name}（已存在，里面可能填着线上 token）")
            continue
        shutil.copy2(src, dst)
        print(f"已同步 {name}")

    index = DST / "index.html"
    if index.exists():
        html = index.read_text(encoding="utf-8", errors="replace")
        for name, _ in FILES:
            if name not in html:
                print(f"警告：index.html 里没有引用 {name}，检查 export_presets.cfg 的 head_include")
    else:
        print("警告：export/web/index.html 不存在，这次导出没成功")

    for guard in ("_headers", "netlify.toml"):
        if not (DST / guard).exists():
            print(f"警告：{guard} 不在 export/web 里，从仓库根目录拷回去（AGENTS.md 要求）")

    return 0


if __name__ == "__main__":
    sys.exit(main())
