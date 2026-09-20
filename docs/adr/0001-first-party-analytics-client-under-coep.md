# 0001. 自己写统计客户端，不引 posthog-js

日期：2026-09-19
状态：已采纳

## 背景

线上包必须带 `Cross-Origin-Opener-Policy: same-origin` 和
`Cross-Origin-Embedder-Policy: require-corp`（`AGENTS.md` 明令不许删，
`export/web/_headers` 与 `netlify.toml` 各有一份）。

`require-corp` 下，任何跨域**资源加载**（`<script src>`、`<img>`、`<iframe>`）
如果响应没有带 `Cross-Origin-Resource-Policy`，浏览器会直接拒绝。
PostHog CDN 上的 SDK 文件正属于这一类，而这个响应头只能由 PostHog 的服务器发，我们改不了。

同时，玩家范围包含中国大陆，第三方 CDN 的可达性本身也是风险。

## 考虑过的选项

1. **去掉 COEP。** 本项目是单线程导出（`variant/thread_support=false`），
   不需要 SharedArrayBuffer，也就不需要跨域隔离，COEP 在这个包里确实是纯负担。
   但这违反 `AGENTS.md` 的一条硬规定，而且以后要开多线程时还得加回来。
2. **给 PostHog 的资源加 CORP。** 做不到，头由对方服务器发。
3. **把 posthog-js 打包进 `export/web/` 同源加载。** 可行，但要引入一个我们不读的
   构建产物（200KB 量级），而且它带来的 autocapture、session replay、
   surveys 都是本轮明确不做的东西。
4. **自己写一个只做上报的第一方客户端。** 选了这个。

## 决定

`web/analytics.js`：同源加载的第一方客户端，事件直接 `fetch` POST 到 PostHog 的
`/batch/` ingest API。`fetch`/XHR 不受 COEP 的资源加载限制，所以请求头原样保留。

代价与边界写清楚：

- 没有 autocapture、session replay、PostHog Surveys。前两个本来就明确不做；
  问卷改画在 Godot 层（`scripts/SurveyCard.gd`），顺带避开了
  `_lock_web_gestures()` 在 document 上装的 `selectstart` / `touchmove` 拦截，
  以及「DOM 层点击穿透到画布」这一整类历史 bug。
- 队列、去重、批量、失败丢弃这些原本 SDK 负责的事，现在是我们自己的代码，
  出问题只能自己查。队列有上限（200 条），送不出去就丢并保留原 `event_id`，
  不重排队——否则弱网玩家会把队列涨满，服务端还可能产生重复计数。
- 身份也自己管：`distinct_id` 放 localStorage，全部兜了 try/catch，
  无痕窗口或禁用存储时不会抛错，事件会带 `storage_ok: false` 供报表识别。

## 后果

- PostHog 的漏斗、留存、分群都只依赖事件和 `distinct_id`，这条路不受影响。
- 将来若要接真实广告 SDK 或任何第三方 DOM 组件，会再次撞上 COEP。
  到时候要重新评估选项 1，而不是在这里绕。
- `web/` 是源码目录，`export/web/` 是部署产物且被 `.gitignore` 排除；
  两边靠 `tools/sync_web_shell.py` 同步，导出后必须跑一次。
