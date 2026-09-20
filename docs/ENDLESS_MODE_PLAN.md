# 无尽模式落地计划

适用范围：Godot 4.7.1，竖屏 576×1024，主场景 `res://scenes/Game.tscn`。
结构约定：主脚本 `Game.gd` 集中控制，`SettlementCard` / `Juice` / `Sfx` / `YardBird` 等为表现辅助。
本计划**不复制场景、不新建游戏模式场景**，只在现有 `Game.tscn` 上加模式分支。

行号基于 2026-09-05 21:08 的 `scripts/Game.gd`（107 KB）。改动后请以函数名为准。

---

## 0. 先说三个和原始判断不一致的地方

**一、无尽模式已经存在了，而且就是「只删掉第八天结束」。**

不是待开发项。当前 [`_next_day()`](scripts/Game.gd:2388) 的终点判断已经是：

```gdscript
if day == 8 and not endless_mode:
```

`endless_mode` 字段、存档字段 `endlessMode`、开始菜单的「无尽模式」入口、`第 %d 天` 的日期文案、以及一套 8 项奖杯（含 `endless7`）都已经接好了。也就是说计划里的**第 2 项（模式字段）已完成**，第 4 项（显示）完成了一半。

但它是**开始菜单里的另一条路**，不是挑战结束后的延续。后果：走无尽的玩家永远不会看到评级结算卡，也没有任何「成绩」概念；走挑战的玩家第八天结束后仍然只能 `_restart()` 重开。你要的「保留八日成绩 → 继续经营」还没有。

**二、「第八晚到第九天的结算衔接」在当前实现下不会触发，但做「继续经营」时一定会触发。**

现在无尽模式压根不进 `day == 8` 分支，所以 `summary` 正常生成、`_wake()` 正常推进，没有断裂。这个坑是**你把 day-8 finale 改成可继续之后才会出现的**——届时必须先构造 `summary` 再决定显示哪张卡，不能靠清空 `game_result` 再调 `_wake()`。计划保留这一项，但它属于 R1-1 的实现细节，不是独立的既有 bug。

**三、教学已经是单日 8 步，不是三日。**

`AGENTS.md` 和 `监工文档.md` 里的「三日新手关」是旧文案。当前是 `tutorial_step` 0–7 的单日分步教学，教学期间时钟真的暂停（[`_process()`](scripts/Game.gd:920) 里 `if not tutorial_mode: left_ms -= ...`）。文档待同步。

---

## 1. 现有玩法（核对后的事实清单）

核心循环：母鸡产蛋 → 收蛋 → 分配给孵化或自动烤蛋糕 → 卖蛋糕 → 买鸡扩产／买卖股票 → 夜间结算。

| 项 | 数值 | 位置 |
| --- | --- | --- |
| 初始 | 120 金币 / 1 母鸡 / 3 枚可收蛋 | [`_reset_new_game_data()`](scripts/Game.gd:2841) |
| 常规日长 | `DAY_MS = 20000`（20 秒） | [Game.gd:16](scripts/Game.gd:16) |
| 黄昏预警 | `DUSK_WARN_MS = 5000` | [Game.gd:18](scripts/Game.gd:18) |
| 孵化 | 1 枚蛋，次日出小鸡，每天最多 1 枚 | `start_hatch()` |
| 烘焙 | 库存满 2 枚自动点火，每 0.12s +5%，约 2.4s 一个 | `_process()` |
| 蛋糕 | 卖 150 金币 | `CAKE_SALE` |
| 买小鸡 / 卖母鸡 | 50 / 40 金币，小鸡次日成母鸡 | `CHICK_COST` / `CHICK_SALE` |
| 烤炉 | 第 2 天起可升级，1→4 级，成本 200 / 500 / 950 | `BAKERY_UPGRADE_COSTS` |
| 任务 | 资产 ≥ 3000 且 鸡群 ≥ 15 | `WEALTH_GOAL` / `FLOCK_GOAL` |
| 资产口径 | **现金 + 股票市值**，不含鸡、蛋糕、烤炉 | [`total()`](scripts/Game.gd:1036) |
| 股市消息 | 仅 3 条：`cake` / `hoard` / `rain`，方向确定 | `NEWS` / `pick_news()` |
| 结束 | 第 8 天固定结算评级，任务完成不提前结束 | `_next_day()` |
| 存档 | `user://cluck-farm-v7.json` + 当日早晨快照 `_dawn_snap` | `_save()` / `_capture_dawn()` |

