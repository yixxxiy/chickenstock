# 小鸡股市 — 事件字典（唯一口径）

更新：2026-09-20。状态：**已实施**，未经真机与线上验证。

2026-09-20 改动：问卷扩成三份表单、加四道题（难度感受 / 没看懂的系统 / 停下来的原因 /
真广告意愿），`survey_version` 升到 2。玩法与奖励流程的埋点没动。见 §5.6。

本文取代以下三份文档在埋点上的说法。它们互相冲突过，现在只以本文为准：

| 文档 | 处理 |
| --- | --- |
| 本文旧版（09-13） | 已整体重写。旧事件名 `app_open` / `client_id` 等不再使用 |
| `PLAYTEST_ANALYTICS_PLAN.md`（09-19，§3.5–3.7） | **口径**（去重规则、归因边界、分母定义）采纳；**事件名与粒度**以本文为准 |
| `ANALYTICS_HANDOFF.md`（09-19） | 事件名与额度纪律采纳；`gameplay_summary` 与 `playtime_heartbeat` 已合并，见 §4 |
| `PLAYTEST_DECISIONS.md`（09-17） | 问卷流程与复活规则的权威来源，未改动 |

冲突已裁决的三处：

1. 计划要每 15 秒一条 `gameplay_summary`，交接书要 30 秒心跳且「绝不做每次操作的埋点」。
   **合并成一条 30 秒的 `playtime_tick`**，同时承担心跳与区间摘要，约 40 条/人。
2. 缺口字段：计划叫 `wealth_gap` / `birds_gap`，交接书叫 `shortfall_pct`。**三个都发**，
   前两个是绝对值，后一个是两项缺口里较大的那个百分比，用于分层。
3. 终局事件：八日保留 `campaign_end`；挑战考核用 `gate_result`，并在 `day_end` 上带 `terminal`。
   不再另发 `run_end`。

---

## 1. 接入结构

```
export/web/index.html（Godot 导出）
  └─ head_include 同步引入
       ├─ posthog-config.js   ← 线上 token，不进仓库
       ├─ analytics.js        ← 第一方客户端，源文件在 web/
       └─ notice.js           ← 加载页的采集告知，源文件在 web/
                ↕ JavaScriptBridge
       scripts/Analytics.gd（Autoload：Analytics）
                ↑
       Game.gd / SettlementCard.gd / SurveyCard.gd 里少量明确的状态事件
```

**为什么不引 posthog-js**：线上包带 `Cross-Origin-Embedder-Policy: require-corp`
（`AGENTS.md` 要求保留）。require-corp 下，跨域**资源加载**没有 CORP 响应头就会被浏览器拒绝，
PostHog CDN 上的 SDK 文件正属于这一类，而 CORP 头只能由 PostHog 的服务器发，我们改不了。
`fetch` 不受这条限制，所以同源加载 `analytics.js`，事件直接 POST 到 `/batch/`。
顺带解决了大陆玩家访问第三方 CDN 的可达性，也避免引入 autocapture。

**部署时必须做**：导出之后、上传之前跑一次

```bash
node tools/web-sync.mjs
```

它把 `web/analytics.js` 同步到 `export/web/`，并检查 `index.html` 真的引用了它、
`_headers` 与 `netlify.toml` 还在、`apiKey` 确实填了。任一项不过就非零退出，不要上传。
已存在的 `export/web/posthog-config.js` 不会被覆盖。

本机预览用 `node tools/web-serve.mjs`（普通静态服务器缺 COOP/COEP，Godot 会加载失败）。

> `tools/sync_web_shell.py` 和 `tools/serve_web.py` 是同功能的 Python 版本。
> 本机的 `python` 是 Microsoft Store 占位程序跑不了，所以正文用 Node 版。

**配置**：填 `export/web/posthog-config.js` 的 `host` 与 `apiKey`。
`apiKey` 留空时统计整体静默停用，游戏照常运行。只放可以公开的项目采集 token，
不要写管理密钥或 Netlify 凭证。

