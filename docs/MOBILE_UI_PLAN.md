# 手机 / 小游戏渠道 UI 适配计划

适用范围：Godot 4.7.1，主场景 `res://scenes/Game.tscn`，基准画布 576×1024。

本计划**只写计划，不含改动**。目标渠道尚未确定，因此按「主流苹果 + 安卓机型」做通用适配，渠道专属部分单独隔离在 R3。

基线：`main` @ `d9a2566`，工作区干净，`LayerSmokeTest` / `TutorialSmokeTest` 均通过。所有数字为 2026-09-05 用 Godot 4.7.1 headless 加载真实 `Game.tscn` 实测，不是估算。

---

## 0. 这份计划解决什么

| 解决 | 不解决 |
| --- | --- |
| 现代手机上下 18–20% 黑边 | 美术风格、画面内容 |
| 触控目标实际只有 26–33pt | 玩法数值、无尽模式逻辑（见 `ENDLESS_MODE_PLAN.md`） |
| 最小字号实际只有 6.9pt | 文案含义 |
| 工程里完全没有安全区概念 | 层级 z 值、双击防抖、结算遮挡（`AGENTS.md` 红线） |
| 渠道胶囊按钮压住右上角功能键 | 包体大小（列为阻塞项，但不在本计划范围内解决） |

排版改动仍然受 [`UI_LAYOUT_WORKFLOW.md`](UI_LAYOUT_WORKFLOW.md) 第 3 节功能冻结红线约束。本计划新增的**唯一**例外：R1 需要动 `project.godot` 的 stretch 设置和新增一个布局容器节点，这超出了原工作流的白名单，必须单独成一次提交、单独过质检。

---

## 1. 事实基线

### 1.1 当前设置

| 设置 | 值 | 来源 |
| --- | --- | --- |
| `display/window/stretch/mode` | `canvas_items` | `project.godot` |
| `display/window/stretch/aspect` | `keep` | **未写在文件里，走引擎默认** |
| 画布 | 576×1024（9:16 = 0.5625） | `project.godot` |
| 朝向 | 竖屏（`handheld/orientation=1`） | `project.godot` |
| `html/canvas_resize_policy` | 2（跟随整个窗口） | `export_presets.cfg:39` |
| `html/head_include` | 空 | `export_presets.cfg:38` |
| 安全区代码 | **零**（`grep safe_area / get_display_safe_area / DisplayServer` 在 `scripts/` 无命中） | — |

### 1.2 主流机型实测（`aspect = keep` 下）

`scale` = 屏宽 ÷ 576，也就是**1 个游戏单位在手机上等于多少 pt**。

| 机型 | CSS 尺寸 | scale | 画面高 | 上下黑边 | 占屏 |
| --- | --- | --- | --- | --- | --- |
| iPhone SE 3 | 375×667 | 0.651 | 667 | 0 | **0%** |
| iPhone 13 mini | 375×812 | 0.651 | 667 | 145 | 17.9% |
| iPhone 14 / 15 | 390×844 | 0.677 | 693 | 151 | 17.9% |
| iPhone 15 / 16 Pro | 393×852 | 0.682 | 699 | 153 | 18.0% |
| iPhone 16 Pro | 402×874 | 0.698 | 715 | 159 | 18.2% |
| iPhone 15 Pro Max | 430×932 | 0.747 | 764 | 168 | 18.0% |
| 安卓中端（大量机型） | 360×800 | **0.625** | 640 | 160 | **20.0%** |
| Pixel 7 Pro 类 | 412×915 | 0.715 | 733 | 183 | 19.9% |

两个要记住的极值：

- **`scale` 最小 = 0.625**（360pt 宽安卓）。所有尺寸换算按这个算最坏情况。
- **iPhone SE 3 是 9:16，黑边为 0**。它没有任何多余垂直空间可用，是 R1 的下限约束。

### 1.3 触控目标实测

44pt 是 iOS HIG 和 Android Material 共同的下限。在 `scale = 0.625` 下，**44pt = 70.4 个游戏单位**。

