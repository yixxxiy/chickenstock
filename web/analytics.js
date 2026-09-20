/*
 * 小鸡股市 —— 第一方统计客户端
 *
 * 为什么不直接引 posthog-js：
 * 线上包带 Cross-Origin-Embedder-Policy: require-corp（AGENTS.md 要求保留）。
 * require-corp 下任何不带 CORP 响应头的跨域「资源加载」都会被浏览器拒绝，
 * 而 PostHog CDN 上的 SDK 文件正属于这一类。fetch/XHR 不受此限制，
 * 所以这里同源加载本文件，事件直接 POST 到 PostHog 的 ingest API。
 * 顺带解决大陆玩家访问第三方 CDN 的可达性问题，也避免引入 autocapture。
 *
 * 本文件必须在 Godot 引擎启动之前执行（通过 export_presets 的 head_include
 * 同步引入），否则会漏掉下载/初始化阶段就失败的玩家。
 *
 * 源文件位置：web/analytics.js —— 这才是要改的地方。
 * export/web/ 下的同名文件是部署副本，由 tools/sync_web_shell.py 同步。
 */
(function () {
  "use strict";

  var CFG = window.CLUCK_POSTHOG || {};
  var HOST = String(CFG.host || "").replace(/\/+$/, "");
  var KEY = String(CFG.apiKey || "");
  var LIVE = !!(HOST && KEY);

  var SCHEMA_VERSION = 1;
  var SESSION_IDLE_MS = 30 * 60 * 1000; // 超过这个间隔再回来算新会话
  var QUEUE_MAX = 200;                  // 队列有上限：失败不会无限吃内存
  var BATCH_MAX = 20;
  var FLUSH_DEBOUNCE_MS = 1500;
  var READY_TIMEOUT_MS = 60000;         // 超时仍不可操作 → 记一条 load_error

  /* ---------- 存储：随时可能抛异常或被禁用，全部兜住 ---------- */

  function lsGet(k) {
    try { return window.localStorage.getItem(k); } catch (e) { return null; }
  }
  function lsSet(k, v) {
    try { window.localStorage.setItem(k, v); return true; } catch (e) { return false; }
  }
  function lsDel(k) {
    try { window.localStorage.removeItem(k); } catch (e) { /* 无痕/禁用存储时忽略 */ }
  }

  function uuid() {
    try {
      if (window.crypto && window.crypto.randomUUID) return window.crypto.randomUUID();
    } catch (e) { /* 落到下面的兜底 */ }
    var s = "";
    for (var i = 0; i < 32; i++) {
      s += Math.floor(Math.random() * 16).toString(16);
      if (i === 7 || i === 11 || i === 15 || i === 19) s += "-";
    }
    return s;
  }

  /* ---------- 身份 ----------
   * distinct_id 与「问卷已提交」都放 localStorage，同生共死：
   * 避免「换了匿名身份却还记得填过问卷」——那样既发不出奖励也收不到问卷。
   * 游戏存档在网页上走 IndexedDB，是另一套存储，可被独立清除，
   * 所以玩法进度重置不影响这里，这里被清了也不影响玩法进度。
   */
  var DID_KEY = "cluck_did";
  var SID_KEY = "cluck_sid";
  var SID_TS_KEY = "cluck_sid_ts";
  var COHORT_KEY = "cluck_cohort";
  // 三份问卷各存各的完成标记。合成一个会让填过主问卷的人再也问不到流失原因。
  var SURVEY_KEY = "cluck_survey_done";
  var EXIT_KEY = "cluck_exit_done";
  var PULSE_KEY = "cluck_pulse_done";
  var FIRST_PLAY_KEY = "cluck_first_play_done";

  var distinctId = lsGet(DID_KEY);
  var persisted = true;
  if (!distinctId) {
    distinctId = uuid();
    persisted = lsSet(DID_KEY, distinctId);
  }

  var now = Date.now();
  var sessionId = lsGet(SID_KEY);
  var lastSeen = parseInt(lsGet(SID_TS_KEY) || "0", 10) || 0;
  var newSession = !sessionId || (now - lastSeen) > SESSION_IDLE_MS;
  if (newSession) {
    sessionId = uuid();
    lsSet(SID_KEY, sessionId);
  }
  lsSet(SID_TS_KEY, String(now));

  var visitId = uuid();

  // 招募来源分层（朋友 / 学校 / 自然流量 / 平台），由分发链接 ?c= 带入。
  // 这是样本分层，不是渠道归因：不采集 referrer 全文、UTM 全套或设备定向信息。
  var cohort = "unknown";
  try {
    var fromUrl = new URLSearchParams(window.location.search).get("c");
    if (fromUrl) {
      cohort = String(fromUrl).slice(0, 24);
      lsSet(COHORT_KEY, cohort);
    } else {
      cohort = lsGet(COHORT_KEY) || "unknown";
    }
  } catch (e) {
    cohort = lsGet(COHORT_KEY) || "unknown";
  }

  var t0 = now;
  try {
    if (window.performance && window.performance.timeOrigin) t0 = window.performance.timeOrigin;
  } catch (e) { /* 用 Date.now() 兜底 */ }

  function sinceOpen() {
    try {
      if (window.performance && window.performance.now) return Math.round(window.performance.now());
    } catch (e) { /* 落到下面 */ }
    return Date.now() - t0;
  }

  /* ---------- 发送队列 ---------- */

  var queue = [];
  var flushTimer = null;
  var dropped = 0;

  function flush(closing) {
    if (flushTimer !== null) {
      window.clearTimeout(flushTimer);
      flushTimer = null;
    }
    if (!queue.length) return;
    if (!LIVE) { queue.length = 0; return; }
    var batch = queue.splice(0, queue.length);
    var body = JSON.stringify({ api_key: KEY, historical_migration: false, batch: batch });
    try {
      window.fetch(HOST + "/batch/", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: body,
        // keepalive 让页面隐藏/关闭时这一批仍有机会送达（上限约 64KB）。
        keepalive: !!closing,
        mode: "cors",
        credentials: "omit",
      })["catch"](function () {
        // 送不出去就丢。不重排队、不无限重试：否则弱网玩家会把队列涨满，
        // 服务端也可能因为重发产生重复计数。
        dropped += batch.length;
      });
    } catch (e) {
      dropped += batch.length;
    }
  }

  function enqueue(payload) {
    if (queue.length >= QUEUE_MAX) { dropped++; return; }
    queue.push(payload);
    if (queue.length >= BATCH_MAX) { flush(false); return; }
    if (flushTimer === null) {
      flushTimer = window.setTimeout(function () {
        flushTimer = null;
        flush(false);
      }, FLUSH_DEBOUNCE_MS);
    }
  }

  /* ---------- 事件 ---------- */

  var readySent = false;
  var readyTimer = null;

  function capturePlain(event, props) {
    var p = props || {};
    var out = {
      distinct_id: distinctId,
      $session_id: sessionId,
      schema_version: SCHEMA_VERSION,
      visit_id: visitId,
      session_id: sessionId,
      cohort: cohort,
      storage_ok: persisted,
      test_env: !!CFG.debug,
      ms_since_open: sinceOpen(),
    };
    for (var k in p) {
      if (Object.prototype.hasOwnProperty.call(p, k)) out[k] = p[k];
    }
    var eventId = out.event_id || uuid();
    out.event_id = eventId;
    enqueue({
      event: event,
      uuid: eventId, // 同一 uuid 重复送达时由接收端去重
      timestamp: new Date().toISOString(),
      properties: out,
    });
  }

  var API = {
    /* Godot 侧统一入口：传一段 JSON 文本，避免拼接字符串时的转义问题。 */
    capture: function (json) {
      var obj;
      try { obj = JSON.parse(json); } catch (e) { return; }
      if (!obj || !obj.event) return;
      if (obj.event === "game_ready" && !readySent) {
        readySent = true;
        if (readyTimer !== null) {
          window.clearTimeout(readyTimer);
          readyTimer = null;
        }
        // 加载页的告知层等这一下才撤。用「真正可操作」而不是「下载完成」：
        // 下载完到能点之间还有引擎启动和首屏，那段时间玩家还在看加载页。
        API.gameReady = true;
        try {
          window.dispatchEvent(new Event("cluck:ready"));
        } catch (e) { /* 统计不许打断页面 */ }
      }
      capturePlain(obj.event, obj.props || {});
      if (obj.flush) flush(false);
    },

    /* 画像四项写成 person 属性，供 PostHog 分群筛选。只在问卷提交成功时调用。 */
    setPerson: function (json) {
      var obj;
      try { obj = JSON.parse(json); } catch (e) { return; }
      capturePlain("$set", { $set: obj });
      flush(false);
    },

    identity: function () {
      return JSON.stringify({
        distinct_id: distinctId,
        visit_id: visitId,
        session_id: sessionId,
        new_session: newSession,
        cohort: cohort,
        storage_ok: persisted,
        live: LIVE,
        test_env: !!CFG.debug,
        survey_done: lsGet(SURVEY_KEY) === "1",
        exit_done: lsGet(EXIT_KEY) === "1",
        pulse_done: lsGet(PULSE_KEY) === "1",
        first_play_done: lsGet(FIRST_PLAY_KEY) === "1",
        ms_since_open: sinceOpen(),
      });
    },

    markSurveyDone: function () { lsSet(SURVEY_KEY, "1"); },
    markExitDone: function () { lsSet(EXIT_KEY, "1"); },
    markPulseDone: function () { lsSet(PULSE_KEY, "1"); },
    markFirstPlayDone: function () { lsSet(FIRST_PLAY_KEY, "1"); },
    flush: function () { flush(false); },

    /* 设置里「Reset Game」：换新匿名身份，问卷/首玩标记一起清。
     * 旧 distinct_id 上的历史事件仍留在 PostHog，客户端删不掉；之后的事件算新玩家。 */
    resetPlayer: function () {
      flush(false);
      distinctId = uuid();
      persisted = lsSet(DID_KEY, distinctId);
      sessionId = uuid();
      visitId = uuid();
      newSession = true;
      lsSet(SID_KEY, sessionId);
      lsSet(SID_TS_KEY, String(Date.now()));
      lsDel(SURVEY_KEY);
      lsDel(EXIT_KEY);
      lsDel(PULSE_KEY);
      lsDel(FIRST_PLAY_KEY);
      try {
        var fromUrl = new URLSearchParams(window.location.search).get("c");
        if (fromUrl) {
          cohort = String(fromUrl).slice(0, 24);
          lsSet(COHORT_KEY, cohort);
        } else {
          lsDel(COHORT_KEY);
          cohort = "unknown";
        }
      } catch (e) {
        lsDel(COHORT_KEY);
        cohort = "unknown";
      }
      return API.identity();
    },

    /* 由 Godot 注册，页面隐藏/恢复时回调：切断有效计时并补报残区间。 */
    onVisibility: null,
    hidden: false,

    /* 游戏是否已经真正可操作。notice.js 靠它决定什么时候撤掉加载页的告知。 */
    gameReady: false,
  };

  window.CluckA = API;

  /* ---------- 页面级事件 ---------- */

  capturePlain("page_open", {
    referrer_kind: (function () {
      // 只区分「站内 / 站外 / 直接打开」，不记录具体 referrer。
      try {
        if (!document.referrer) return "direct";
        return new URL(document.referrer).host === window.location.host ? "internal" : "external";
      } catch (e) { return "unknown"; }
    })(),
    screen_w: (window.screen && window.screen.width) || 0,
    screen_h: (window.screen && window.screen.height) || 0,
    dpr: window.devicePixelRatio || 1,
    lang_hint: String(navigator.language || "").slice(0, 8),
    ua_mobile: /Mobi|Android|iPhone|iPad/i.test(navigator.userAgent || ""),
  });

  readyTimer = window.setTimeout(function () {
    if (readySent) return;
    capturePlain("load_error", {
      stage: "ready_timeout",
      error_type: "no_game_ready",
      wait_ms: READY_TIMEOUT_MS,
    });
    flush(false);
  }, READY_TIMEOUT_MS);

  window.addEventListener("error", function (e) {
    if (readySent) return; // 只关心「还没能开始玩」这一段
    var msg = "";
    try {
      msg = String((e && (e.message || (e.error && e.error.message))) || "").slice(0, 200);
    } catch (err) {
      msg = "";
    }
    capturePlain("load_error", { stage: "boot", error_type: "js_error", message: msg });
  }, true);

  document.addEventListener("visibilitychange", function () {
    API.hidden = document.visibilityState === "hidden";
    // Godot 的 JS 回调是同步执行的：先让它补报残区间，再把队列送走。
    try {
      if (API.onVisibility) API.onVisibility(API.hidden ? 1 : 0);
    } catch (e) { /* 统计不许打断页面 */ }
    if (API.hidden) flush(true);
  });

  window.addEventListener("pagehide", function () {
    try {
      if (API.onVisibility) API.onVisibility(1);
    } catch (e) { /* 同上 */ }
    flush(true);
  });
})();