## 2. 标识分工

| 标识 | 存在哪 | 何时更换 |
| --- | --- | --- |
| `distinct_id` | localStorage `cluck_did` | 清网站数据、换浏览器或设备，或设置里点 **Reset Game** |
| `session_id` | localStorage `cluck_sid`，30 分钟无活动过期 | 过期后新会话 |
| `visit_id` | 内存，每次页面加载 | 每次刷新 |
| `run_id` | **游戏存档** `cluck-farm-v7.json` | 新开一局才换；续档保留 |
| `attempt_id` / `retry_index` | 同上 | 每次当天重试恢复成功后 +1 |
| `offer_id` | 同上（`offerId` / `offerKey`） | 每个新的「局+天+尝试」一个 |
| `decision_id` | 内存 | 每次终局后接受的选择一个，10 分钟过期 |
| `event_id` | 每条事件一个 UUID | 重发保留原值，供接收端去重 |

`run_id` 必须进存档：`_enter_play()` 的续档分支不重置任何状态，只放内存的话，
玩家刷新后继续玩会换新 `run_id`，第 1–8 天漏斗会断成两截。

**问卷完成状态**放 localStorage，三份表单各一个键：`cluck_survey_done`（奖励主问卷）、
`cluck_exit_done`（设置里的补充反馈）、`cluck_pulse_done`（回主菜单的单题脉冲），
和 `distinct_id` 同生共死。
游戏存档在网页上走 IndexedDB，是另一套存储，可被独立清除。
结算卡「再开一局」只删玩法存档，**不**换匿名身份、也不清问卷。
设置里的 **Reset Game** 会换新 `distinct_id`，并清问卷/首玩标记、成就和解锁，之后的事件算新玩家；
旧身份上的历史事件仍留在 PostHog，网页端删不掉。
「每人一次问卷」指同一浏览器的同一匿名身份一次，不承诺跨设备去重，也不做设备指纹。

## 3. 公共字段

每条事件都带：`schema_version`、`build`、`lang`、`cohort`、`test_env`、`storage_ok`、
`visit_id`、`session_id`、`distinct_id`、`run_id`、`attempt_id`、`retry_index`、
`mode`、`day`、`phase`、`source_offer_id`、`source_decision_id`、
`active_ms_total`、`first_play_session`、`event_id`、`ms_since_open`。

- `build` 取自 `project.godot` 的 `application/config/version`。**每次发布必须改**，
  否则不同版本的加载耗时、留存、包体混在一起没法比。
- `cohort` 由分发链接的 `?c=` 带入并记住（`friends` / `school` / `organic` / `crazygames`…）。
  这是样本分层，不是渠道归因：不采集 referrer 全文、UTM 全套或设备定向信息。
  朋友和学校协助测试与陌生自然流量不能混成一个群体。
- `mode`：`menu` / `tutorial` / `normal` / `challenge` / `endless`。**四种玩法模式，不是两种。**
- `phase`：`boot` / `menu` / `tutorial` / `play` / `settle` / `survey` / `wait`。

## 4. 有效游玩时长的口径

只有 `phase` 为 `tutorial` 或 `play` 时累计 `active_ms`：

- 页面隐藏不累计（`analytics.js` 监听 `visibilitychange`，回调切断计时）。
- 单帧跨度超过 2 秒不累计（切后台回来、系统休眠、断点）。
- 距上次输入超过 **60 秒**不累计。本作有自动生产，不能要求每秒点击才算在玩，
  但也不能让挂机页面一直涨时长。阈值写在 `Analytics.IDLE_CUTOFF_MS`。
- 结算阅读单独计进 `settle_ms`，不进 `active_ms`。
- 问卷和五秒等待都不计。

**`playtime_tick`**：每累计 30 秒有效时长发一条；日结、教学结束、回档前、切主菜单、
重开、页面隐藏时补报非空残区间（`reason` 字段说明是哪一种）。
它同时替代了计划的 `gameplay_summary` 和 `playtime_heartbeat`。