| 控件 | 单位尺寸 | @0.682 (393) | @0.625 (360) | |
| --- | --- | --- | --- | --- |
| `Dock/Row/Ticker/TradeRow/ShareBuy` `ShareSell` | 90×42 | 28.7pt | **26.3pt** | ❌ |
| `HUD/SettingsBtn` | 48×48 | 32.8pt | **30.0pt** | ❌ |
| `StartMenuLayer/Card/Box/*`（5 个入口） | 220×47 | 32.1pt | **29.4pt** | ❌ |
| `SettingsPop/Card/Col/*` | 高 52–62 | 35–42pt | **32.5–38.8pt** | ❌ |
| `HUD/QuestBtn` | 64×64 | 43.7pt | **40.0pt** | ⚠️ |
| 思想气泡（蛋 / 蛋糕 / 孵化 / 小鸡） | 60–64 | 41–44pt | **37.5–40pt** | ⚠️ |
| `Dock/Row/Day/DayEnd` | 204×182 | 124pt | 114pt | ✅ |
| `Dock/Row/Animals/WolfBuy` `WolfSell` | 146×97 | 66pt | 61pt | ✅ |

注：`HUD/HudBar/*Chip` 高 52 单位看着也偏小，但它们是 `mouse_filter = 2`（纯显示，不可点），不算触控目标。

### 1.4 字号实测

10pt 是中文最小可读下限，在 `scale = 0.625` 下等于 **16 个游戏单位**。

| 字号（单位） | @0.625 | 用在哪 | |
| --- | --- | --- | --- |
| 11 | **6.9pt** | `HUD/HudBar/CashChip/.../CashTitle`、`StockTitle` | ❌ |
| 13 | **8.1pt** | `Dock/Row/Ticker/Face/Col/TickerPrice` `TickerDelta` `TickerHold` | ❌ |
| 14 | 8.8pt | 时钟 `DayLabel`、开始菜单 `Subtitle`、新手指南正文 | ❌ |
| 15 | 9.4pt | `BakeryEggs`、`BakeryUpgrade`、设置页 `HomeBtn` `Restart` `Credits` | ⚠️ |
| 16 | 10.0pt | 思想气泡、股票买卖按钮 | ✅ 刚好 |
| 18+ | 11.3pt+ | 大部分按钮和标题 | ✅ |

`SettlementCard.tscn` 最小 14，同样在线下。

### 1.5 渠道胶囊按钮

`HUD/QuestBtn` 实测在 x 454–518、`HUD/SettingsBtn` 在 x 518–566，y 26–90，正好是微信 / 抖音小游戏胶囊按钮（右上，约 87×32pt）的位置。

**现在不冲突**——`keep` 的黑边把胶囊挡在画布之外了。但 R1 一旦消掉黑边，胶囊立刻压在信封和设置按钮上。这两件事必须一起改，不能只做 R1。

---

## 2. 核心设计决定：世界层和 Chrome 层用两套坐标

问题的根源是一套坐标要同时满足两件互斥的事：

- 农场美术（地图 + 鸡 + 狼摊 + 烤炉 + 思想气泡）必须**严格按 576×1024 对位**，任何拉伸都会让鸡站错地方。
- HUD 和 Dock 应该**贴真实屏幕边缘**，才能吃掉黑边、避开刘海和小白条。

方案：`aspect` 改 `expand`，然后把这两类内容分开。

```
真实视口（576 × 1024~1280，随机型变化）
├─ Bg            铺满真实视口（延续地图的天空色 / 草地色）
├─ WorldFrame    固定 576×1024，垂直居中
│  ├─ WorldBack  （Map / Flock / HatchEgg）
│  └─ WorldFront （思想气泡 / 烤炉升级 / 狼摊 / 教学高亮）
├─ HUD           贴真实上边 + 顶部安全区 + 胶囊预留
└─ Dock          贴真实下边 − 底部安全区
```

### 2.1 为什么这样是安全的

**`expand` 下的视口高度只有一个变量**：宽度恒为 576，高度 = 576 × (屏高 ÷ 屏宽)。

| 机型 | expand 视口 | 相比 1024 的余量 | 上下各分到 |
| --- | --- | --- | --- |
| iPhone SE 3 | 576×1024 | **0** | 0 |
| iPhone 14 / 15 | 576×1246 | 222 | 111 |
| iPhone 15 Pro | 576×1249 | 225 | 112 |
| iPhone 15 Pro Max | 576×1248 | 224 | 112 |
| 安卓 360×800 | 576×**1280** | **256** | 128 |
| Pixel 7 Pro 类 | 576×1279 | 255 | 128 |

