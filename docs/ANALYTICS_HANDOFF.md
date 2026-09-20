> **已被取代（2026-09-19）**：本文的「代码现状」与事件字典增补已落地，事件定义以 `docs/ANALYTICS.md` 为准。
> §3（已定规则）与 §7（仍未定）仍然有效。

# 埋点实施交接:当前状态与待办

更新:2026-09-19
工程:`E:\小游戏\Godot\chickenstock-yixuan`
读者:下一位接手埋点实施的 agent

## 文档优先级(冲突时的裁决顺序)

| 顺序 | 文档 | 日期 | 地位 |
| --- | --- | --- | --- |
| 1 | **本文** | 09-19 | 代码现状与待办,每条经当前代码核对 |
| 2 | **`PLAYTEST_DECISIONS.md`** | 09-17 | **用户决策的权威记录**。问卷流程、复活规则以它为准 |
| 3 | `CURSOR_HANDOFF_ANALYTICS_SURVEY_PLATFORMS.md` | 09-17 | 访谈与平台研究过程 |
| 4 | `PLAYTEST_ANALYTICS_PLAN.md` | 09-16 | 口径与验收清单仍有用,**但基线判断已失效**(见 §1) |
| 5 | `ANALYTICS.md` | 09-13 | 旧事件字典,已过时,勿照抄 |

**范围限定:只做游戏代码层面的埋点。** Marketing 归因(UTM、渠道、投放分析)在其他渠道做,
不在本轮范围。注意区分:**招募来源标记**(§4.6)不是 marketing 归因,是样本分层,必须做。

---

## 1. 先纠正:那份 09-16 计划错在哪

`PLAYTEST_ANALYTICS_PLAN.md` 的 §2.1 / §5.4 / §11.1 都写着「当前文件夹未发现二十天挑战/阶段失败机制」,
并把它列为头号待确认。**这是错的,机制就在本工程里:**

| 机制 | 位置 |
| --- | --- |
| `CHALLENGE_GATES` = 第 12 / 16 / 20 天资产+鸡群双门槛 | `Game.gd` 常量区 |
| 考核失败 `game_result = "flop"` | `Game.gd:2934` |
| 第 20 天通关 `game_result = "won"` | `Game.gd:2924` |
| 八日失败 `game_result = "flop"` | `Game.gd:2912` |
| 八日达标 `game_result = "ended"` | `Game.gd:2906` |

不要再去找「另一个版本」。`PLAYTEST_DECISIONS.md` 也已记录「旧计划中『没有挑战模式』的描述已过时」。

**游戏有四种模式,不是两种。** `ANALYTICS.md` 的 `mode` 枚举漏了 `challenge`,
`bakery_level` 写 `1–4` 实际到 **6**:

| mode | 含义 | 天数 | 烤炉上限 |
| --- | --- | --- | --- |
| `tutorial` | 单日教程,时钟暂停 | — | — |
| `normal` | 普通八日 | 1–8 | 4 |
| `challenge` | 挑战,每 4 天一次考核 | 9–20 | 6 |
| `endless` | 挑战通关后解锁,**无考核墙** | 21+ | 6 |

解锁链:普通八日达标 → 解锁挑战 → 第 20 天通关 → 解锁无尽。存 `user://cluck-unlocks.json`。

> 命名坑:`_continue_endless_from_finale()` 名字是旧的,**实际行为是「普通通关后进入挑战」**。
> 埋点按行为含义命名,不要跟着函数名叫 endless。

---

## 2. 代码现状

### 2.1 已有

| 项 | 位置 |
| --- | --- |
| 四模式 + 解锁链 | `_enter_play(kind)` `Game.gd:763` |
| 挑战三道考核 + flop/won 判定 | `_next_day()` `Game.gd:2849` 内 |
| 挑战预设开局(第9天/12鸡/烤炉Lv3/1800金/股价220) | `_apply_challenge_seed()` `Game.gd:804` |
| **考核失败一次机会**(第12/16/20天各自独立一次) | `_gate_retry_left` / `_spend_gate_retry` `Game.gd:1296` |
| 当天重试(回到当天早晨) | `_on_ad_rewind` `Game.gd:3307` → `_rewind_to_dawn` `Game.gd:3369` |
| 分享成绩卡(存 PNG) | `SettlementCard._share_card`,用 `JavaScriptBridge.download_buffer` |
| 长局保护 `FLOCK_RENDER_CAP=28` / `WEALTH_LOG_MAX=40` | `Game.gd` 常量区 |
| Netlify 请求头 | `export/web/_headers` + `export/web/netlify.toml` |