属性：`interval_id`、`interval_seq`、`reason`、`active_ms`、`settle_ms`、`is_tutorial`，
外加本区间的增量计数（见 §6）。**全部是增量**，PostHog 里按属性求和，
不能用事件条数代替动作数。

**已知限制**：突然关页仍可能丢掉最后不足 30 秒的区间。报表要写明。

**`playtime_milestone`**：首次游玩会话累计有效时长达到 60 / 180 / 300 / 600 / 1200 秒各发一次。
带 `seconds`、`first_play_session`。二十分钟之后 `active_ms_total` 继续累计，节点只是报表入口。

## 5. 事件表

### 5.1 加载与入口

| 事件 | 触发点 | 关键属性 |
| --- | --- | --- |
| `page_open` | `analytics.js` 执行时，**早于 Godot 引擎启动** | `referrer_kind`、`screen_w/h`、`dpr`、`ua_mobile`、`lang_hint` |
| `game_ready` | `Game._finish_boot()`，首个入口真正可操作 | `ms_since_open` 就是首次可操作耗时；`tutorial_resumed`、`has_save` |
| `load_error` | JS 侧：60 秒未 ready，或 ready 之前的 window error | `stage`（`ready_timeout` / `boot`）、`error_type` |
| `menu_view` | 主菜单显示 | `challenge_unlocked`、`endless_unlocked`、`has_save` |
| `menu_click` | 选中某入口 | `item` |
| `menu_click_locked` | 挑战/无尽被锁时点击 | `item`、`lock` |

可观测加载成功率 = 产生 `game_ready` 的 `visit_id` 数 ÷ 产生 `page_open` 的 `visit_id` 数。
**报表必须写「可观测访问」**：页面完全跑不起来、被拦截、离线时，这次访问本身也看不见。
缺 `game_ready` 不等于确认崩溃，也可能是玩家主动离开。

### 5.2 开始游玩与一局

| 事件 | 触发点 | 关键属性 |
| --- | --- | --- |
| `play_start` | 进入教程或正式玩法 | `entry_reason` |
| `run_start` | 新开一局或续档进入 | `continued`、`entry_reason`、`decision_id`、`previous_run_id`、`start_day` |
| `day_start` | 每一天开始 | `entry_reason`、`wealth`、`birds`、`coins`、`bakery_level`、`price` |
| `day_end` | 日结数据确定时 | 见下 |

`entry_reason` 枚举：`menu_new`、`menu_continue`、`tutorial_finish`、`next_day`、
`reward_rewind`、`restart`、`continue_challenge`。
**§7 的「自愿再玩」指标要排除 `reward_rewind` 和 `menu_continue`。**

`day_end` 除经济快照（`wealth`、`old_wealth`、`birds`、`hens`、`coins`、`shares`、`price`、
`bakery_level`、`cakes_sold`、`stock_profit`、`broken_eggs`）外，带 `how`（`dusk` / `manual`）、
`terminal`、`gate_day`、`gate_hit`，以及当天全部动作计数 `day_*`（见 §6）。
这些计数用来分开「挂机流失」和「操作到手抽筋还是输」——两种流失的解法完全相反。

### 5.3 教程

| 事件 | 属性 |
| --- | --- |
| `tutorial_start` | — |
| `tutorial_step_view` | `step` |
| `tutorial_step_complete` | `step`、`step_duration_ms` |
| `tutorial_finish` / `tutorial_abort` | `step`、`duration_ms` |

要看的接缝是两个转化率：`play_start ÷ tutorial_finish`，以及
`day_end(day=1) ÷ day_start(day=1)`。**教程完成率高但第 1 天完成率低 = 教程没教会。**

### 5.4 考核与终局

