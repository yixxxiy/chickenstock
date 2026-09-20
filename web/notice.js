/*
 * 小鸡股市 —— 加载页样式（满屏启动图 + 醒目进度条）
 *
 * 源文件：web/notice.js。export/web/ 副本由 tools/web-sync.mjs 同步。
 * 通过 export_presets 的 head_include 在引擎启动前注入。
 *
 * 约束：
 * - 线上包带 COEP require-corp，不加载任何外部资源。
 * - 不挂文案层、不吃点击（pointer-events 不挡 canvas）。
 */
(function () {
  "use strict";

  var css = [
    /* 竖屏启动图铺满视口；默认 object-fit:contain 会留黑边 */
    "#status-splash.fullsize--true{",
    "height:100%!important;",
    "width:100%!important;",
    "max-height:100%!important;",
    "max-width:100%!important;",
    "object-fit:cover!important;",
    "object-position:center center;",
    "}",
    /* 进度条：暖金高对比，压在深色雨夜底图上仍醒目 */
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
  ].join("");

  function inject() {
    if (document.getElementById("cluck-splash-style")) return;
    var style = document.createElement("style");
    style.id = "cluck-splash-style";
    style.textContent = css;
    (document.head || document.documentElement).appendChild(style);
  }

  if (document.head) {
    inject();
  } else {
    document.addEventListener("DOMContentLoaded", inject);
  }
})();