需要修正的一条：**「直接开始」首日 60 秒**这个 bug 已经修了。现在 [`_enter_play()`](scripts/Game.gd:713) 统一 `left_ms = DAY_MS`，两条入口的第一天都是 20 秒。

---

## 2. 无尽模式现状盘点

### 已经做完的

| 能力 | 实现位置 |
| --- | --- |
| `endless_mode` 字段 | [Game.gd:105](scripts/Game.gd:105) |
| 随存档保存 / 读取，旧存档默认挑战模式 | `_save()` 写 `endlessMode`；`_load()` 读 `bool(d.get("endlessMode", false))` |
| 重置时归位 | `_reset_new_game_data()` 末尾 `endless_mode = false` |
| 开始菜单第三个入口「无尽模式」 | `_start_menu_endless_pressed()` → `_enter_play(true)` |
| 同模式续档、跨模式重开 | `_enter_play()` 里 `can_continue` 判断含 `endless_mode == want_endless` |
| 跳过第八天终局 | `if day == 8 and not endless_mode` |
| 日期文案分模式 | `day_endless` = `第 %d 天`，`day_frac` = `%d/8天` |
| 奖杯系统（8 项，独立存档 `cluck-trophies.json`） | `TROPHY_DEFS` / `_grant_trophy()` / `_check_trophies()` |
| 无尽第 7 天奖杯 | `_wake()` 里 `if endless_mode and day >= 7` |

### 还没做的（按你的清单逐条落位）

| # | 你的条目 | 现状 | 结论 |
| --- | --- | --- | --- |
| 1 | 第八天保留成绩 + 继续经营 | 无尽是独立入口，挑战结束仍只能 `_restart()` | **待做，R1 主体** |
| 2 | 模式字段 | 已完成 | 关闭 |
| 3 | 第八晚→第九天衔接 | 当前不触发，做 #1 时必须处理 | **并入 R1-1** |
| 4 | 显示调整 | 日期文案已分模式；其余仍写死八日 | **部分待做** |
| 5 | 长期运行保护 | 完全没做 | **待做，R1 必须** |
| — | 任务停在完成态 | `quest_done` 一旦 `true` 永不复位 | **待做** |
| — | 烤炉 4 级封顶 / 3 条新闻 / 无支出破产 | 未处理 | 留给 R2 |

**长期运行保护的两个具体风险（已核实）**

- [`_spawn_flock()`](scripts/Game.gd:2224) 为**每一只**母鸡和小鸡各创建一个 `YardBird` 动画节点，无上限。无尽跑到 60+ 只鸡时，手机上是 60+ 个逐帧精灵在走位。
- `wealth_log` 每次 `_wake()` 追加一个整数，**从不裁剪**，并且整数组写进存档 JSON。无尽长局会让存档和终局曲线无限膨胀。

**仍写死「八日」的文案**（都在 `Loc.gd`，中英各一份）：`help`、`guide_step_stock_desc`、`tutorial_t0_goal`、`tutorial_complete_toast`、`finale_hook`、`chart_cap`、`retry_eight`、`quest_miss`、`rank_10_copy`。

---

## 3. 第一步（R1）：让这座农场可靠地继续经营

目标：手机上能验证「保留这座农场继续玩」是否有吸引力。不加新玩法，只把延长跑通。

### R1-1 把 day-8 终局改成「结算 + 可继续」

改 [`_next_day()`](scripts/Game.gd:2388)。当前 day-8 分支在构造 `summary` **之前**就 `return` 了，这是衔接断裂的根源。改成先建 `summary`，再选卡：