| 事件 | 触发点 | 属性 |
| --- | --- | --- |
| `quest_hit` | 普通八日局中首次双线达标（庆祝弹窗弹出时） | `wealth`、`birds`、`day`、`wealth_goal`、`flock_goal` |
| `gate_result` | 第 12 / 16 / 20 天考核判定完 | `gate_day`、`hit`、`wealth`、`wealth_goal`、`wealth_gap`、`birds`、`birds_goal`、`birds_gap`、`shortfall_pct`、`gate_retry_left` |
| `campaign_end` | 普通八日终局 | `quest_ok`、`wealth`、`birds`、`wealth_goal`、`flock_goal` |
| `settlement_cta` | 玩家在结算卡上做出选择 | `choice`、`decision_id`、`previous_run_id`、`result`、`terminal` |

`shortfall_pct` 是归因的核心变量：差 5% 和差 60% 的玩家复活意愿天差地别，
没有它，「意愿率 34%」是个无法解释的数字。第 12 / 16 / 20 关分别看，
得到的衰减曲线是未来定奖励频次的依据。

「打到终局」与「达到通关条件」分开；局数、尝试次数和去重玩家数分开。
结算卡上的「超过多少玩家」由 `beat_percent()` 按固定资产区间算出，
**不是真实玩家排名，不得作为统计结果引用**。

### 5.5 奖励重试

本轮没有真实广告。入口文案按实际条件写：第一次「填反馈 → 重试今天」，
之后「等 5 秒 → 重试今天」。**不得把问卷、入口曝光或占位等待上报成广告展示或完播，
也不得用它们推算广告收入。**

| 事件 | 触发点 | 属性 |
| --- | --- | --- |
| `retry_offer_view` | 入口**实际可见**时，按「局+天+尝试」去重 | `offer_id`、`offer_context`、`reward_type`、`required_wait_seconds`、考核缺口字段 |
| `retry_offer_click` | 点击入口 | 同 `offer_id` |
| `survey_view` / `survey_submit` / `survey_dismiss` | 问卷 | 见 §5.6 |
| `retry_wait_start` / `retry_wait_complete` | 五秒占位等待 | `offer_id`、`required_wait_seconds` |
| `retry_restored` | 快照**确实恢复成功**后 | `offer_id`、`offer_context`、`reward_type`，事件自带新的 `attempt_id` |
| `retry_resumed` | 恢复后**第一次完成有效玩法动作**，每个 offer 一次 | `offer_id`、`action` |

`offer_context`：`daily`（普通日结）/ `campaign_flop`（八日失败）/ `gate_flop`（考核失败）。

**`retry_resumed` 只由真正改变游戏状态的主动操作触发**（`Game._note_effective_action`）：
恢复画面、点结算卡按钮、烤炉自动出炉都不算，否则「点了按钮就走」会被误判成继续玩。

恢复之后的 `playtime_tick`、`day_end`、终局事件都带 `source_offer_id`。
归属持续到下一次重试恢复、新开一局或本次会话结束；再次恢复后切换归属，额外时长不重复计算。

**规则提醒**（出自 `PLAYTEST_DECISIONS.md`，不要重新设计）：
问卷没填完就关掉，**这次奖励照发**，稍后还能再填；主问卷提交成功后奖励入口不再弹问卷，
改成五秒等待。所以 **「问卷完成率」≠「复活发放率」，必须分别统计。**
（设置入口在主问卷交完之后换成 `exit` 补充表单，那份不发奖励，不影响这条规则。）

考核复活额度：第 12 / 16 / 20 天**各有一次**，互不影响；同一考核日第二次失败不能再复活。
代码已按此实现（`_gate_retry_used`），埋点复用 `_gate_retry_left()`，不要另写一套额度逻辑。
**注意：普通日结的当天重试目前仍是无限次**，与考核不一致，这条仍未拍板。

### 5.6 问卷

九道题库、三份表单，全部画在 Godot 层（`scripts/SurveyCard.gd`），不是 DOM 覆盖层
——见 §1 的 COEP 说明，以及 `_lock_web_gestures()` 在 document 上装的
`selectstart` / `touchmove` 拦截。

**设计原则：埋点能答的题一律不问。** 玩了多久、打到第几天、点了多少次、选了哪个模式、
什么设备，全都有数据。问卷只买三样东西：**主观感受、原因、意图**。

