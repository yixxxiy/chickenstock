# 小鸡股市 — 数据埋点

版本：对照当前 `scripts/Game.gd`（存档 `cluck-farm-v7.json`）。  
完成标准：手机网页 https://chickenstock.netlify.app。  
现状：工程内**没有**统计 SDK，本文只定事件名、字段和优先级，方便以后接 PostHog / Mixpanel / GA4 / 自建。

## 1. 要回答的问题

| 优先级 | 问题 |
| --- | --- |
| P0 | 人从哪进来、玩没玩、卡在哪（主菜单 / 教程 / 第几天） |
| P0 | 八日挑战有没有打完，通关还是资产不够 |
| P0 | 教程哪一步掉人 |
| P1 | 农场循环（收蛋、孵化、蛋糕、买鸡）和股市（买/卖）各做了多少 |
| P1 | 结束一天时蛋有没有碎、股价怎么走 |
| P2 | 设置、语言、邮箱、成就、烤炉升级 |

## 2. 身份与会话

每条事件都带这些公共字段（能取到再发，不要为了埋点改玩法）。

| 字段 | 类型 | 来源 |
| --- | --- | --- |
| `client_id` | string | 首次启动生成 UUID，写 `user://`，以后一直用 |
| `session_id` | string | 每次打开页面生成 |
| `session_seq` | int | 本会话第几条事件 |
| `ts` | int | Unix ms |
| `build` | string | 导出包版本或 `index.pck` 哈希前 8 位 |
| `lang` | `zh` / `en` | `Loc.lang` |
| `mode` | `menu` / `tutorial` / `campaign` / `endless` | 主菜单 / 教学 / 八日 / 无尽 |
| `day` | int | `day`，菜单为 0 |
| `tutorial_step` | int | `0–7`，非教学为 `-1` |
| `coins` | int | 现金 |
| `wealth` | int | `total()` = 现金 + 持股×现价 |
| `birds` | int | 母鸡 + 小鸡 + 待收小鸡 + 孵化中 |
| `hens` | int | |
| `chicks` | int | `young_chicks + hatched` |
| `shares` | int | |
| `price` | int | 现价 |
| `bakery_level` | int | `1–4` |
| `quest_done` | bool | 是否已达到 3000 资产且 15 只鸡 |
| `platform` | string | `web` |
| `ua_mobile` | bool | 是否手机 UA |

**会话**：打开页面发 `app_open`；切到后台 30s+ 再回来算新会话（网页用 `visibilitychange`）。

不要上传邮箱、存档全文、IP。制作人邮箱只在设置里展示，禁止进统计。

## 3. 命名

- 事件：`snake_case`，动词在前：`tutorial_step_complete`。
- 属性：`snake_case`。
- 失败：同一事件加 `ok: false` 和 `reason`，不要另造一堆 `xxx_fail`（漏斗用 `ok` 过滤）。
- 长按连点：只在**第一次按下**打点，不要每个 hold tick 打一次。

常量（写死在属性说明里，便于对账）：

| 名 | 值 |
| --- | --- |
| 一日时长 | 正式 20s，教学暂停/60s |
| 买鸡 | 50 |
| 卖母鸡 | 40 |
| 蛋糕 | 150 |
| 目标 | 资产 3000，鸡 15 |
| 八日 | `day == 8` 且非无尽则收官 |
| 新闻 | `hoard` / `cake` / `rain` |
| 烤炉花费 | Lv1→2 = 200，2→3 = 500，3→4 = 950 |

## 4. 事件表

### 4.1 启动与主菜单（P0）

| 事件 | 何时 | 额外属性 |
| --- | --- | --- |
| `app_open` | 游戏 `_ready` 且主循环开始 | `has_save` bool，`last_mode`，`last_day` |
| `menu_view` | 主菜单出现 | `from`: `boot` / `home` / `restart` / `tutorial_exit` |
| `menu_click` | 点主菜单按钮 | `item`: `tutorial` / `direct` / `endless` / `settings` / `trophies` |
| `run_start` | 真正进入可玩农场 | `entry`: `tutorial` / `direct` / `endless` / `continue`；`continued` bool |

`continue`：有存档且模式一致、未收官。

### 4.2 教程（P0）

步骤与 `Game._tutorial_action` 对齐：

| step | 完成动作 |
| --- | --- |
| 0 | 点「开始」 |
| 1 | 收下 3 个蛋（`egg_stored` ×3） |
| 2 | 点孵化（`hatch_started`） |
| 3 | 卖掉蛋糕（`cake_sold`） |
| 4 | 狼摊买鸡（`chick_bought`） |
| 5 | 买 1 股（`share_bought`） |
| 6 | 卖 1 股（`share_sold`） |
| 7 | 点「进入正式游戏」 |

| 事件 | 何时 | 额外属性 |
| --- | --- | --- |
| `tutorial_start` | `_start_tutorial` | |
| `tutorial_step_view` | `_tutorial_set_step` | `step` |
| `tutorial_step_complete` | `_tutorial_action` 推进成功 | `step`，`action` |
| `tutorial_finish` | `_leave_tutorial(true)` | `duration_ms` |
| `tutorial_abort` | `_leave_tutorial(false)` | `step`，`duration_ms` |

漏斗：`tutorial_start` → 各 `step_complete` → `tutorial_finish` → `run_start(entry=direct 或 campaign)`。

### 4.3 农场操作（P1）

成功才 `ok: true`。点了但条件不够：`ok: false` + `reason`。

