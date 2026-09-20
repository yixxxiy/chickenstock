/*
 * 本地预览导出的网页版：
 *
 *     node tools/web-serve.mjs
 *     然后浏览器打开 http://127.0.0.1:8080
 *
 * 为什么不能用普通的静态服务器：Godot 的网页版需要 COOP/COEP 两个响应头，
 * 缺了会在加载后直接失败。这里和线上的 _headers 保持一致。
 *
 * 这是 tools/serve_web.py 的 Node 版本，功能相同。
 * 本机的 python 是 Microsoft Store 占位程序跑不了，所以用这个。
 */

import { createServer } from "node:http";
import { createReadStream, existsSync, statSync } from "node:fs";
import { join, extname, normalize, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..", "export", "web");
const PORT = 8080;

const TYPES = {
  ".html": "text/html; charset=utf-8",
  ".js": "application/javascript",
  ".mjs": "application/javascript",
  ".json": "application/json",
  ".wasm": "application/wasm",
  ".pck": "application/octet-stream",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
  ".otf": "font/otf",
  ".ttf": "font/ttf",
  ".wav": "audio/wav",
  ".ogg": "audio/ogg",
};

if (!existsSync(join(ROOT, "index.html"))) {
  console.error("export/web/index.html 不存在 —— 先在 Godot 里导出一次 Web 版。");
  process.exit(1);
}

createServer((req, res) => {
  let rel = decodeURIComponent(new URL(req.url, "http://x").pathname);
  if (rel === "/") rel = "/index.html";
  // 挡住 ../ 之类的路径穿越
  const path = join(ROOT, normalize(rel).replace(/^(\.\.[\\/])+/, ""));

  if (!path.startsWith(ROOT) || !existsSync(path) || statSync(path).isDirectory()) {
    res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
    res.end("404");
    return;
  }

  res.writeHead(200, {
    "Content-Type": TYPES[extname(path).toLowerCase()] || "application/octet-stream",
    // 和线上 _headers 一致，少一个 Godot 就跑不起来
    "Cross-Origin-Opener-Policy": "same-origin",
    "Cross-Origin-Embedder-Policy": "require-corp",
    "Cache-Control": "no-cache",
  });
  createReadStream(path).pipe(res);
}).listen(PORT, "127.0.0.1", () => {
  console.log("正在提供 export/web");
  console.log(`浏览器打开 http://127.0.0.1:${PORT}`);
  console.log("（Ctrl+C 停止）");
});