```
计算 broken / grown / hatch_ready / sold / old_p / p / closing
        ↓
无条件构造 summary（含 day+1、fromDay）      ← 关键：提前到分支之前
        ↓
if day == 8 and not endless_mode:
        game_result = "ended"
        记录本局八日成绩到 _run_record
        _grant_trophy("day8")
        _fill_finale_card(closing)          ← finale 增加「继续经营」按钮
else:
        _fill_daily_card()
```

`_on_settlement_confirm()` 相应分三路：

| 来源 | 行为 |
| --- | --- |
| 日结卡确认 | `_wake()`（不变） |
| 终局卡「再战八天」 | `_restart()`（不变） |
| 终局卡「继续经营」 | `game_result = ""`；`endless_mode = true`；`_wake()` |

`_wake()` 本身**不用改**——它只依赖 `summary`，而 `summary` 现在总是存在。成长和孵化仍然只结算一次，因为 `_wake()` 结尾会 `summary = {}`。

新增状态 `_run_record: Dictionary`，随存档保存，记录八日成绩：`{"rank_lv", "wealth", "birds", "quest", "day": 8}`。继续经营后这份成绩不再变化，用于奖杯页和分享。

**完成标准**：第八天结算后点「继续经营」能进第九天；`hens` 只增长一次、`hatched` 只到账一次；此时 `endless_mode` 为 `true` 并写进存档。

### R1-2 结算卡增加「继续经营」按钮

改 [`SettlementCard.gd`](scripts/SettlementCard.gd) 的 `show_finale()` 与 `.tscn`：在 `$Finale/Actions` 里加一颗 `ContinueBtn`，新 signal `continue_run`。
沿用现有 `_style_green()` / `_begin_cta_wait()` 的锁定节奏，不要新造样式。

**注意按钮宽度**：教学第 7 步的「进入正式游戏」已经出现过文字撑出按钮的问题（`custom_minimum_size = (112, 40)` 放不下 5 个 16px 中文字）。新按钮文案控制在 4 字以内，或把 `custom_minimum_size.x` 一起放开。

### R1-3 任务不再停在完成态

`quest_done` 现在一旦 `true` 就永远不复位，信封会一直显示「已完成」印章。
最小改法：进入无尽（`endless_mode == true`）时，`_refresh_quest()` 改为显示**当前阶段订单**而不是固定的 3000／15。订单本体见 R1-6。

八日目标在无尽里仍然有意义（它是奖杯 `wealth` / `flock` 的判定），但不再是信封的主展示内容。

### R1-4 长期运行保护

**鸡群显示与实际分离。**

```gdscript
const FLOCK_RENDER_CAP := 24   # 初值，手机实测后再定
```

`_spawn_flock()` 只创建 `mini(hens, cap)` + `mini(young_chicks, cap - 已用)` 个节点；`_refresh_flock()` 的 `_flock_sig` 用**截断后的数量**参与签名，避免超过上限后每天重建。
HUD 的 `hud_hens` / `hud_chicks` 和 `birds()` 仍用真实数量——只有画面截断，逻辑不截断。

**资产曲线裁剪。**

```gdscript
const WEALTH_LOG_MAX := 40
```

`_wake()` 追加后裁剪到最近 40 天；同时新增 `best_wealth`（历史最高资产）单独记录并存档，终局曲线用「最近 40 天 + 历史最高」而不是全量。

**完成标准**：无尽跑到第 30 天，鸡群 40+，手机网页帧率不塌；存档 JSON 体积不随天数线性增长。

### R1-5 文案统一进 Loc.gd

把第 2 节列出的 9 个写死八日的键改成分模式取值。无尽模式下：

- `chart_cap` → 「近期资产曲线」
- `retry_eight` / `quest_miss` → 经营天数口径
- `finale_hook` → 「我把农场经营到了第 N 天」
- 分享卡改为「经营天数 + 历史最高资产」

`help`、`guide_step_stock_desc`、`tutorial_t0_goal` 属于教学与指南，**保持八日口径不动**——教学只教挑战模式，不要在入门阶段引入第二套目标。