也就是说排版只需要覆盖 **1024 → 1280 这一段**，上下各 0 → 128 单位的弹性。

关键性质：**在 iPhone SE 3（9:16）上余量为 0，`WorldFrame` 正好铺满，HUD 和 Dock 回到今天的位置，布局完全退化成现在的样子。** 现在手机网页上验收过的效果不会被推翻，改动只在「比 9:16 更长的屏」上生效。

### 2.2 安全区余量够不够

| 机型 | 顶部安全区 | 换算成单位 | 顶部可用余量 | 结论 |
| --- | --- | --- | --- | --- |
| iPhone 15 Pro（灵动岛） | 59pt | 86 | 112 | ✅ HUD 落在余量内，不压世界 |
| iPhone X–13（刘海） | 47pt | 69 | 111 | ✅ |
| 安卓 360×800（状态栏） | 24–32pt | 38–51 | 128 | ✅ |
| **iPhone SE 3** | 20pt | **31** | **0** | ⚠️ HUD 要往下压 31 单位，比今天更遮世界 |

底部：iOS 小白条 34pt ≈ 50 单位，安卓手势条 16–24pt ≈ 26–38 单位，都在 0–128 的底部余量内（SE 3 除外，同样是 0）。

**SE 3 是唯一需要单独看一眼的机型**，其它主流机型的余量都足够。

---

## 3. R1：消黑边 + 安全区

一次提交，独立过质检。这是全计划里唯一动引擎设置和节点树的一步。

### R1-1 切 stretch 模式

`project.godot` 显式写入 `display/window/stretch/aspect="expand"`（现在是缺省，依赖引擎默认，本身就该写死）。

### R1-2 新增 `WorldFrame`

在 [`_setup_world_zoom()`](../scripts/Game.gd:398) 里，`WorldBack` / `WorldFront` 不再直接挂在根上，而是挂进一个固定 576×1024、垂直居中的 `WorldFrame`。

- [`_fit_worlds()`](../scripts/Game.gd:413) 目前把世界层尺寸设成 `size`（即整个根 Control）。改成设成 `WorldFrame` 的固定尺寸。
- 缩放 / 拖动逻辑（`_clamp_world()` / `_zoom_at()` / `_apply_pinch()`）的坐标基准跟着 `WorldFrame` 走，不是根。
- `Bg` 留在根上铺满真实视口，颜色沿用现在的 `Color(0.776, 0.847, 0.714)`，或换成上下渐变去接地图的天空 / 草地。

**红线**：`WORLD_BACK` / `WORLD_FRONT` 的成员名单不变，只换共同父节点。`_raise_hud_chrome()` 的所有 z 值不变。

### R1-3 安全区读取

新增 `scripts/SafeArea.gd`（或并进 `Game.gd`，视代码量定），提供 `insets() -> Vector4`（上 / 右 / 下 / 左，游戏单位）：

| 平台 | 来源 |
| --- | --- |
| Web | `JavaScriptBridge` 读 `env(safe-area-inset-*)`。需要在 `:root` 上先写 `--sat: env(safe-area-inset-top)` 之类再 `getComputedStyle` 取值——`env()` 不能直接读 |
| 原生 Android / iOS | `DisplayServer.get_display_safe_area()` 对比 `get_screen_size()` |
| 小游戏渠道 | 见 R3，走各家 SDK，本步只留接口 |
| 取不到 | 回退常量：顶 48 单位、底 34 单位 |

**前置检查**：`env(safe-area-inset-*)` 只在 `<meta name="viewport" content="... viewport-fit=cover">` 下才非零。需要确认 Godot 4.7.1 的默认 web shell 是否带 `viewport-fit=cover`；不带就通过 `export_presets.cfg` 的 `html/head_include`（现在是空的）补，或者在 [`_lock_web_gestures()`](../scripts/Game.gd:323) 里直接改 meta。

### R1-4 Chrome 贴真实边