#### 三份表单

| `survey_form` | 位点 | 题目（顺序即展示顺序） | 完成标记 |
| --- | --- | --- | --- |
| `reward` | 奖励重试入口，首次点击时 | 画像四题 + `difficulty_feel` + `retry_reason` + `would_watch_real_ad` + `free_text` | localStorage `cluck_survey_done` |
| `exit` | 设置里的反馈入口，**主问卷交过之后**变成这份 | `difficulty_feel` + `unclear_system` + `stop_reason` + `would_watch_real_ad` + `free_text` | `cluck_exit_done` |
| `pulse` | 玩过一局后回主菜单，单题、不发奖励 | `stop_reason` | `cluck_pulse_done` |

**三个标记必须分开。** 合成一个布尔会让「交过主问卷的人再也问不到流失原因」，
而玩得最久的那批人恰恰最早交完主问卷。奖励入口那边的行为不变，仍然只看
`survey_done`：交过就改成五秒等待（`PLAYTEST_DECISIONS.md` 已定，不要重新设计）。

`pulse` 的门槛（`Game.PULSE_MIN_ACTIVE_MS`，现为 60 秒有效游玩）和抑制条件：
统计关着不弹、已弹过不弹、正要再开一局（终局决策未兑现）不弹、菜单上还有别的弹窗不弹。
**它是唯一能采到「不走奖励入口就离开」那批人的位点**，而那批人正是流失分析最需要的样本。

#### 本地怎么看

三份表单在编辑器里分别是 **F9 / F10 / F11**（只在 debug 构建有效，正式网页包是 release，
玩家碰不到）。需要它是因为：非 Web 环境 `Analytics.enabled` 是 false，有效时长压根不累计，
**主菜单脉冲在本地永远不会自己弹**（门槛是玩满一分钟）。

本地按键打开的问卷**不会真的上报**，但会把该发的事件打印到控制台（`Analytics.verbose`）。
要验证 PostHog 真收到数，必须用填了 `apiKey` 的网页导出。

#### 事件

| 事件 | 属性 |
| --- | --- |
| `survey_view` | `offer_id`、`survey_source`、`survey_form`、`survey_version`、`question_count` |
| `survey_submit` | 上列 + 已回答的字段 + `answered_count`、`dwell_ms`、`game_result` |
| `survey_dismiss` | 上列 + `dwell_ms`、`answered_count`、`last_question_key`、`last_question_index` |

`survey_source`：`daily` / `campaign_flop` / `gate_flop` / `settings` / `menu_return`
/ `debug_key`（本地调试快捷键，线上不会出现；万一出现要从报表里排掉）。

`question_count` 是**这一份表单**的题量（含自由文本）。三份表单长度不同，
完成度必须按它算比例，不能拿绝对答题数横着比。

`last_question_key` 是关掉前最后一次真正碰过的题（点 chip 或输入自由文本），
一题都没碰是空字符串、序号 -1。只看 `answered_count` 分不出
「开头就走」和「答到最后一题放弃」——这两种的改法不一样。
代码里直接赋 `LineEdit.text` 不会触发 `text_changed`，所以冒烟测试里它停在最后一颗 chip 上。

#### 答案枚举（稳定值，永不本地化）

