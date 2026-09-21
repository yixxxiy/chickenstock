/*
 * 小鸡股市 —— 加载页样式（9:16 启动图 + 主菜单同位置 logo + 进度 tip）
 *
 * 源文件：web/notice.js。export/web/ 副本由 tools/web-sync.mjs 同步。
 * 通过 export_presets 的 head_include 在引擎启动前注入。
 *
 * 约束：
 * - 线上包带 COEP require-corp，不加载任何外部资源（logo 用同目录本地 png）。
 * - 不挂可点层（pointer-events:none），绝不挡 canvas。
 *
 * Logo 位置对齐 UiLayout._menu：
 *   card = (0.17, 0.08, 0.66 × 0.67)
 *   icon = card 内 (0.28, -0.02, 0.44 × 0.22)
 *   word = card 内 (0.04, 0.18, 0.92 × 0.16)
 */
(function () {
  "use strict";

  var TIPS = {
    zh: [
      "小提示：长按可连续收蛋、卖蛋糕",
      "本游戏开发中，尚未完善，敬请期待完整版",
    ],
    en: [
      "Tip: Hold to keep collecting eggs & cakes",
      "Early build — unfinished. Full version coming soon",
    ],
  };
  var TIP_MS = 2800;

  // card 相对视口 + logo 相对 card → 相对 #status（与游戏 576×1024 同比例）
  var CARD_X = 0.17;
  var CARD_Y = 0.08;
  var CARD_W = 0.66;
  var CARD_H = 0.67;
  var ICON = { x: 0.28, y: -0.02, w: 0.44, h: 0.22 };
  var WORD = { x: 0.04, y: 0.18, w: 0.92, h: 0.16 };

  function pct(n) {
    return (n * 100).toFixed(3) + "%";
  }

  function boxCss(id, rel) {
    return [
      "#" + id + "{",
      "position:absolute;",
      "left:" + pct(CARD_X + rel.x * CARD_W) + ";",
      "top:" + pct(CARD_Y + rel.y * CARD_H) + ";",
      "width:" + pct(rel.w * CARD_W) + ";",
      "height:" + pct(rel.h * CARD_H) + ";",
      "object-fit:contain;",
      "object-position:center center;",
      "pointer-events:none;",
      "user-select:none;",
      "-webkit-user-select:none;",
      "z-index:2;",
      "}",
    ].join("");
  }

  var css = [
    "html,body{background:#141f2e;}",
    "#status{",
    "left:50%!important;",
    "right:auto!important;",
    "top:50%!important;",
    "bottom:auto!important;",
    "width:min(100vw,calc(100dvh * 9 / 16))!important;",
    "height:min(100dvh,calc(100vw * 16 / 9))!important;",
    "transform:translate(-50%,-50%)!important;",
    "}",
    "#status-splash.fullsize--true{",
    "height:100%!important;",
    "width:100%!important;",
    "max-height:100%!important;",
    "max-width:100%!important;",
    "object-fit:contain!important;",
    "object-position:center center;",
    "}",
    boxCss("cluck-load-logo-icon", ICON),
    boxCss("cluck-load-logo-word", WORD),
    "#status-progress{",
    "display:block;",
    "bottom:7%!important;",
    "width:72%!important;",
    "height:16px!important;",
    "margin:0 auto;",
    "border:2px solid #fff3c8;",
    "border-radius:999px;",
    "overflow:hidden;",
    "background:#1a1208;",
    "accent-color:#ffd24a;",
    "color:#ffd24a;",
    "box-shadow:0 0 0 2px rgba(0,0,0,0.45),0 0 18px rgba(255,210,74,0.55);",
    "}",
    "#status-progress::-webkit-progress-bar{",
    "background:#1a1208;",
    "border-radius:999px;",
    "}",
    "#status-progress::-webkit-progress-value{",
    "background:linear-gradient(90deg,#ffe566,#ffb020);",
    "border-radius:999px;",
    "}",
    "#status-progress::-moz-progress-bar{",
    "background:linear-gradient(90deg,#ffe566,#ffb020);",
    "border-radius:999px;",
    "}",
    "#cluck-load-tip{",
    "position:absolute;",
    "left:0;",
    "right:0;",
    "bottom:11.5%;",
    "z-index:2;",
    "margin:0;",
    "padding:0 18px;",
    "box-sizing:border-box;",
    "text-align:center;",
    "color:#fff6d6;",
    "font:600 14px/1.35 -apple-system,BlinkMacSystemFont,'Segoe UI','PingFang SC',",
    "'Hiragino Sans GB','Microsoft YaHei',sans-serif;",
    "letter-spacing:0.02em;",
    "text-shadow:0 1px 2px rgba(0,0,0,0.85),0 0 12px rgba(0,0,0,0.45);",
    "pointer-events:none;",
    "user-select:none;",
    "-webkit-user-select:none;",
    "opacity:1;",
    "transition:opacity 280ms ease;",
    "}",
  ].join("");

  // 锁死缩放，避免 iOS 对小字号 input 自动放大后整页弹不回去。
  try {
    var meta = document.querySelector('meta[name="viewport"]');
    if (meta) {
      meta.setAttribute(
        "content",
        "width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover"
      );
    }
  } catch (e) {}

  function isZh() {
    try {
      return window.localStorage.getItem("cluck_lang") === "zh";
    } catch (e) {
      return false;
    }
  }

  function tipList() {
    return isZh() ? TIPS.zh : TIPS.en;
  }

  function wordSrc() {
    return isZh() ? "logo_wordmark.png" : "logo_wordmark_en.png";
  }

  function injectStyle() {
    if (document.getElementById("cluck-splash-style")) return;
    var style = document.createElement("style");
    style.id = "cluck-splash-style";
    style.textContent = css;
    (document.head || document.documentElement).appendChild(style);
  }

  function addImg(id, src, alt) {
    if (document.getElementById(id)) return;
    var img = document.createElement("img");
    img.id = id;
    img.src = src;
    img.alt = alt;
    img.draggable = false;
    img.decoding = "async";
    return img;
  }

  function startTipRotate(tip) {
    if (tip.getAttribute("data-rotating") === "1") return;
    tip.setAttribute("data-rotating", "1");
    var list = tipList();
    var i = 0;
    tip.textContent = list[0];
    if (list.length < 2) return;
    window.setInterval(function () {
      if (!tip.parentNode) return;
      tip.style.opacity = "0";
      window.setTimeout(function () {
        if (!tip.parentNode) return;
        list = tipList();
        i = (i + 1) % list.length;
        tip.textContent = list[i];
        tip.style.opacity = "1";
      }, 280);
    }, TIP_MS);
  }

  function mountChrome() {
    var status = document.getElementById("status");
    if (!status) return false;

    if (!document.getElementById("cluck-load-logo-icon")) {
      var icon = addImg("cluck-load-logo-icon", "logo_icon.png", "Chicken Stock");
      status.appendChild(icon);
    }
    if (!document.getElementById("cluck-load-logo-word")) {
      var word = addImg("cluck-load-logo-word", wordSrc(), "Chicken Stock");
      status.appendChild(word);
    }
    var tip = document.getElementById("cluck-load-tip");
    if (!tip) {
      tip = document.createElement("p");
      tip.id = "cluck-load-tip";
      tip.setAttribute("role", "note");
      status.appendChild(tip);
    }
    startTipRotate(tip);
    return true;
  }

  function boot() {
    injectStyle();
    if (mountChrome()) return;
    var tries = 0;
    var poll = window.setInterval(function () {
      tries += 1;
      if (mountChrome() || tries > 80) window.clearInterval(poll);
    }, 50);
  }

  if (document.body) {
    boot();
  } else {
    document.addEventListener("DOMContentLoaded", boot);
  }
})();
