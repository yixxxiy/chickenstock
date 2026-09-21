/*
 * 导出之后、上传 Netlify 之前跑这一条：
 *
 *     node tools/web-sync.mjs
 *
 * 它做两件事：
 * 1. 把 web/analytics.js 和 web/notice.js 复制进 export/web/
 *    （统计客户端缺了会静默停用；告知层缺了玩家就看不到采集说明，不能上线）
 * 2. 检查这一包能不能上传（引用、请求头、token 填没填），有问题直接报错退出
 *
 * 这是 tools/sync_web_shell.py 的 Node 版本，功能相同。
 * 本机的 python 是 Microsoft Store 占位程序跑不了，所以用这个。
 *
 * 已经填好 token 的 export/web/posthog-config.js 不会被覆盖。
 */

import { existsSync, copyFileSync, readFileSync, statSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const SRC = join(ROOT, "web");
const DST = join(ROOT, "export", "web");

const problems = [];
const notes = [];

function fail(msg) {
  problems.push(msg);
}

// ---- 1. 导出产物在不在 ----

if (!existsSync(DST)) {
  console.error("找不到 export/web —— 先在 Godot 里导出一次 Web 版。");
  process.exit(1);
}

if (!existsSync(join(DST, "index.html"))) {
  console.error("export/web 里没有 index.html —— 这次导出没成功，先回 Godot 重导。");
  process.exit(1);
}

// ---- 2. 同步统计文件 ----
// [文件名, 已存在时是否覆盖]
const FILES = [
  ["analytics.js", true],
  ["notice.js", true],
  ["posthog-config.js", false],
  ["logo_icon.png", true],
  ["logo_wordmark.png", true],
  ["logo_wordmark_en.png", true],
];

for (const [name, overwrite] of FILES) {
  const src = join(SRC, name);
  const dst = join(DST, name);
  if (!existsSync(src)) {
    console.error(`缺少源文件 web/${name}`);
    process.exit(1);
  }
  if (existsSync(dst) && !overwrite) {
    notes.push(`跳过 ${name}（已存在，里面可能填着线上 token）`);
    continue;
  }
  copyFileSync(src, dst);
  notes.push(`已同步 ${name}`);
}

// ---- 3. 检查 index.html 真的引用了外壳脚本（logo 由 notice.js 动态挂，不必写进 html）----

const html = readFileSync(join(DST, "index.html"), "utf8");
for (const name of ["posthog-config.js", "analytics.js", "notice.js"]) {
  if (!html.includes(name)) {
    fail(`index.html 没有引用 ${name} —— 检查 export_presets.cfg 的 html/head_include`);
  }
}

// ---- 4. 请求头文件（AGENTS.md 要求，Godot 重导可能冲掉）----

for (const guard of ["_headers", "netlify.toml"]) {
  if (!existsSync(join(DST, guard))) {
    fail(`${guard} 不在 export/web 里 —— 从仓库根目录拷回去`);
  }
}

// ---- 5. token 填了没有 ----

const cfg = readFileSync(join(DST, "posthog-config.js"), "utf8");
const keyMatch = cfg.match(/apiKey:\s*["']([^"']*)["']/);
const apiKey = keyMatch ? keyMatch[1] : "";
if (!apiKey) {
  fail("export/web/posthog-config.js 的 apiKey 是空的 —— 这样统计会静默停用，一条数据都收不到");
} else if (!apiKey.startsWith("phc_")) {
  fail(`apiKey 看起来不对（应该以 phc_ 开头，现在是 "${apiKey.slice(0, 12)}..."）`);
} else {
  notes.push(`apiKey 已填：${apiKey.slice(0, 12)}…`);
}

const debugMatch = cfg.match(/debug:\s*(true|false)/);
if (debugMatch && debugMatch[1] === "true") {
  notes.push("注意：debug 是 true，事件会带 test_env=true（正式发布请改成 false）");
}

// ---- 6. 包体信息，顺便记进部署日志用 ----

for (const f of readdirSync(DST)) {
  if (f.endsWith(".pck") || f.endsWith(".wasm")) {
    const mb = (statSync(join(DST, f)).size / 1048576).toFixed(2);
    notes.push(`${f} = ${mb} MB`);
  }
}

// ---- 输出 ----

for (const n of notes) console.log("  " + n);

if (problems.length) {
  console.log("");
  console.error("这一包还不能上传：");
  for (const p of problems) console.error("  ✗ " + p);
  process.exit(1);
}

console.log("");
console.log("✓ export/web 检查通过，可以整个文件夹拖去 Netlify 了。");