> **2026-09-19 新增**:「考核失败一次机会」和长局保护。
> 因此 `PLAYTEST_DECISIONS.md` 里「挑战考核失败没有该入口」、
> `PLAYTEST_ANALYTICS_PLAN.md` §2 里「鸡群显示/wealth_log 未设上限」这两条描述**都已不成立**。

### 2.2 完全没有(逐项核对过)

| 项 | 核对方式 |
| --- | --- |
| `scripts/Analytics.gd` | 文件不存在 |
| PostHog SDK | 脚本内 `posthog` 命中 0 |
| 自定义 Web 外壳 | `export_presets.cfg` 里 `html/custom_html_shell=""` |
| Autoload | `project.godot` **没有 `[autoload]` 段** |
| 问卷 / 五秒等待 | `survey` / `问卷` 命中 0 |
| 身份体系 | `distinct_id` / `visit_id` / `run_id` / `attempt_id` 各命中 0 |
| 分钟节点 / 心跳 / 有效时长 | 无 |
| 正式导出产物 | `export/web/` 下只有 `_headers` 和 `netlify.toml`,**没有 HTML/WASM/PCK** |
| 可回滚基线 | **本目录不是 git 仓库** |

**统计是 0 到 1,不是改进。** 计划的阶段 B/C/D 一项未开始。

`JavaScriptBridge` 现有两处用法都与统计无关(`Game.gd:320`、`SettlementCard.gd:653`),
可参考它们的 `OS.has_feature("web")` 守卫写法。

---

## 3. 已定的规则(照做,不要重新设计)

出自 `PLAYTEST_DECISIONS.md`,均为用户明确确认。

### 3.1 考核复活

- 第 12 / 16 / 20 天**各有一次**奖励复活,互不影响(第 12 天用过不影响 16、20)
- 同一考核日第一次失败可当天重试,**第二次没过不能再复活**

**代码已按此实现**(`_gate_retry_used`,`Game.gd:145`)。埋点直接复用 `_gate_retry_left()` 的判断,
以及 `_fill_flop_card` 里已经算好的 `"rewind"` 字段,**不要另写一套额度逻辑**。

### 3.2 问卷流程

```
第一次点奖励复活入口
  → 弹六题问卷
  → 未填完就关闭:这次复活照发,稍后仍可再填
  → 提交成功:以后不再弹,奖励入口改为五秒占位等待
设置里另有反馈入口:只补填问卷,不发复活
提交成功后,奖励入口和设置入口都不再出现问卷
```

关键推论:**「问卷完成率」不等于「复活发放率」**,因为关闭未提交也照发奖励。两者必须分别统计。

### 3.3 奖励观察分三层,不得合并

1. 看见入口 → 点击
2. 完成问卷 或 五秒等待
3. 真实广告完成并复活后**继续玩**

本轮不接真实广告,第 3 层拿不到。**不得**把问卷完成或五秒等待上报成广告展示/完播,
也不得用它们推算广告收入。

### 3.4 发布路线(背景,非本轮实施)

自有站小测排查问题 → 再投 CrazyGames 测陌生流量。不与 Poki 并行。
CrazyGames Basic Launch 阶段**广告是关闭的**,验证不了真实广告复活。
平台默认指标不会告诉你玩家卡在第 12 还是第 20 天,所以自有站要保留通关与重试的自定义事件。

---

## 4. 事件字典增补

计划 §7 的字典写于「不知道有挑战模式」时,最值钱的部分正好漏了。以下为增补,
计划 §7 已有的 `page_open` / `game_ready` / `tutorial_*` / `day_start` / `playtime_milestone` 沿用。

### 4.1 考核与复活意愿(最高优先级)

自愿回档(「想打更好」)和考核失败复活(「不想前功尽弃」)动机完全不同,**必须分开统计**。

| 事件 | 关键属性 |
| --- | --- |
| `gate_result` | `gate_day`、`hit`、`wealth`、`wealth_goal`、`birds`、`birds_goal`、**`shortfall_pct`** |
| `gate_retry_offer_view` | `gate_day`、`retry_index`、`shortfall_pct`(入口**实际可见**时才发) |
| `gate_retry_offer_click` | 同上,与 view 共用 `offer_id` 对账 |
| `gate_retry_offer_dismiss` | 同上 + `dismiss_how`:关卡片 / 回主菜单 / 直接离开页面 |
| `gate_retry_restored` | `gate_day`、`retry_index`(快照**确实恢复成功**后才发) |

