# 小鸡股市 — Agent 说明

Godot 4.7 竖屏农场/股市游戏。视口 **576×1024**。主场景 `res://scenes/Game.tscn`，逻辑几乎都在 `scripts/Game.gd`。设计者是太阳海：直接改代码，手机网页才算验收。

## 角色

- **实现**：按截图和一句完成标准改。不要顺手加无关功能。
- **质检**（另开聊天）：只读 diff，对照本文否决。不改画、不调手感、不重写文案。
- **品味**：字号、贴边、声音腻不腻、卡好不好看，留给太阳海。不确定就列出手机上要点哪几下，而不是猜。

## 层级（禁止为了「能点到」而抬底栏）

`_raise_hud_chrome()` / `_set_settle_chrome()` 是权威：

| 节点 | z |
| --- | --- |
| Dock | 8 |
| 场景按钮（WORLD_FRONT 一类） | 21 |
| HUD（金币/时钟，不含信封） | 40 |
| Night 结算 | 100 |
| QuestPop / SettingsPop | 110 / 115 |
| 信封 QuestBtn、设置按钮 | 120 |
| SurveyPop / TrophyPop | 125 |
| GuidePop（新手指南，整屏模态，刻意盖住信封） | 126 |
| StartMenuLayer | 500 |
| Toasts（成就解锁盖住主菜单 logo；mouse_filter 忽略，不挡点击） | 510 |

结算时：`Dock` 必须 **隐藏** 且 z 保持 8。不要把 Dock 抬到 Night 上面。信封在结算期间仍可打开，这是刻意的，不是 bug。

**运行时 `add_child` 进来的 Control 要用 `set_anchors_and_offsets_preset`**，不能只用
`set_anchors_preset`——后者只改锚点不重排，节点尺寸会一直停在 0×0。问卷卡因此空了很久：
弹是弹出来了，遮罩没了、卡片塌成一条、题目一道看不见，看起来像「根本没弹」。

**主菜单（500）压在设置 / 奖杯页 / 问卷之上**，所以要在菜单上开那些弹层，必须先
`start_menu.visible = false`，关掉后用 `_restore_menu_if_needed()` 放回来。
抬设置或问卷的 z 去盖菜单是错的。**Toasts 是例外**：z=510，成就提示要盖住 logo。

## 手机点击（最常见的假 bug）

`project.godot` 开了 `emulate_touch_from_mouse`。`Game._input` 会给 `BaseButton` 合成 `pressed`，GUI 触摸还会再打一次。开关类（信封、语言、音效）看起来像「点一下立刻关 / 切两次」。

已有补丁，改点击时不要拆掉：

- 命中按钮时吞掉多余的 `InputEventScreenTouch`
- 信封 `_toggle_quest`、`Loc.toggle()` 约 280ms 防抖
- 打开邮件后 `_quest_ignore_close`，避免 Dim 立刻关掉
- 设置 Dim 点到设置内按钮时不要关面板

新做开关按钮：同样要防抖 + 吞 ScreenTouch，不要只绑 `pressed`。

## 世界层

`WORLD_BACK` / `WORLD_FRONT` 决定谁跟着地图缩放。烤炉升级、狼摊、思想气泡在 FRONT。改父节点或 z 时，确认缩放和点击还在。

## 容易回归的逻辑

- 烤蛋糕：`< 100` 才涨进度；`>= 100` 再持有约 0.7s 后重置。持有不要写进「还没烤完」分支，否则第一次之后会卡死。
- 鸡经过狼/建筑用 `GHOST_MAT` 变淡，遮挡矩形含放大后的 `wolf_hit`。不要改成整只隐藏。
- 文案走 `Loc.gd`。手机缺字时靠 `_ensure_cjk_fallback()`，不要只塞一个 TTF。
- 音效：`Sfx` 里鸡叫 ≠ 母鸡；环境音独立开关 `amb_on`。不要为了「有声音」把环境音和音效绑死。

## 改完自检（实现 agent 在回复里列出）

按改动勾，不要假装已经真机测过：

1. 点信封：打开后不立刻关；结算时仍能开。
2. 点语言：只切一次；按钮为 `语言：中文` / `Language: English`。
3. 进结算：底栏消失，不挡报告 CTA。
4. 若动了烤炉：烤到 100% 能结束并重置。
5. 若动了层级或 Dock：结算层仍在底栏之上。

## 质检开场白（另开聊天粘贴）

```
只当质检。读 AGENTS.md 和这次 diff。只回答违反了哪条（层级 / 双击 / 结算挡按钮 / 烤炉卡死）。不要改代码，不要评价画风。
```

## 美术资产生成 SOP

画风、要不要用，只归太阳海。Agent 负责按参考图生成、抠透明、切片进正确目录，不要顺手改运行时布局。

```
截图 / 一句「要什么」
        ↓
GenerateImage：透明底、无框无字、一件一文件（动画才用图集）
        ↓
PIL 验 alpha；白底 / 棋盘格 / 羊皮纸底一律抠掉
        ↓
落盘到对应目录，Godot 刷新
        ↓
AssetGallery / ArtScene / 手机网页上看成片
```

### 禁区（已经踩过）

- **不要把底、框、字烤进贴图。** Godot 没法单独改。字走 `Loc.gd`，框用九宫或代码 StyleBox。
- **一张图一个物件。** 图标不要 3×3 图集（除非明确是动画条）。动画条才用等宽格子 + 同一脚底线。
- **提示词必须写死透明。** `TRUE transparent PNG, no checkerboard, no white/beige fill, no parchment, no wooden frame, no baked text`。模型经常给出白底 RGB，生成后必须验通道。
- **不要改画风。** 参考现有农场手绘：暖色、软体积、左上光、不要粗描边、不要贴纸白边。
- 生图默认进 `generated-v2/`，**定稿后再拷到运行时路径**。未接线的草图不要覆盖 `button_green.png` 这类正在用的文件。