### R1-6 第一个阶段订单（最小版）

沿用信封，不新建面板。一次只有一单，完成后手动领取下一单。

```gdscript
const ORDERS := [
    {"id": "cake_5",   "kind": "cakes_sold", "need": 5,    "reward": 300},
    {"id": "flock_20", "kind": "birds",      "need": 20,   "reward": 500},
    {"id": "wealth_5k","kind": "wealth",     "need": 5000, "reward": 800},
]
```

新增状态 `order_index` / `order_progress` / `order_claimable`，随存档保存。
进度在 `_refresh_quest()` 里复用现有的 `WealthCard` / `FlockCard` 两条进度条组件——**不要新画 UI**。
完成时复用 `_start_fanfare()` 的印章与庆祝，领取按钮放在信封卡片底部。

**完成标准**：无尽第 1 单可完成、可领取、可进入第 2 单；刷新网页后订单进度不丢。

---

## 4. R1 验收清单

按 `AGENTS.md` 的自检格式，实现 agent 在回复里逐条勾：

1. 第八天结算后点「继续经营」→ 第九天；成长与孵化各只结算一次。
2. 停在结算界面时刷新网页 → 仍停在同一张结算卡，确认后仍能正确进入下一天。
3. 无尽模式中途「回到当天早晨」→ 天数、模式、订单进度都回到早晨状态。
4. 原八日挑战路径不变：第八天仍出评级卡，「再战八天」仍重开。
5. 教学（单日 8 步）不受影响，`TutorialSmokeTest` 仍 `TUTORIAL_SMOKE_OK`。
6. 已有回归项：点信封不立刻关；语言只切一次；进结算底栏消失且不挡 CTA；烤炉烤到 100% 能结束并重置；结算层仍在底栏之上。
7. 新增 `tests/EndlessSmokeTest.tscn`：模拟挑战跑到第 8 天 → 继续经营 → 第 9、10 天 → 断言 `hens` 增量正确、`endless_mode` 已存档、`wealth_log` 长度受限。

---

## 5. 第二步（R2）：继续玩的理由

R1 上线并在手机上试玩之后再动。**数值一律不在此刻定死**，先做机制骨架，用试玩调。

| 系统 | 范围 | 落点 |
| --- | --- | --- |
| 阶段订单扩展 | 从 3 单扩到一个可配置列表，每阶段从卖蛋糕／孵化／资产中抽一个 | 抽出 `OrderBook.gd` |
| 有用途的扩建 | 鸡舍容量、烤炉批量产出、孵化容量各一条升级线，给金币持续用途 | 现有 `bakery_level` 泛化为 `upgrades: Dictionary` |
| 持续数日的市场事件 | 一次只影响蛋糕售价／产量／股市中的一项，提前公告影响与期限 | 扩展 `NEWS` 为带 `duration` 的事件表 |

股市消息要从「明确给出涨跌方向」改成「给出倾向」，否则长局会退化成固定操作。

**重构时机**：等 R2 真的开始加订单／扩建／事件时，再把规则配置、订单管理、存档管理从 `Game.gd` 抽出去。R1 阶段**不做大重构**——四处改动都在现有函数内部。

---

## 6. 明确不做的事

- 不复制场景、不新建独立的无尽模式场景。
- 不在 R1 加经营支出和破产判定。当前设计更适合「持续经营、冲纪录」；要做「撑得越久越好」的生存模式，需要另设计支出与失败规则，是独立提案。
- 不改教学。教学只教挑战模式。
- 不动画风与美术资产。

---

## 7. 一个需要试玩回答的问题

每天只有 20 秒。鸡群扩大到 20、40 只之后，玩家的实际操作会不会退化成「反复长按收蛋、反复长按卖蛋糕」？

如果是，那么 R2 的第一优先级不是订单和事件，而是**批量操作**（一次收全部蛋 / 自动出售），或者**拉长无尽模式的日长**。这个只能靠手机实测回答，不要在代码里先猜。