**`shortfall_pct` 是归因的核心变量。** 差 5% 和差 60% 的玩家意愿天差地别;
没有它,「意愿率 34%」是个无法解释的数字。

`dismiss_how` 用来区分「没兴趣」和「被劝退」。

第 12 / 16 / 20 关分别看意愿,得到的**衰减曲线是未来定广告频次的依据**。
八日失败(`campaign_flop`)的复活意愿单列,不要和 gate 混。

### 4.2 教程 → 第一天 衔接漏斗

教程完成率高但第 1 天完成率低 = 教程没教会。计划有两端事件但没点明这个接缝。

```
tutorial_finish → play_start(mode=normal) → day_start(day=1) → day_end(day=1) → day_start(day=2)
```

- 全链路同一 `distinct_id`;`day_*` 同一 `run_id`
- `tutorial_finish` 带 `duration_ms` 和最后到达的 `step`
- `tutorial_abort` 带退出时的 `step`
- 看两个转化率:`play_start ÷ tutorial_finish`、`day_end(day=1) ÷ day_start(day=1)`

挂点:`_tutorial_next_pressed()` `Game.gd:3759`、`_tutorial_action()` `Game.gd:3767`
(步骤推进在 3799)、`_enter_play()` `Game.gd:763`。

### 4.3 `day_end` 当日操作计数

**不新增事件,只在已有 `day_end` 上加字段,事件量成本为 0。**
用来区分「挂机流失」和「操作到手抽筋还是输」——这两种流失解法完全相反。

这也满足 `CURSOR_HANDOFF` §5 的要求:「长按操作要保留实际数量,可聚合上报;
旧计划『只记长按第一次』不足以衡量完整操作量」。聚合计数正是这个做法。

| 字段 | 来源函数 |
| --- | --- |
| `act_egg` | `collect_egg()` `Game.gd:2633` |
| `act_cake` | `sell_cake()` `Game.gd:2711` |
| `act_chick_buy` | `buy_chick()` `Game.gd:2786` |
| `act_hatch` | `start_hatch()` `Game.gd:2686` |
| `act_share_buy` | `buy_shares()` `Game.gd:2737` |
| `act_share_sell` | `sell_shares()` `Game.gd:2761` |

同时带经济快照(同样纯字段):`wealth`、`birds`、`bakery_level`、`cakes_sold`、
`stock_profit`、`broken_eggs`。回答「卡在哪个数值上」。

实现提示:这六个函数都有 `quiet` 参数,冒烟测试以 `quiet=true` 调用。
**计数放在真实成功路径上**,并确认测试调用不污染统计。每天在 `_wake()` `Game.gd:3582` 清零。

**不要**给每次收蛋单独发事件——一局上千次点击,一个玩家吃掉几百条额度。

### 4.4 问卷

| 事件 | 属性 |
| --- | --- |
| `survey_view` / `survey_submit` | 沿用计划 §7 |
| `survey_dismiss` | **新增** `dwell_ms` + 关闭时在第几题。只记 submit 会严重高估问卷体验,而且按 §3.2 关闭也照发奖励,这条是必需的 |
| 全部问卷事件 | **新增** `survey_source`:`gate_retry` / `campaign_flop` / `settings` / `day_rewind` |

画像四项沿用计划 §5.2,**「未回答」与「不披露」必须是不同的值**。

### 4.5 其他

| 事件 | 说明 |
| --- | --- |
| `menu_click_locked` | 挑战/无尽被锁时的点击。多少人想玩但被解锁条件挡住;计划的 `menu_click` 没区分成功/被拒 |

### 4.6 招募来源标记(必做,不是 marketing 归因)

`PLAYTEST_DECISIONS.md` 两处强调:**朋友/学校协助测试与陌生自然流量不能混为一个群体**,
「朋友填问卷与陌生玩家看广告动机不同,按来源和奖励类型分开看」。

做法:一个粗粒度 `cohort` 字段(如 `friends` / `school` / `organic` / `crazygames`),
由分发链接带入并随事件上报。**这是样本分层,不是渠道投放分析**,与 §范围限定 不冲突。
不要顺手把 UTM 全套、referrer、设备定向采集加进来。