- `HUD`：`anchors_preset` 保持顶部拉伸，`offset_top` 从固定 10 改成 `10 + inset.top`（脚本在 `resized` 时刷新）。
- `Dock`：现在是 `anchor_top=0.786 / anchor_bottom=0.996` 的比例锚定，在 `expand` 下高度会跟着视口变（1280 时变成 269 单位高，比设计值 215 高 25%）。**改成贴底 + 固定高度**：`anchor_top=1 / anchor_bottom=1`，`offset_top = -(215 + inset.bottom)`，`offset_bottom = -inset.bottom`。
- `HudBarBg` 跟着 `hud_bar` 走的逻辑（[`_sync_top_hud_bar()`](../scripts/Game.gd:1422)）不用改，它是相对定位。

### R1-5 检查被比例锚定的其它节点

`expand` 之后所有比例锚定的节点行为会变。逐个确认它们应该跟世界走还是跟屏幕走：

| 节点 | 现状 | 归属 |
| --- | --- | --- |
| `EggThought` / `CakeThought` / `HatchThought` / `ChickThought` | 已在 `WorldFront` | 世界 ✅ |
| `BakeryEggs` / `BakeryUpgrade` / `WolfShop` | 已在 `WorldFront` | 世界 ✅ |
| `HatchEgg` | 在 `WorldBack` | 世界 ✅ |
| `QuestPop/Card` | 根，比例锚定 | **屏幕**——在 1280 高的屏上会拉长，要复核 |
| `SettingsPop/Card`（0.06–0.9） | 根，比例锚定 | **屏幕**——同上 |
| `TrophyPop/Card` | 根，比例锚定 | **屏幕**——同上 |
| `StartMenuLayer/Card`（居中 340×536 固定） | 根 | 屏幕 ✅ 固定尺寸，天然安全 |
| `Night` / `Night/Card` | 根 | **屏幕**——结算卡要复核，别在长屏上被拉变形 |
| `TutorialLayer/Card` | 根 | **屏幕**——复核 |
| `Toasts` | 根 | 屏幕 |

弹窗卡片建议统一改成「固定最大宽 + 居中 + 上下留安全区」，不要继续用比例锚定，否则每换一种屏比就要重新对一次。

### R1-6 验收

- 8 个机型比例（1.2 的表）各截一张，确认无黑边、无拉伸、鸡站的位置和现在一致。
- iPhone SE 3 比例（375×667）单独确认：布局和今天完全一致，只是 HUD 下移约 31 单位。
- `AGENTS.md` 固定五项回归全过。
- `LayerSmokeTest` / `TutorialSmokeTest` 通过。

---

## 4. R2：触控尺寸和字号下限

R1 落地并在手机上确认之后再做。R1 释放出的垂直空间正好给 R2 用。

### R2-1 触控下限

按最坏情况 `scale = 0.625` 定：**主要操作 ≥ 72 单位（45pt），任何可点控件 ≥ 64 单位（40pt）**。

| 控件 | 现在 | 目标 | 备注 |
| --- | --- | --- | --- |
| `ShareBuy` / `ShareSell` | 42 | **72** | 最严重的一个。Dock 里 `Ticker` 列要重排，`Face`（走势图 + 三行文字）要让出高度 |
| `SettingsBtn` | 48 | **72** | 和 R3 的胶囊避让一起改 |
| `QuestBtn` | 64 | **72** | 同上 |
| 开始菜单 5 个入口 | 46 | **72** | 卡片高度从 536 → 约 660，`expand` 下放得下 |
| `SettingsPop` 各行 | 52 / 62 | **72** | 卡片已经偏挤，可能要拆成两屏或加滚动 |
| 思想气泡 | 60–64 | **72** | 它们在世界层，会跟缩放走，优先级低于以上 |

相邻可点控件间距 ≥ 12 单位（7.5pt）。

### R2-2 字号下限

**正文 ≥ 18 单位（11.3pt），任何文字 ≥ 16 单位（10pt）。**

| 现在 | 改成 | 影响 |
| --- | --- | --- |
| 11（`CashTitle` / `StockTitle`） | 16，或直接删标题只留图标 | HudBar 宽度 294 已经很挤，加字号会溢出，倾向删标题 |
| 13（`TickerPrice` / `TickerDelta` / `TickerHold`） | 18 | Dock `Ticker` 列要重排，和 R2-1 一起做 |
| 14（`DayLabel`、`Subtitle`、指南正文） | 16–18 | 指南正文加字号会撑破羊皮纸内容区，要重新排 |
| 15（`BakeryEggs`、设置页底部三项） | 16–18 | |
| `SettlementCard.tscn` 的 14 / 15 | 16–18 | 结算卡单独一轮 |

