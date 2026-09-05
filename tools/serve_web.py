# Local preview for Godot Web export.
# Plain `python -m http.server` does not send COOP/COEP, so Godot fails after export.
from __future__ import annotations

import functools
import http.server
import os
import socketserver
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "export" / "web"
PORT = 8080


class Handler(http.server.SimpleHTTPRequestHandler):
	extensions_map = {
		**getattr(http.server.SimpleHTTPRequestHandler, "extensions_map", {}),
		".wasm": "application/wasm",
		".pck": "application/octet-stream",
		".js": "application/javascript",
		".png": "image/png",
		".html": "text/html",
	}

	def end_headers(self) -> None:
		self.send_header("Cross-Origin-Opener-Policy", "same-origin")
		self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
		self.send_header("Cache-Control", "no-cache")
		super().end_headers()


def main() -> None:
	if not (ROOT / "index.html").exists():
		raise SystemExit("Missing export/web/index.html. Export Web first.")
	os.chdir(ROOT)
	socketserver.TCPServer.allow_reuse_address = True
	with socketserver.TCPServer(("127.0.0.1", PORT), Handler) as httpd:
		print("Serving export/web")
		print(f"Open http://127.0.0.1:{PORT}")
		httpd.serve_forever()


if __name__ == "__main__":
	main()