### 4.7 明确不做

- UTM / referrer / 渠道归因 / 设备定向采集
- 分享事件(`share_click` 等)—— 传播分析,不在本轮
- 每次收蛋、长按 tick 的全量日志

---

## 5. 额度预算

PostHog 免费额度 100 万事件/月。

- 心跳 **30 秒**一次,20 分钟会话 = 40 条
- 离散事件约 80 条/人
- 合计约 **120 条/人** → 约 **8,000 名玩家/月**

首轮够用。三条保命规则:

1. 心跳保持 30 秒,**不要更密**
2. **绝不做每次操作的埋点**(见 §4.3)
3. 内部调试流量用**独立 project** 或 `$process_person_profile: false`

---

## 6. 实施顺序

### 第 0 步(阻塞后面一切)

1. **`git init` 并提交当前状态。** 本目录还不是 git 仓库,而埋点会铺开到十几个文件,
   没有回退能力风险太大。多份文档都提过,至今未做。
2. 更新或废弃 `ANALYTICS.md`:补 `challenge` 模式、`bakery_level` 改 1–6。
   **不要让两套口径并存。**

### 第 1 步:外壳 + Analytics.gd

- 自定义 HTML shell(现在是空的):`page_open` 打点 → 加载计时 → 异步加载 PostHog SDK
- 新建 `scripts/Analytics.gd` 作为 Autoload(`project.godot` 需新建 `[autoload]` 段),
  统一 `log(event, props)`;非 Web 与 SDK 未配置时安全退化,不阻塞启动
- 身份:`distinct_id` 交给 PostHog;`visit_id` / `session_id` / `run_id` / `attempt_id` 自己生成
- 成功事件在**状态确实变更成功后**才发;界面重绘、语言切换、恢复结算页不得重复计通关

### 第 2 步:考核埋点(优先于问卷)

挑战考核是本作唯一的真实失败墙,也是复活意愿唯一可信的观测点。机制已就位,挂事件成本最低。

### 第 3 步:问卷 + 五秒占位等待(按 §3.2 的已定流程)

### 第 4 步:正式导出、包体测量、真机验证

---

## 7. 仍未定(不要自行决定)

以下出自 `PLAYTEST_DECISIONS.md` 的「下一轮待定」,**仍然未定**:

1. **普通第八天失败是否仍可多次当天重试**
   —— 注意:挑战考核已限一次,普通八日目前仍是**无限次**,两者不一致,需要用户拍板
2. 入口文案本轮写「看广告」还是按实际条件写「填问卷 / 等待」(本轮不接真实广告)
3. 问卷提交时网络失败如何处理
4. 首次会话有效时长、静置、后台、结算阅读的口径
5. 次日回访用 24 小时还是日历日
6. 自有站小测结束、可提交 CrazyGames 的标准
7. 平台版是否保留第三方统计与问卷(须先核实平台要求)

§6 的第 0 步和第 1 步不依赖以上任何一条,可以先动。

---

## 8. 回归底线

改动涉及结算卡或输入层时,按 `AGENTS.md` 跑既有回归项:

- 信封点开不立即关闭,结算期间仍可打开
- 语言只切换一次,新增文案中英齐全
- 结算时 Dock 隐藏且 z 保持 8,不挡 CTA
- 烤炉烤到 100% 后仍能结束并重置
- 网页问卷层不得穿透点击到 Godot 画布;关闭后输入恢复正常
- 不得为接 SDK 删掉 `export/web/_headers` 里项目要求的 COOP/COEP

现有冒烟测试:

| 场景 | 覆盖 |
| --- | --- |
| `tests/TutorialSmokeTest.tscn` | 教程 8 步 |
| `tests/LayerSmokeTest.tscn` | 层级 |
| `tests/GateRetrySmokeTest.tscn` | 考核失败一次机会、存读档、长局保护 |
| `tests/EndlessSmokeRunner.gd` | 需隔离 APPDATA 运行 |

```bash
"E:\小游戏\Godot\Godot_v4.7.1-stable_win64_console.exe" --headless --path "E:\小游戏\Godot\chickenstock-yixuan" res://tests/GateRetrySmokeTest.tscn
```

成功标志是打印 `*_SMOKE_OK`。断言失败时进程会停住且不打印 OK ——
**不要把「没报错」当成通过**,要确认看到 OK 那一行。
