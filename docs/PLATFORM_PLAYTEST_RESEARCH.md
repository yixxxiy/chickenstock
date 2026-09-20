# 小鸡股市：平台测试与变现路线核实

查询日期：2026-09-17。只使用官方一手文档；本次没有注册账号、提交游戏或接入 SDK。本文为研究记录，不代表已决定发行平台。

## CrazyGames

- 游戏提交后先经过 QA；Basic Launch 是限量测试，表现好才有机会被选入 Full Launch，不是上传即上架，也不是等时间到了就自动赚钱。[官方流程](https://docs.crazygames.com/)
- Basic Launch 持续 7–21 天：至少上线 7 天且达到 500 plays 后结束；不足 500 plays 则到第 21 天自动结束。plays 不等于独立玩家数。[Basic Launch Guide](https://docs.crazygames.com/resources/basic-launch-metrics/)
- Basic 自动统计单次平均游玩时长、D1 回访、开始后玩满一分钟的 conversion；仪表盘每日更新，无需 SDK。官方列出的较好表现参考为平均 10+ 分钟、D1 10–15%、一分钟 conversion 80%+，这些是参考，不能当保送通过门槛。[Basic Launch Guide](https://docs.crazygames.com/resources/basic-launch-metrics/)
- Basic 中 SDK 可选，广告关闭，不能使用外部广告；Full 需要 SDK 集成，主要通过平台广告分成变现。[要求总览](https://docs.crazygames.com/requirements/intro/)
- 平台默认指标能回答整体投入与回访；本项目的第 8/12/16/20 天通关、具体复活入口和恢复后行为仍需游戏事件。官方推荐额外行为分析工具 ByteBrew，说明并非一概禁止第三方统计；没有找到对 PostHog 的明确逐名许可。[分析说明](https://docs.crazygames.com/requirements/intro/#insights-analytics)
- 额外收集 SDK 事件以外的个人数据，平台要求向新玩家展示条款或隐私说明，建议不阻断玩法。[User Consent](https://docs.crazygames.com/requirements/technical/#user-consent)
- 提交包需英语本地化。无 SDK 时总包上限 50MB；进入移动首页的初始包上限 20MB。允许竖屏游戏，但桌面 iframe 也要可读、可操作。[玩法要求](https://docs.crazygames.com/requirements/gameplay/)、[技术要求](https://docs.crazygames.com/requirements/technical/)

**未知项**：公开页面没有直接确认“首次奖励入口填六题问卷，之后五秒模拟广告”在 Basic 是否会获准。不要从“允许第三方统计”推导“奖励问卷一定获准”；正式准备平台包时需向平台核实。Basic 不提供真实广告，因而不能用这阶段验证广告完播率或收入。

## Poki

- 公开入口是申请 Poki for Developers 访问权限，提交个人/团队和作品信息后等待联系；不是完全无审核的自助发布。[申请入口](https://developers.poki.com/guide/share)
- 路线为上传并过内容检查 → 每轮 10 个试玩录像 → Player fit test（500 玩家，约 5 小时）→ Web fit test（约 7 天）→ 最终人工审核（1–2 周）。官方还写通过后从协议到全球发布约 2–3 个月。[测试流程](https://developers.poki.com/guide/how-testing-works)
- Player fit 主要看时长，Web fit 看点击率、页面时长和进入游玩的转化。因此它也能减少人工招募负担，但不是交包后立刻得到全套商业验证。[测试流程](https://developers.poki.com/guide/how-testing-works)
- 真实广告全部走 Poki SDK；激励视频必须由玩家主动选择，是额外奖励。收益取决于协议，不在这里估算 CPM、填充率或收入。[变现说明](https://developers.poki.com/guide/how-monetization-works)
- Poki SDK `measure()` 支持自定义进度和交互事件；广告入口曝光/点击由游戏发送，真实广告播放和结果由广告 SDK 自动记录。可用于本项目的通关、复活漏斗。[Game Events](https://developers.poki.com/guide/game-events)
- 默认阻止外部请求；第三方统计需逐项申请 CSP 批准及提供隐私页面。PostHog 和问卷后端不能假定直接可用。[外部资源政策](https://developers.poki.com/guide/external-resources-policy)
- 当前合作说明要求网页独家，不能同时发布到其他网页游戏平台；适用条款与自有测试站安排需以签署协议确认。不能把 Poki 和 CrazyGames 当作随意同时铺量的组合。[合作说明](https://developers.poki.com/guide/working-with-poki)

## 对当前测试设计的含义（推论，非平台承诺）

1. CrazyGames Basic 更接近用户记忆中的“考察期”，适合用陌生平台流量检验首次投入和 D1；不能代替真实广告变现测试。
2. 自有 Netlify 测试可保留首次六题问卷、之后五秒 placeholder。分别标记 `survey`、`placeholder`、未来 `real_ad`，不合并成真实广告完播。它们可提供复活意愿信号，但不证明真实广告收益。
3. 平台基础统计不能自动知道游戏内通关或重玩原因；如果这些是必须回答的 KPI，仍应留最少量关键事件。Poki 自有事件接口能减少额外统计接入。
4. 建议先决定“平台测试替代自有测试”还是“两个渠道分别测试”。平台流量与朋友/学校群流量分开报告；广告/问卷条件不一致时不能把留存差异简单归因为玩法。

## 尚未确定

- 本项目会否被任一平台接受、何时给流量、能否达到 Full Launch、最终商业条款。
- CrazyGames 对本项目具体问卷奖励方案的接受情况；Poki 是否批准所选外部统计与问卷服务。
- 当前导出包是否符合尺寸/加载要求；本次没有检查构建产物或进行平台内运行测试。
