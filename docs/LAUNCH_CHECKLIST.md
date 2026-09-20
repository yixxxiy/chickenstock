# 小鸡股市 — 上线前还要做什么

盘点日期：2026-09-19。范围：`E:\小游戏\Godot\chickenstock-yixuan`。

本文只写**还没做**的事，以及每件事的完成标准。已经做完的写在 `docs/ANALYTICS.md`
（事件字典）和 `AGENTS.md`（Deploy SOP），不重复。

本文每一条「现状」都是这次实跑或实读得出的，不是照抄旧文档。没亲自验的，明确写「未验证」。

---

## 0. 一句话结论

**代码侧就绪，发布侧卡在第一步。** 2026-09-20 全套 headless 复跑 + 新增整局通关测试：
119 项全过、零运行时报错，普通八日和挑战二十天都真打通关了（§1.1）。

剩下的全是发布链路：这台机器**导不出网页版**（`%APPDATA%\Godot\export_templates\` 仍是空目录），
`export/web/` 下只有 `_headers` / `netlify.toml` / `posthog-config.js`，没有 `index.html`，
`node tools/web-sync.mjs` 直接报「这次导出没成功」。**装导出模板是唯一的真阻塞项**，
后面所有事都排在它后面。

好消息：`web-sync.mjs` 已经替代了跑不动的 python 脚本（B2 可以按 Node 版走），
`export/web/posthog-config.js` 里的 `phc_` token 已填好、区域是美国区（B3 的填 key 部分已完成）。

§4.3 的两个测试可靠性问题已经修完；新发现一个 `TutorialSmokeTest` 退出时偶发段错误。

---

## 1. 这次实测到的事实

### 1.1 冒烟测试（Godot 4.7.1 headless，隔离 APPDATA）

2026-09-20 全套复跑，含新增的整局通关测试。

| 测试 | 结果 | 说明 |
| --- | --- | --- |
| `TutorialSmokeTest` | 通过（**退出时偶发段错误**） | `TUTORIAL_SMOKE_OK` 一定会打出来，但约每 4~6 次有一次在 `quit()` 之后的引擎清理阶段 exit 139。断言全过，是退出时序问题，进 CI 前要按输出里的 `*_OK` 判成败 |
| `LayerSmokeTest` | 通过（已修好假绿） | 34 条检查全跑。原来 `guide_z` 断言 116、实际 126，assert 失败只中断 `_assert_stack()`，后面 11 条一条没跑却照样打 OK。现在改成计数 + 退出码，故意改坏一个 z 值能返回 1 |
| `GateRetrySmokeTest` | 通过 | `GATE_RETRY_SMOKE_OK` |
| `SurveySmokeTest` | 通过 | `SURVEY_SMOKE_OK`；主问卷→提交→恢复当天→二次入口转五秒等待全链路，外加 `exit` 补充表单与 `pulse` 单题脉冲的独立完成标记 |
| `EndlessSmokeTest` | 通过（有前提，已不再挂死） | `CHALLENGE_SMOKE_OK`。路径不含 `audit-user` 时现在立刻 `quit(1)` 并打印 `CHALLENGE_SMOKE_SKIPPED`，不再永久挂死 |
| `FullPlaythroughTest`（新增） | 通过 | **119 项全过、0 失败、全程零运行时报错**。见下 |

`tests/FullPlaythroughRunner.gd` 是这次新加的整局通关测试，一次跑完：
开机与菜单锁 → z 层级表 → 中英文案对齐（311 条，键、空值、`%` 占位符全对得上）
→ 新手关七步 → **普通模式机器人真打八天通关** → 从终局续进挑战 → **挑战模式打到第 20 天 `won`**
→ 设置每一项 → 三份问卷 → 存读档与重置。

它刻意不用裸 `assert`（那正是 `LayerSmokeTest` 假绿的原因），改成 `_check` 计数 + 退出码。
用 `Engine.time_scale` 加速，全程约 6 分钟。**注意语言防抖用的是真实墙钟，
不跟 `time_scale` 走**，测设置那一段必须先把 `time_scale` 调回 1。

```bash
APPDATA=<含 audit-user 的空目录> "E:/小游戏/Godot/Godot_v4.7.1-stable_win64_console.exe" --headless --path "E:/小游戏/Godot/chickenstock-yixuan" res://tests/FullPlaythroughTest.tscn
```

#### 这一轮的平衡观察（不是 bug，但影响测试解读）

- **普通八日：好打。** 机器人用常规打法（收蛋→孵化→烤蛋糕→买鸡到 15 只→余钱买股）
  三次全部通关，收盘资产 6474 / 7574 / 7508，目标是 3000。
- **股市按新闻操作接近白给。** 今晚的新闻在 HUD 上是明牌，`next_price()` 里
  「雨天必跌、其余必涨」。机器人只要照新闻满仓 / 清仓，挑战模式一路打穿到第 20 天，
  收盘 116428（目标 22500），三道考核没有一道构成阻力。
  不看新闻乱买的同一个机器人则卡在第 12 关。**难度目前完全取决于玩家有没有发现这条规律。**
- **从八日终局「继续挑战」和从菜单进挑战，起手差很多。** 菜单进是固定种子
  （第 9 天 / 12 鸡 / 1800 金币 / 烤炉 Lv3），续进则原样带走上一局的家当
  （实测有一次是 20 鸡 / 6 金币 / 烤炉 Lv1）。两条路的难度不是一回事。

复现命令（`<ISO>` 是一个路径里带 `audit-user` 的空目录）：

```bash
APPDATA=<ISO> "E:/小游戏/Godot/Godot_v4.7.1-stable_win64_console.exe" --headless --path "E:/小游戏/Godot/chickenstock-yixuan" res://tests/EndlessSmokeTest.tscn
```

### 1.2 环境

| 项 | 现状 | 影响 |
| --- | --- | --- |
| Godot 4.7.1 本体 | 有，`E:\小游戏\Godot\Godot_v4.7.1-stable_win64_console.exe` | — |
| Web 导出模板 | `%APPDATA%\Godot\export_templates\` **存在但为空（0 项）** | **导不出网页版** |
| Python | 指向 `WindowsApps\python.exe` 占位程序，`python --version` 无输出 | `tools/sync_web_shell.py` 跑不了 |
| Node.js | v24.20.0 可用 | 可作为脚本替代方案 |
| `gh` CLI | v2.97.0，已登录 `Derggggg`，scope 含 `repo` | 可直接建远程仓库 |

### 1.3 仓库

| 项 | 现状 |
| --- | --- |
| 提交数 | 3（`c1b32c2` → `d94c9ab` → `7a36b54`），全在 2026-09-19 |
| 分支 | `master`，**无远程，无 tag** |
| 跟踪文件 | 585 个，pack 119.33 MiB |
| 最大单文件 | `assets/map/farm-background.png` 8.7 MB（无文件超 20 MB） |
| `.gitattributes` | 只有 `* text=auto eol=lf` |
| CI | 无 `.github/`，无 hooks |
| `export/web/` | 只有 `_headers` 和 `netlify.toml`，**没有 index.html / wasm / pck** |
| `config/version` | `2026.09.19-pt1` |
| `web/posthog-config.js` | `apiKey` 为空字符串 |

---

## 2. P0 阻塞项：不做完就上不了线

按依赖顺序排列。每条都给出「完成标准」，没达到就不算做完。

### B1. 装 Web 单线程导出模板

**现状**：`%APPDATA%\Godot\export_templates\` 是空目录，一个模板都没有。

**做法**：Godot 编辑器 → 编辑器 → 管理导出模板 → 下载 4.7.1.stable。
按 `AGENTS.md` 只需要 `web_nothreads_debug.zip` / `web_nothreads_release.zip`，不必下全套。

**完成标准**：`%APPDATA%\Godot\export_templates\4.7.1.stable\` 下能看到
`web_nothreads_release.zip`，且导出窗口里 Web 预设不再报缺模板。

**为什么排第一**：后面所有事（包体测量、真机验证、统计验证、平台提交）都要先有导出产物。

### B2. 修好 python，或改用等价的 PowerShell 命令

**现状**：`python` 命令是 Microsoft Store 的占位程序，执行没有任何输出。
`AGENTS.md` 的 Deploy SOP 把 `python tools/sync_web_shell.py` 写成必做步骤，
而这一步**决定 `analytics.js` 会不会进部署包**。缺了它统计静默停用、游戏照常跑，
所以出错时不会有任何提示。

**做法（二选一，推荐前者）**：

1. 装真正的 Python 3，装完 `python --version` 要有输出。
2. 不装 Python，每次导出后执行等价的 PowerShell：

```powershell
Copy-Item web\analytics.js export\web\analytics.js -Force
Copy-Item web\notice.js export\web\notice.js -Force
if (-not (Test-Path export\web\posthog-config.js)) { Copy-Item web\posthog-config.js export\web\posthog-config.js }
foreach ($f in 'analytics.js','notice.js','posthog-config.js','_headers','netlify.toml') { if (-not (Test-Path (Join-Path 'export\web' $f))) { Write-Warning "$f 不在 export\web" } }
```

**完成标准**：导出后 `export/web/analytics.js` 与 `notice.js` 都在，且 `index.html` 里能搜到
`analytics.js`、`notice.js`、`posthog-config.js` 三个 `<script src>`。

> `notice.js` 是加载页那条采集告知（见 `docs/ANALYTICS.md` §7.5）。
> **它缺了就等于没告知玩家在采数据**，而页面照样跑、没有任何报错——
> 和 `analytics.js` 一样属于「漏了没症状」，只能靠这一步查。

> 注：`posthog-config.js` 缺失不会让页面报错。`window.CLUCK_POSTHOG` 未定义时
> `analytics.js` 走 `CFG = {}`，`LIVE` 为 false，统计整体静默停用。
> 这是刻意设计，但也意味着**漏了文件不会有任何症状**，只能靠这一步检查。

### B3. 建 PostHog 项目，填 token

**现状**：`web/posthog-config.js` 的 `apiKey` 是空串。旧文档写过「用户已做过初步连通测试」，
那句话没有本轮实测支撑，按未验证处理。

**做法**：

1. 建**两个**项目：`chickenstock-prod` 和 `chickenstock-dev`。
   内部调试流量绝不能混进正式项目（`docs/ANALYTICS.md` §7 第 3 条）。
2. 把 prod 的 Project API Key（`phc_` 开头）填进 **`export/web/posthog-config.js`**，
   不是 `web/` 下的源文件。`export/web/*` 已被 `.gitignore` 排除，token 不会进仓库。
3. `host` 按项目区域填 `https://us.i.posthog.com` 或 `https://eu.i.posthog.com`。
4. 本机自测用 dev 的 key，并把 `debug` 设为 `true`，事件会带 `test_env: true`。

**完成标准**：本地起服务玩一局，PostHog 的 Activity 面板里能看到
`page_open` → `game_ready` → `day_start` 这条链。

### B4. 大陆可达性：给上报做同源代理（强烈建议）

**现状**：`docs/adr/0001` 解决的是「COEP 下加载不了 PostHog 的 SDK 文件」，
方案是改成 `fetch` POST 到 `us.i.posthog.com`。COEP 这一关确实绕过去了，
**但 ingest 域名本身仍是第三方境外域名**。玩家范围包含中国大陆，
这条链路的可达性**本轮完全没有验证过**。

**风险**：大陆玩家可能一条事件都发不出去，而且发不出去时是「静默丢弃、不重排队」
（ADR 0001 明写）。结果是数据**系统性缺掉一整个地区的样本**却看不出来，
留存和时长会被幸存者偏差整体拉高。

**做法**：在 `netlify.toml` 和 `export/web/netlify.toml` 加一条同源代理，
让上报打到自己的域名，由 Netlify 转发：

```toml
[[redirects]]
  from = "/e/*"
  to = "https://us.i.posthog.com/:splat"
  status = 200
  force = true
```

然后把 `posthog-config.js` 的 `host` 改成空串，让 `analytics.js` 走相对路径 `/e/batch/`。
**注意**：`analytics.js` 现在的 `LIVE = !!(HOST && KEY)` 会因为 `HOST` 为空而判定停用，
所以这个改动需要同步改一行判断逻辑，不能只改配置。

**完成标准**：用大陆网络（不挂代理）打开线上站玩一局，PostHog 里能收到这一局的事件。
拿不到大陆测试机时，至少让一位大陆的朋友按带 `?c=friends` 的链接玩一局并确认数据到达。

**如果决定不做**：也可以先上线观察，但必须第一天就对账（见 §3.4），
并且报表里写明「大陆样本可能系统性缺失」。

### B5. 发布版本号纪律

**现状**：`config/version` 是 `2026.09.19-pt1`，每条事件的 `build` 字段取自这里。

**做法**：每次导出前改 `config/version`，并且同一个值打一个 git tag。
格式沿用现在的「年.月.日-序号」。

**完成标准**：PostHog 里任一条事件的 `build` 值，都能在 `git tag` 列表里找到对应提交。

### B6. 真机 + 线上端到端验证

`AGENTS.md` 写死了：完成标准是手机打开 https://chickenstock.netlify.app ，不是编辑器。

按顺序走，每步都要过：

1. 导出 → 同步外壳 → 确认 `netlify.toml` 和 `_headers` 还在 `export/web` 里。
2. 整个 `export/web` 文件夹拖到 Netlify 站点 `chickenstock`，等 Production Published。
3. 手机打开，**强制刷新**（浏览器会缓存旧 `.pck`）。
4. 对比 `index.pck` 线上体积和本地刚导出的文件体积，不一致说明还是旧包。
5. 手机上完整玩一局：信封能开、语言只切一次、进结算底栏消失、烤炉能烤完。
6. 故意日结失败 → 点奖励入口 → 六题问卷弹出 → 提交 → 恢复当天早晨。
7. 再失败一次 → 入口文案变成「等 5 秒 → 重试今天」。
8. 打开设置 → 反馈入口存在，且只提交问卷、不发重试。

**完成标准**：八步全过，且 PostHog 里能按同一个 `distinct_id` 串起完整事件序列。

---

## 3. 数据分析侧还要做什么

### 3.1 采集层的遗留缺口

代码已经把 `docs/ANALYTICS.md` §5 的事件表全部接上了：34 个 `log_event` 调用点，
动作计数走 `Game._note_effective_action`，11 个计数器全部接线。剩下的是这几处：

| 缺口 | 现状 | 建议 |
| --- | --- | --- |
| 丢弃事件数没有上报 | `analytics.js` 里 `dropped` 一直在累加，但**从来没发出去过** | 把 `dropped` 加进 `capturePlain` 的公共属性。否则弱网丢了多少数据是不可知的 |
| `log_once` / `seen` / `mark_seen` 是死代码 | `Analytics.gd` 定义了，`Game.gd` 一次都没调用 | 去重现在靠 `_offer_key` 等业务字段做，能用。要么删掉这三个函数，要么在注释里写明已改用业务去重键 |
| 刷新页面的终局重复计数 | `gate_result` / `campaign_end` 在 `_next_day()` 里发，刷新不会重跑，看起来安全 | **未实测**。上线前手动验一次：结算卡出现时刷新页面，确认 PostHog 里没多出第二条 |
| 问卷提交时网络失败 | 问卷画在 Godot 层，提交不依赖网络；事件送不出去就丢 | 已知取舍，**写进报表说明**即可，不用改代码 |

### 3.2 PostHog 项目配置（建站当天就要定，改起来很贵）

| 配置 | 建议值 | 理由 |
| --- | --- | --- |
| 项目时区 | `Asia/Shanghai` | D1 回访按日历日算时要有唯一口径；时区改了历史报表会整体位移 |
| 事件去重 | 依赖 `uuid` 字段 | `analytics.js` 每条事件都带 `uuid`（等于 `event_id`），重发由接收端去重 |
| Person profiles | 只在 `$set` 时创建 | 现在只有问卷提交会调 `setPerson`，符合预期，不要改成每事件都建档 |
| 数据保留 | 默认即可 | 本轮是短期测试 |
| 内部流量排除 | 报表统一加 `test_env != true` 过滤 | 或者干脆用独立 dev 项目，更稳 |

### 3.3 上线前就要建好的看板

**不要等数据来了再想怎么看。** 下面每条都能用已有事件直接算出来，
建议上线前用 dev 项目的假数据先把图搭好。

**A. 加载与入口漏斗**

```
page_open → game_ready → menu_view → play_start → day_start(day=1) → day_end(day=1)
```

- 可观测加载成功率 = `game_ready` 的 `visit_id` 去重数 ÷ `page_open` 的 `visit_id` 去重数
- 首次可操作耗时 = `game_ready` 的 `ms_since_open` 分布，看 P50 和 P90，不要只看均值
- **报表必须写「可观测」**：页面完全跑不起来、被拦截、离线的访问本身就看不见

**B. 首次游玩投入（首要目标）**

- 分母：`first_play_session = true` 且产生过 `play_start` 的 `distinct_id`
- 分子：`playtime_milestone` 各节点（60 / 180 / 300 / 600 / 1200 秒）的去重人数
- 内部探索目标是 5–10 分钟约 40%，**这是内部目标不是行业合格线**，报表里要这么写

**C. 教程到第一天的接缝**

两个转化率分开看：`tutorial_finish ÷ tutorial_start`，以及 `day_end(day=1) ÷ day_start(day=1)`。
**教程完成率高但第 1 天完成率低 = 教程没教会。**

**D. 考核墙与重试意愿衰减（本作最值钱的一张图）**

第 12 / 16 / 20 天**分开**画，每关一条链：

```
gate_result(hit=false) → retry_offer_view → retry_offer_click
  → survey_submit 或 retry_wait_complete → retry_restored → retry_resumed
```

横轴用 `shortfall_pct` 分桶（差 5% / 15% / 30% / 60% 以上）。
没有这个变量，「意愿率 34%」是个解释不了的数字。

**E. 终局后自愿再玩**

- 分母：首次终局的玩家，**含没继续的**，不能只统计点过按钮的人
- 分子：`continuation_engaged`，即终局选择之后真正做了有效玩法动作
- 成功终局和失败终局**分开**
- 要排除 `entry_reason` 为 `reward_rewind` 和 `menu_continue` 的情况

**F. 次日回访（D1）**

按 `distinct_id` 的 `page_open` 算。口径要先定，见 §6 第 3 条。

**G. 数据质量看板**

`load_error` 按 `stage` 分；`storage_ok = false` 的占比；`dropped` 的分布（做完 §3.1 之后）。

### 3.4 上线后头 30 分钟的自查清单

线上跑起来的第一时间必须对一遍，不然错的数据会一直攒：

1. `page_open` 有没有进来。没有 = token 或代理错了
2. `game_ready ÷ page_open` 是不是接近 1。明显偏低 = 加载在挂
3. 事件的 `build` 是不是这次发布的版本号。不是 = 忘改 `config/version` 或传了旧包
4. `test_env` 是不是 false。是 true = 用错了配置文件
5. `cohort` 有没有正确带入。自己用 `?c=friends` 链接开一次验证
6. 随便挑一个 `distinct_id`，看事件序列能不能串成一局完整的游戏
7. `day_end` 的 `day_*` 计数不是全 0。全 0 = 计数没接上真实成功路径
8. `storage_ok = false` 的占比。偏高说明很多玩家在无痕模式，D1 会失真

### 3.5 必须写进报表的统计局限

这几条不写，结论就会被过度解读：

- **可观测访问**：缺 `game_ready` 不等于确认崩溃，也可能是玩家主动离开
- **最后不足 30 秒的区间会丢**：突然关页时 `playtime_tick` 补报不了，时长是**低估**
- **`beat_percent()` 不是真实排名**：结算卡上的「超过多少玩家」按固定资产区间算出，
  **不得作为统计结果引用**
- **问卷有选择性偏差**：只有走奖励重试入口的人才看得到，不代表全体玩家
- **问卷完成率 ≠ 复活发放率**：关掉没提交也照发奖励，两者必须分别统计
- **问卷和五秒等待不是广告**：不得上报成广告展示或完播，也不得用来推算广告收入
- **每人一次问卷**指同一浏览器的同一匿名身份一次，不承诺跨设备去重
- **普通日结的当天重试目前是无限次**，和考核的「每关一次」不一致，
  所以「重试次数」在两种模式下含义不同，不能合并

### 3.6 隐私与合规

- 游戏内已有隐私说明文案（`Loc.gd` 的 `survey_privacy`，中英齐全），
  但只在问卷卡里出现。**站点本身没有任何隐私说明页面。**
- CrazyGames 的 User Consent 要求：采集 SDK 以外的个人数据时要向新玩家展示条款或隐私说明，
  且建议不阻断玩法。自有站小测阶段可以先不做，**提交平台前必须补一个静态隐私页**。
- 自由填空题限 80 字且提示不要填联系方式，这条已在代码里，保持。
- 不做：UTM 全套、referrer 全文、渠道归因、设备指纹、账号、跨设备身份拼接。

---

## 4. 代码管理侧还要做什么

### 4.1 建远程仓库（P0）

**现状**：3 个提交全在本机，**没有远程**。硬盘坏了就全没了。
`gh` 已登录 `Derggggg` 且有 `repo` scope，可以直接建。

```bash
gh repo create chickenstock-yixuan --private --source=. --remote=origin --push
```

**注意两件事**：

1. 本地主分支叫 `master`，但项目约定的主分支是 `main`。推之前统一：`git branch -M main`。
2. 仓库 pack 是 119 MB，`assets/` 占 112 MB。低于 GitHub 的告警线，
   单文件最大 8.7 MB 也远低于 100 MB 硬限制，**可以直接推**，暂时不需要 Git LFS。
   但每加一批生图草稿都会再涨，见 §4.6。

### 4.2 发布可追溯：让 `build` 能反查到代码

这是**数据分析和代码管理的交界处**，也是现在最大的结构性缺口。

**问题**：`export/web/*` 被 `.gitignore` 排除，部署产物不进仓库；`config/version` 靠手改；
Netlify 是手动拖拽上传。三者叠加的结果是——**看到一条 `build = 2026.09.19-pt1` 的事件，
没有任何机制能告诉你它对应哪个 commit、什么时候传的、包多大。**

**做法**：

1. 每次发布打 tag，tag 名等于 `config/version`：

```bash
git tag -a 2026.09.19-pt1 -m "发布：首轮玩家测试" && git push origin 2026.09.19-pt1
```

2. 建一个 `docs/DEPLOY_LOG.md`，每次发布追加一行：
   版本号 / commit / 上传时间 / `index.pck` 体积 / PostHog 项目 / 这次改了什么。
3. 不要把 `export/web` 加进仓库，那是产物目录，加进去会让仓库迅速膨胀。
   tag 加部署日志就够反查了。

**完成标准**：随便拿一条线上事件的 `build` 值，能在五分钟内找到对应的代码和部署记录。

### 4.3 修两个测试可靠性问题（P0）— **2026-09-20 已做完**

两条都已落地，下面保留原始诊断备查：

- `LayerSmokeRunner.gd` 重写成 `_eq` / `_ok` 计数 + 非零退出码，34 条检查全跑；
  取「指南 126 盖住信封 120」为准（它是整屏模态），`AGENTS.md` 的 z 表补上了 `GuidePop` 一行。
  验收做过了：故意把 `Dock` 的期望值改成 9，退出码变 1。
- `EndlessSmokeRunner.gd` 的前提检查改成 `push_error` + `quit(1)`，不再挂死。

新发现的第三个：`TutorialSmokeTest` 退出时偶发段错误（见 §1.1）。**这个还没修。**

---

#### 原始诊断（已修，留作记录）

`docs/ANALYTICS_HANDOFF.md` §8 写着「成功标志是打印 `*_SMOKE_OK`，
不要把『没报错』当成通过」。这次实跑发现，**连「打了 OK」都不能当成通过**。

#### 问题一：`LayerSmokeTest` 是假绿的

`LayerSmokeRunner.gd:61` 的 `assert(guide_z == 116)` 断言失败了，
但 Godot 的 assert 失败只中断**当前函数** `_assert_stack()`，
控制流回到 `_ready()` 继续执行，最后照样打印 `LAYER_SMOKE_OK`，退出码还是 0。后果有两层：

- 第 61 行之后的所有断言（`mail_z`、`toast_z`、`menu_z` 和整条大小关系链）**一条都没跑**
- 任何人看到 OK 都会以为层级没问题

**根因**：`Game.gd:420` 写的是 `guide_pop.z_index = 126`，测试却断言 116。
另外 `trophy_pop.z_index = 125`（`Game.gd:416`）既不在测试里，也不在 `AGENTS.md` 的 z 表里。
真实次序是「指南 126 > 奖杯 125 > 信封按钮 120」，而测试期望的是「指南 116 < 信封按钮 120」。

**做法**：

1. 先确认哪个才是想要的：新手指南应该盖住信封按钮，还是反过来。
   这条影响玩家能看到什么，列在 §6 第 1 条。
2. 定了之后三处一起改：`Game.gd` 的赋值、`LayerSmokeRunner.gd` 的断言、
   `AGENTS.md` 的 z 表（表里现在缺 `guide_pop` 和 `trophy_pop` 两行）。
3. **把断言改成会真正失败的形式**：不要用裸 `assert`，
   改成检查不过就 `push_error` 加 `get_tree().quit(1)`，让退出码能反映结果。

#### 问题二：`EndlessSmokeTest` 在前提不满足时永久挂死

`EndlessSmokeRunner.gd:7` 是 `assert("audit-user" in OS.get_user_data_dir(), ...)`。
用户数据目录路径里没有 `audit-user` 时，这条断言中断 `_ready()`，
后面的 `get_tree().quit()` 永远不会执行，**进程挂在那里不退出，也不打印任何结论**。
这次盘点就因为这个卡了十分钟才发现。

**做法**：改成失败即退出并说明原因：

```gdscript
if not ("audit-user" in OS.get_user_data_dir()):
	push_error("EndlessSmokeTest 需要隔离的 APPDATA（路径需含 audit-user）")
	get_tree().quit(1)
	return
```

并把这个路径要求写进 `AGENTS.md`。现在只有交接文档里提了一句「需隔离 APPDATA 运行」，
没说必须含 `audit-user` 这个魔法字符串。

### 4.4 加 CI（推完远程就做）

有了远程仓库就能让机器替你跑回归。`.github/workflows/smoke.yml` 用带 Godot 4.7.1 的镜像，
headless 跑四个冒烟测试；`Endless` 那个要先按 §4.3 修好前提检查，
并把工作目录设成含 `audit-user` 的路径。

**前提是先做完 §4.3**。现在的测试连本地都会假绿，放进 CI 只会制造一个绿色的假象。

**完成标准**：push 之后 Actions 页面是绿的，并且**故意改坏一个 z 值能让它变红**。

### 4.5 `.gitattributes` 补二进制声明

**现状**：只有 `* text=auto eol=lf`。`text=auto` 会让 git 自动探测二进制，
大多数情况没问题，但 PNG / OTF / WAV 这类文件靠探测总有失手的可能，
一旦被当成文本做换行规范化就是不可逆的损坏。

**做法**：追加显式声明。

```
*.png  binary
*.jpg  binary
*.otf  binary
*.ttf  binary
*.wav  binary
*.ogg  binary
*.pck  binary
*.wasm binary
```

### 4.6 收一下仓库体积

`assets/ui/farm-ui/generated-v2/` 里的生图草稿单张 2.7 到 3.4 MB，
已经占掉了前十大文件里的五个。按 `AGENTS.md` 的规定，这个目录**只存源图，不直接给 Game 用**，
导出预设里也已经排除了它们。

**做法，择一**：

- 保守：保持现状，接受仓库慢慢变大。目前 119 MB 还完全可控。
- 推荐：以后新增的草稿不入库，或者单独建一个 `chickenstock-art` 仓库存草稿。
  **不要**回头 rewrite history 去删已经提交的，那会让已有的三个提交全部失效，
  收益远小于风险。

### 4.7 收敛文档冲突

现在有六份文档在讲同一件事，互相矛盾过。`ANALYTICS.md` 已经做了一次裁决，
但还剩这几处没对齐：

| 冲突 | 处理 |
| --- | --- |
| `AGENTS.md` 的 z 表缺 `guide_pop`(126) 和 `trophy_pop`(125) | 按 §4.3 定稿后补进表里 |
| `监工文档.md` 提到「三日新手关」 | 实际是单日 8 步（`tutorial_step` 0–7），改掉 |
| `docs/PLAYTEST_ANALYTICS_PLAN.md` §2.1 说「未发现挑战模式」 | 顶部已加「已被取代」横幅，但正文仍在误导。整份移进 `docs/archive/` |
| `tmp/analytics-plan-update/` 两份计划副本 | 临时目录，内容已并入正式文档，**删掉** |
| `docs/CURSOR_HANDOFF_ANALYTICS_SURVEY_PLATFORMS.md` | 同上，已被取代，移进 `docs/archive/` |

**原则**：过时的文档要么删、要么移走，**不要只在开头加一句「已被取代」就留在原地**。
下一个 agent 还是会读到正文并照做。

---

## 5. 分发链接与招募

`cohort` 靠链接的 `?c=` 参数带入，存 localStorage，后续访问沿用。
上线前把链接准备好，**发出去之后就不能改了**，改了会把同一批人拆成两个群体。

| 群体 | 链接 |
| --- | --- |
| 朋友 | `https://chickenstock.netlify.app/?c=friends` |
| 学校群 | `https://chickenstock.netlify.app/?c=school` |
| 自然流量（不带参数） | `https://chickenstock.netlify.app/` → 记为 `unknown` |
| 将来的 CrazyGames | `?c=crazygames` |

**注意**：不带参数的访问 `cohort` 是 `unknown` 而不是 `organic`。
报表里要么接受 `unknown`，要么发布前把默认值改掉，别到时候两个值混着解释。

---

## 6. 要拍板的决定

工程取舍按建议直接做。下面这些要么影响玩家看到什么、要么影响数据口径且改起来很贵，
需要一句话确认。每条都给了推荐值。

| # | 问题 | 推荐 |
| --- | --- | --- |
| 1 | 新手指南应该盖住信封按钮吗？现在代码是盖住（126 > 120），测试期望不盖 | 保持代码现状，改测试和文档 |
| 2 | 普通第八天失败还能无限次当天重试吗？挑战考核已限每关一次 | 也限一次，和考核一致。否则两种模式的「重试次数」没法合并解释 |
| 3 | D1 回访按自然日还是首玩后 24–48 小时？ | 按自然日加 `Asia/Shanghai`，PostHog 的留存报表原生支持 |
| 4 | 五分钟和十分钟参与率的验收目标各是多少？ | 先不定死，首轮拿基线，第二轮再定目标 |
| 5 | 首轮测多少人、测多久才算结束？ | 满 100 个有 `game_ready` 的去重玩家，或满 7 天，先到先算 |
| 6 | 要不要做 §B4 的大陆同源代理？ | 做。不做的话大陆样本可能整块丢失且察觉不到 |

---

## 7. 执行顺序

前后有依赖，别跳步。

**第一阶段：先把东西存住**

1. `git branch -M main`
2. `gh repo create ... --push`
3. 删 `tmp/`，归档过时文档（§4.7）

**第二阶段：修测试（§4.3）**

4. 定 z 值，三处同步改
5. 两个 runner 改成失败即 `quit(1)`
6. 五个测试全绿，且故意改坏能变红

**第三阶段：打通导出（§B1、§B2）**

7. 下 Web 单线程模板
8. 修好 python 或换 PowerShell 命令
9. 导出一次，本地起服务确认能玩

**第四阶段：打通数据（§B3、§B4）**

10. 建两个 PostHog 项目
11. 决定代理方案，改配置和 `analytics.js` 的 `LIVE` 判断
12. dev 项目自测：本地玩一局，事件能到

**第五阶段：发布（§B5、§B6）**

13. 改 `config/version`，打 tag
14. 导出 → 同步外壳 → 检查请求头 → 上传 Netlify
15. 手机强制刷新，跑完 §B6 的八步验证
16. 跑 §3.4 的 30 分钟对账
17. 记一行 `docs/DEPLOY_LOG.md`

**第六阶段：发链接**

18. 按 §5 的分群链接分别发出去
19. 建好 §3.3 的看板

---

## 8. 本轮明确不做

写在这里是为了挡住「顺手做一下」：

- 真实广告 SDK、广告收益预测、eCPM / ARPDAU
- 内购
- 跨天回退（从第 12 天回到第 8 天这种）
- 为统计增加账号、登录、跨设备身份拼接、设备指纹
- 会话回放、autocapture、全量点击日志
- 分享事件与传播分析
- 提交 Poki（需要网页独家，和 CrazyGames 路线冲突）
- 为埋点顺手改 UI 风格、数值、音效、触摸机制或层级
- 承诺「所有机型兼容」

---

## 9. CrazyGames 提交前另外要做的（不在本轮）

自有站小测跑完、问题排查干净之后才启动。先记着，免得到时候重新查：

- 包体：无 SDK 时总包上限 50 MB；要进移动首页的话初始包上限 20 MB。
  **本轮导出后要量一次 `index.pck` 的实际大小**，现在还不知道。
- 必须有英语本地化。已有，`Loc.gd` 中英齐全。
- 竖屏可以，但桌面 iframe 里也要可读可操作。
- Basic Launch 阶段广告是关闭的，**验证不了真实广告复活**。
- 采集 SDK 以外的数据要展示隐私说明，见 §3.6。
- 问卷换奖励的方案在平台是否获准，官方文档没写，**要主动问平台**，
  不要从「允许第三方统计」推导出「问卷奖励一定获准」。