字号改动会连锁触发换行和溢出，必须**按 `UI_LAYOUT_WORKFLOW.md` 一个界面一轮**，中英文都覆盖，不要一次全改。

### R2-3 顺序

按影响面从小到大：`Dock` → `HUD` → 开始菜单 → 设置页 → 结算卡 → 新手指南。

---

## 5. R3：渠道适配（等渠道确定）

渠道未定，这一段只列需求，不排期。

### R3-1 胶囊避让（微信 / 抖音 / 快手）

右上角预留一块 **约 130×50 单位**（87×32pt ÷ 0.682）的禁区，`QuestBtn` 和 `SettingsBtn` 移出去。可选落点：

- 移到左上，和时钟换边；
- 或整条 HUD 下移到胶囊下方，右上留空。

精确尺寸不要写死常量，用 `wx.getMenuButtonBoundingClientRect()` / 抖音对应 API 实时读，取不到再回退常量。

### R3-2 各渠道差异

| 项 | 微信小游戏 | 抖音小游戏 | 纯 H5 |
| --- | --- | --- | --- |
| 胶囊 | 有 | 有 | 无 |
| 安全区 API | `wx.getSystemInfoSync().safeArea` | `tt.getSystemInfoSync().safeArea` | `env(safe-area-inset-*)` |
| 退出 | `wx.exitMiniProgram()` | `tt.exitMiniProgram()` | 无 |
| 主包上限 | **4MB**（总 30MB 需分包） | 宽松 | 无 |
| 首屏 loading | 必须自绘 | 必须自绘 | 现有 boot splash 够 |

设置页的「返回主菜单」（`SettingsPop/Card/Col/HomeBtn`）在有退出 API 的渠道上可能要加一个「退出小游戏」。

### R3-3 阻塞项：包体

这是选微信渠道的硬门槛，也是唯一可能推翻整个渠道选择的因素。

- `assets/` 现在 112MB。导出预设已经排掉草稿（`generated-v2`、`mockups`、`farm-background-hd-v2` 等），但仍在打包的大件包括 `assets/map/farm-background.png` 8.7MB、`assets/sprites/wolf-hen-idle-6x1.png` 2.9MB、`assets/ui/guide-board-cut.png` 2.5MB、`assets/ui/farm-ui-atlas-transparent.png` 2.3MB。
- 加上 Godot 4 web 的 wasm，落地包保守估计 25–40MB。
- **微信小游戏主包 4MB 过不去**，必须分包 + CDN 远程资源，且 Godot 官方没有微信小游戏导出，要走第三方转换链路。
- 抖音 / 快手 / 纯 H5 没有这个硬限制，但首屏加载时长仍需要资源瘦身。

建议：在定渠道之前先跑一次真实导出，量一下 `index.pck` 和 `.wasm` 的实际体积，再决定。现在 `export/web/` 里只有 `_headers` 和 `netlify.toml`，没有构建产物，所以这个数字目前是估的。

---

## 6. 验收标准

一个阶段只有同时满足以下才算完成：

1. 1.2 表里的 8 个机型比例，中英文各一张截图，无黑边、无裁切、无遮挡。
2. iPhone SE 3（9:16）和安卓 360×800（最小 scale）这两个极值机型单独确认。
3. `AGENTS.md` 固定五项回归全过：信封不秒关、语言只切一次、结算时 Dock 消失、烤炉能烤完、结算层在 Dock 之上。
4. `LayerSmokeTest` / `TutorialSmokeTest` 通过。
5. `git diff` 不含玩法数值、`Loc.gd` 文案含义、z 值、防抖逻辑的改动。
6. 太阳海在手机网页上确认成片。

---

## 7. 明确不做

- 不改画风、不换素材。
- 不动无尽模式逻辑（`quest_done` 不复位、`wealth_log` 无上限这两个坑归 `ENDLESS_MODE_PLAN.md` 的 R1-3 / R1-4）。
- 不改 `Loc.gd` 的文案含义。
- 不为了「能点到」抬 Dock 的 z 值。
- 不在同一次提交里混 R1（容器层）和 R2（排版）。