| 字段 | 取值 | 它买到了什么埋点答不了的东西 |
| --- | --- | --- |
| `self_reported_skill` | `novice` / `intermediate` / `hardcore` / `undisclosed` | 分群 |
| `age_bracket` | `under18` / `18_24` / `25_34` / `35_plus` / `undisclosed` | 分群 |
| `gender` | `male` / `female` / `other` / `undisclosed` | 分群 |
| `genre_experience` | `never` / `rarely` / `occasionally` / `sometimes` / `often` / `undisclosed` | 分群 |
| `retry_reason` | `rules` / `too_slow` / `trade_regret` / `try_other` / `misclick_lag` / `other` | 当下这一次为什么想重试 |
| `difficulty_feel` | `too_easy` / `just_right` / `hard_but_fair` / `too_hard` / `unclear_why_lost` | 埋点只知道差多少没过（`shortfall_pct`），不知道玩家觉得是难还是没看懂。**这两种的修法完全相反** |
| `unclear_system` | `stock_price` / `bakery` / `hatching` / `day_timer` / `goal` / `all_clear` | 教程该改哪一步；和 `tutorial_step_complete.step_duration_ms` 交叉看 |
| `stop_reason` | `satisfied_done` / `too_hard` / `too_repetitive` / `boring_early` / `lag_or_misclick` / `no_time` / `other` | 埋点只能看到「后面没有事件了」，看不到为什么 |
| `would_watch_real_ad` | `yes_any_time` / `only_when_stuck` / `only_if_short` / `no` | 本轮没有真实广告，五秒占位等待测不出真广告意愿 |
| `free_text` | 限 80 字，提示不要填联系方式 | — |

**`would_watch_real_ad` 是意愿，不是完播率。** 它和 `retry_wait_complete` 一样，
不得用来推算广告收入或当成真实广告表现的证据。

**「未回答」与「不想披露」是不同的值**：未回答时这个属性根本不出现在事件里，
主动不披露是 `undisclosed`。

**只有画像四项写成 person 属性（`$set`）**。感受题随局变化，写成 person 属性会被
后一局覆盖，历史就没了——它们只留在事件上。

`survey_version` 现为 **2**（1 是旧的单表单六题版）。
题目、选项或表单组成有任何改动都要加一，否则新旧回答会被混在一张表里。

**采样偏差**：`reward` 的回答只来自愿意为重试付出代价的人，`exit` 只来自主动进设置的人，
`pulse` 只来自玩满一分钟又回过菜单的人。三者都是自选样本，报表分开列，不合并成「玩家认为」。

### 5.7 终局后自愿再玩

| 事件 | 触发点 | 属性 |
| --- | --- | --- |
| `settlement_cta` | 终局后接受某个选择 | `choice`、`decision_id`、`previous_run_id`、`result` |
| `continuation_engaged` | 该选择之后**第一次完成有效玩法动作**，每个 decision 一次 | `decision_id`、`action` |

`choice`：`restart`（重新开局）/ `continue_challenge`（八日通关后进挑战）/ `next_day`（普通续日，不建决策）。

失败终局的 `restart` 会经过主菜单再进新局，所以 `decision_id` 带 **10 分钟过期**：
玩家在菜单里逛太久再开的局不算这次终局带来的继续行为。
**页面刷新会丢掉待兑现的决策**（`_restart()` 已经删了存档），这部分样本单列。

主指标：首次终局玩家中，同一游玩会话内、**不经过问卷/等待奖励**，
主动开启后续玩法并完成有效操作的比例。
分母包括没有继续的终局玩家，不能只统计点过按钮的人；成功/失败终局分开。

## 6. 动作计数

`playtime_tick` 带本区间增量，`day_end` 带当天合计（同名加 `day_` 前缀）：

| 计数 | 来源 |
| --- | --- |
| `collect_egg_count` | `collect_egg()` |
| `hatch_start_count` / `hatch_collect_count` | `start_hatch()` / `collect_chick()` |
| `cake_sell_count` | `sell_cake()` |
| `stock_buy_count` / `stock_sell_count` | `buy_shares()` / `sell_shares()` |
| `chick_buy_count` / `hen_sell_count` | `buy_chick()` / `sell_hen()` |
| `bakery_upgrade_count` | `upgrade_bakery()` |
| `bake_start_count` / `bake_complete_count` | `_ignite_bake()` / `_advance_baking()`。**烤炉是自动推进的，记数量但不算主动操作** |
| `tap_count` / `hold_count` / `hold_duration_ms` | `_start_hold()` / `_end_gesture()` |
| `deny_funds_count` / `deny_resource_count` / `deny_other_count` | 各动作的失败分支 |

### 两个容易踩的坑