| 事件 | 代码 | `reason` 例 |
| --- | --- | --- |
| `egg_collect` | `collect_egg` | `blocked`，`empty`，`tutorial_lock` |
| `hatch_start` | `start_hatch` | `no_egg`，`already_hatching` |
| `chick_collect` | `collect_chick` | `none`，`tutorial` |
| `cake_sell` | `sell_cake` | `no_cake` |
| `chick_buy` | `buy_chick` | `no_gold`（现金 < 50） |
| `hen_sell` | `sell_hen` | `no_hen`，`tutorial` |
| `bakery_upgrade` | `upgrade_bakery` | `locked_day`（day<2），`no_gold`，`max` |

成功时建议再带：

- `chick_buy`：`cost=50`，`birds_after`
- `cake_sell`：`gain=150`，`cakes_left`
- `bakery_upgrade`：`from_level`，`to_level`，`cost`

按钮灰掉未点：**不要**打点。点了才打 `ok: false`。

### 4.4 股市（P1）

| 事件 | 代码 | 额外属性 |
| --- | --- | --- |
| `share_buy` | `buy_shares` | `ok`，`price`，`qty`（本次 1），`shares_after`，`reason` |
| `share_sell` | `sell_shares` | 同上；成功可加 `pnl_this`（卖出价相对均价，没有均价就省略） |

长按连买：只记第一次，或加 `via: tap / hold`，`hold` 每秒最多 1 条。

### 4.5 一天结束与结算（P0）

对应 `结束今天` / 倒计时走完进入 Night。

| 事件 | 何时 | 额外属性 |
| --- | --- | --- |
| `day_end` | 结算摘要写好、Night 出现 | `how`: `button` / `timeout`；`eggs_broken`；`eggs_auto_hatch` bool；`news`；`price_from`；`price_to`；`wealth_from`；`wealth_to`；`grown`；`hatched`；`is_finale` bool |
| `settlement_cta` | 点日结 CTA | `kind`: `next_day` / `restart` / `endless` / `share` |
| `day_wake` | `_wake` 新的一天开始 | `day`（醒来后） |
| `campaign_end` | 八日收官卡出现 | `wealth`，`birds`，`quest_ok`，`rank_lv`，`rank_title` |
| `endless_continue` | 通关后点无尽继续 | `from_day`，`wealth` |

`is_finale`：`day == 8 && !endless_mode`。  
碎蛋：`leftover_eggs() > 0` 且未自动进窝。

### 4.6 目标与成就（P1）

| 事件 | 何时 | 额外属性 |
| --- | --- | --- |
| `quest_complete` | `quest_done` 第一次变为 true | `day`，`wealth`，`birds` |
| `quest_open` | `_open_quest` | `source`: `mail` / `fanfare` / `other`；`unread` bool（红点） |
| `quest_close` | `_close_quest` | `dwell_ms` |
| `trophy_unlock` | `_grant_trophy` 真正新解锁 | `trophy_id` |

`trophy_id` 与代码一致：`primer`，`cake`，`hen`，`share`，`flock`，`day8`，`endless7`，`chicken_king`，`chicken_emperor`，`retail_not_chives`，`stock_god`，以及日结段位相关 id。

### 4.7 HUD / 设置（P2）

| 事件 | 何时 | 额外属性 |
| --- | --- | --- |
| `settings_open` / `settings_close` | 设置面板 | `source`: `hud` / `menu` |
| `settings_toggle` | 音效 / 环境音 | `key`: `sfx` / `amb`，`on` bool |
| `lang_change` | `Loc.toggle` 成功（防抖后） | `from`，`to` |
| `game_reset` | `_restart` | `confirm` 若以后有二次确认 |
| `home_menu` | 设置里回主菜单 | `day`，`mode` |

点语言只打一次（已有约 280ms 防抖，埋点跟防抖后的结果走）。

## 5. 漏斗（看板直接用）

**新用户**

1. `app_open`
2. `menu_click item=tutorial`（或 `direct`）
3. `tutorial_start`（若走教程）
4. `tutorial_step_complete` step=1…6
5. `tutorial_finish`
6. `run_start`
7. `day_end` day=1…8
8. `campaign_end`

**核心循环（单日）**

`egg_collect ok` → `hatch_start` 或 `cake_sell` → `chick_buy` / `share_buy` → `day_end`

看：到 `day_end` 的人数、碎蛋率、买鸡率、做股票率。

## 6. 接入约定（以后写代码时）

1. 新建 `scripts/Analytics.gd`（Autoload），`log(name, props)`；Web 导出再 POST。没配 endpoint 就静默丢弃，不要弹窗。
2. 只在**玩法已经成功改状态之后**打成功事件；失败打在 toast / `_deny` 同一处。
3. 不要在 `_process` 里打点。
4.  tut 锁、结算 `blocked()` 造成的点按：能区分就带 `reason=blocked`。
5. 调试：`verbose` 时 `print` 事件名；正式包关闭。

## 7. 第一期建议（先做这些）

只接 P0，大约 12 个事件：

`app_open`，`menu_click`，`run_start`，`tutorial_start`，`tutorial_step_complete`，`tutorial_finish`，`tutorial_abort`，`day_end`，`campaign_end`，`quest_complete`，`settlement_cta`

农场买卖等按钮稳了再补 P1。

## 8. 对照代码位置

| 埋点 | 文件 |
| --- | --- |
| 主菜单 | `Game._start_menu_*_pressed`，`_enter_play` |
| 教程 | `_start_tutorial`，`_tutorial_action`，`_leave_tutorial` |
| 农场/股市 | `collect_egg`，`start_hatch`，`sell_cake`，`buy_chick`，`sell_hen`，`buy_shares`，`sell_shares`，`upgrade_bakery` |
| 日结 | 结束今天逻辑、`_wake`，`_fill_finale_card` |
| 目标 | `_refresh` 里 `quest_complete()`，`_grant_trophy` |
| 设置 | `_connect_ui` 里 Sfx / Amb / `Loc.toggle` / `_restart` |