### 落盘路径

| 类型 | 目录 | 说明 |
| --- | --- | --- |
| 运行时小图标 | `icons/` | 金币、走势、蛋、蛋糕、鸡、涨跌。透明、无字、无框。 |
| HUD / 按钮 / 底栏 | `assets/ui/farm-ui/` | 九宫框、木按钮、气泡。底栏打包见 `tools/_pack_dock_ui.py`。 |
| 生图草稿 | `assets/ui/farm-ui/generated-v2/` | 只存源图，不直接给 Game 用。 |
| 结算分层 | `assets/ui/settlement/layers/` | 编号图层，`00-moon` … `25-pip-now`。打包：`assets/ui/settlement/_pack_layers.py`。 |
| 结算对版 | `assets/ui/settlement/mockups/` | 给 `SettlementPreview.tscn` 看，不进主场景。 |
| 角色动画 | `assets/sprites/` | 等宽 8 帧。脚底对齐用 `tools/recut_chick_sheets.py` / `recut_hen_sheets.py`。 |
| 地图 | `assets/map/` | 整张底图，不要切成碎建筑再拼。 |

### 生成后必做

1. 用 Pillow 读 `mode` 和四角像素。不是 RGBA、或四角是白/米色 → 洪水抠底（结算脚本已有 `knockout`；底栏用品红/黑键）。
2. 动画条：格子必须是整数像素；同一条里身体高度、脚底 y 一致。不要「看起来对齐」就过。
3. 对版场景：总览 `scenes/AssetGallery.tscn`；主界面拼板 `scenes/ArtScene.tscn`；结算 `scenes/SettlementPreview.tscn`（`1` 日结，`2` 通关，`3` 翻车）。
4. 接到 `Game.tscn` / `SheetSprite` 时核对 `columns` / `rows` / `frame_count`。改图集尺寸后旧 region 会错位。
5. 太阳海在**手机网页**上看成片，不在编辑器里定稿。

### 对 agent 说什么

```
按这张参考图生成【表盘】。透明底，不要框不要字。放到 assets/ui/clock-face.png。生成后验 alpha，白底要抠掉。
```

## Deploy SOP

完成标准是手机打开 **https://chickenstock.netlify.app**，不是编辑器、也不是本机 html。Godot 工程不能直接丢到 Netlify。

```
脚本无红字
        ↓
Godot：项目 → 导出 → Web → 导出项目
        ↓
确认 export/web 里有 index.html / .wasm / .pck，以及 netlify.toml、_headers
（预设已排除草稿和对版资源，不要清空排除项）
        ↓
node tools/web-sync.mjs
（同步 web/analytics.js 并检查这一包能不能传；缺了它统计会静默停用，游戏照常跑）
        ↓
整包覆盖上传到站点 chickenstock
        ↓
手机打开 chickenstock.netlify.app，强制刷新后再玩一局
```

### 导出

- 引擎 **Godot 4.7.1**，预设 **Web**，输出 `export/web/index.html`。
- **单线程**：`variant/thread_support=false`。不要开 Threads。模板是 `web_nothreads_debug.zip` / `web_nothreads_release.zip`，装在 `%APPDATA%\Godot\export_templates\4.7.1.stable\`。
- 导出窗口空或报缺模板：先 **管理导出模板**，只下 Web 单线程，不用下全套。
- **有脚本红字先别导。** 类型错误会卡住导出。
- 网页渲染会走 Compatibility / WebGL2，项目里的 Forward Plus 不影响导出。
- `export/` 有 `.gdignore`，不要删，否则导出会被再导入工程。

### 上传

手动拖拽（常用）：

1. [app.netlify.com](https://app.netlify.com) → 站点 **chickenstock**
2. **Deploys → 把整个 `export/web` 文件夹拖进去**（不要只拖 `index.html`）
3. 等 Production Published

Git 连接时发布目录是 `export/web`（根目录 `netlify.toml` 的 `publish`）。没有 git 远程时不要走这条。

上传需要已登录的 Netlify 账号。匿名 API 会 401。覆盖同一站点，不要每次新建 site。

### 统计

事件字典和接入结构在 `docs/ANALYTICS.md`，只有那一份口径。三件事别踩：

- **每次发布改 `project.godot` 的 `config/version`。** 事件的 `build` 取自那里，
  不改的话两个版本的数据混在一起没法比。
- `export/web/posthog-config.js` 填线上 token（该目录已被 .gitignore 排除）。
  留空时统计静默停用，游戏照常跑，不会报错。
- 改动收蛋/卖蛋糕这类函数时，计数放在**真实成功路径**上。
  `quiet` 参数不能用来区分测试调用——长按连点走的也是 `quiet = true`。

### 请求头（不要删）

`export/web/netlify.toml` 和 `_headers` 必须和 `index.html` 同级。Godot 再导出可能冲掉它们，导完检查还在；不在就从仓库根目录的 `netlify.toml` 拷回去。

```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
*.wasm → Content-Type: application/wasm
```

### 上线后

1. 打开 https://chickenstock.netlify.app ，**Ctrl+F5**（浏览器会缓存旧 `.pck`）。
2. `index.pck` 的体积应和刚导出的本地文件一致，否则还是旧包。
3. 手机网页玩一局：信封、语言、进结算。编辑器通过不算发布完成。