**一、`quiet` 参数不能用来区分测试调用。** 长按连点走的是
`_hold_fn.call(true)`，也就是 `quiet = true`，和冒烟测试同一个标记。
按 `quiet == false` 计数会漏掉绝大多数收蛋和卖蛋糕。
计数一律放在真实成功路径上，测试靠 `Analytics.enabled = false` 整体关掉。

**二、动作数与手势数分开。** 一次长按收 8 个蛋 = 1 次手势、8 次动作。
`_start_hold()` 是唯一的按压入口，`_end_gesture()` 是唯一的释放出口，
超过 260 毫秒算长按（和 `_hold_wait` 的阈值一致，两处要一起改）。

无效尝试同一原因在 600 毫秒内只算一次连续尝试：长按被挡住时，
一次按压会先后产生「首次点击」和「重复 tick」两次拒绝。

**不要给每次收蛋单独发事件。** 一局上千次点击，一个玩家就能吃掉几百条额度。

## 7. 额度

PostHog 免费额度 100 万事件/月。

- `playtime_tick` 30 秒一条，20 分钟会话约 40 条
- 离散事件约 80 条/人
- 合计约 **120 条/人** → 约 **8,000 名玩家/月**

三条保命规则：

1. `playtime_tick` 保持 30 秒，**不要更密**。
2. **绝不做每次操作的埋点。**
3. 内部调试流量用**独立 project**；必须共用时把 `posthog-config.js` 的 `debug` 设为 `true`，
   事件会带 `test_env: true` 以便在报表里排除。

## 7.5 加载页的采集告知

`web/notice.js`，随 `head_include` 在引擎启动之前执行，所以在 wasm 还在下载时就看得见。
游戏**真正可操作**（`game_ready`）之后淡出——不是「下载完成」就撤，
下载完到能点之间还有引擎启动和首屏，那段时间玩家还在看加载页。

文案（中英按 `navigator.language` 自动选，本轮定为**删档测试**）：

> 本次测试为删档测试。为了进行平衡性调整及性能优化，游戏将记录您的对局数据、
> 崩溃日志及行为习惯。所有收集数据仅用于本次测试调优。
> 不采集姓名、生日、联系方式或存档内容。

为什么写「删档」：存档只在玩家浏览器的 IndexedDB 里，没有服务器也没有账号，
版本迭代、换设备、清理浏览器数据都会没。写「非删档」是兜不住的承诺。

两条硬约束，改之前先看清楚：

- **`pointer-events: none`**，绝不吃点击。底下就是 canvas，本项目最贵的历史 bug 全在输入层。
- **不加载任何外部资源**（字体、图片、CSS 全内联）。线上包带 COEP require-corp。

**文案必须和实际采集行为对得上。** 加采集项之前先改这里，不是反过来。
下面 §8 列的那些「明确不做」，就是这条告知敢这么写的底气。

## 8. 明确不做

- UTM / referrer 全文 / 渠道归因 / 设备定向采集（marketing 归因在别的渠道做）
- 分享事件（传播分析，不在本轮）
- 每次收蛋、长按 tick 的全量日志
- 会话回放、全量自动点击采集
- 为统计增加账号、登录、跨设备身份拼接或设备指纹

## 9. 仍未定（不要自行决定）

1. 普通第八天失败是否仍可多次当天重试——挑战考核已限一次，普通八日目前仍是**无限次**，两者不一致。
2. 问卷提交时网络失败如何处理（当前问卷在 Godot 层，提交本身不依赖网络；
   事件送不出去会被丢弃，不会锁住游戏）。
3. 次日回访用自然日还是首玩后 24–48 小时；PostHog 项目报表时区。
4. 五分钟与十分钟各自的验收目标、首轮测试人数、实际设备/网络范围。
5. 自有站小测结束、可提交 CrazyGames 的标准；平台版是否保留第三方统计与问卷。

第 4 条会影响报表口径，但不影响已经落地的采集：`active_ms_total` 与分钟节点已经按
§4 的规则记录，定目标时直接取用即可。
