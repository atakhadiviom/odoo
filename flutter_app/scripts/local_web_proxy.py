#!/usr/bin/env python3
from __future__ import annotations

import http.server
import mimetypes
import socketserver
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1] / "build" / "web"
ODOO_BASE = "http://127.0.0.1:8069"
ODOO_DB = "syntho_mobile_ecommerce_20260415"
PORT = 8123
PROXY_PREFIXES = ("/mobile_api", "/web", "/shop", "/website")


class LocalProxyHandler(http.server.BaseHTTPRequestHandler):
    server_version = "SynthoFlutterProxy/1.0"

    def do_GET(self) -> None:
        if self.path.startswith(PROXY_PREFIXES):
            self._proxy_request()
            return
        self._serve_static()

    def do_HEAD(self) -> None:
        if self.path.startswith(PROXY_PREFIXES):
            self._proxy_request(write_body=False)
            return
        self._serve_static(write_body=False)

    def do_POST(self) -> None:
        self._proxy_request()

    def do_OPTIONS(self) -> None:
        if self.path.startswith(PROXY_PREFIXES):
            self.send_response(204)
            self.send_header("Access-Control-Allow-Origin", f"http://127.0.0.1:{PORT}")
            self.send_header("Access-Control-Allow-Credentials", "true")
            self.send_header("Access-Control-Allow-Headers", "Content-Type")
            self.send_header("Access-Control-Allow-Methods", "GET, HEAD, POST, OPTIONS")
            self.end_headers()
            return
        self.send_error(405)

    def _serve_static(self, write_body: bool = True) -> None:
        parsed = urllib.parse.urlparse(self.path)
        relative = parsed.path.lstrip("/") or "index.html"
        target = (ROOT / relative).resolve()
        if not str(target).startswith(str(ROOT)) or not target.exists() or target.is_dir():
            target = ROOT / "index.html"

        data = target.read_bytes()
        content_type, _ = mimetypes.guess_type(str(target))
        self.send_response(200)
        self.send_header("Content-Type", content_type or "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        if write_body:
            self.wfile.write(data)

    def _proxy_request(self, write_body: bool = True) -> None:
        parsed = urllib.parse.urlparse(self.path)
        query = dict(urllib.parse.parse_qsl(parsed.query, keep_blank_values=True))
        query.setdefault("db", ODOO_DB)
        upstream = f"{ODOO_BASE}{parsed.path}"
        if query:
            upstream = f"{upstream}?{urllib.parse.urlencode(query, doseq=True)}"

        body = None
        content_length = int(self.headers.get("Content-Length", "0"))
        if content_length:
            body = self.rfile.read(content_length)

        headers = {
            key: value
            for key, value in self.headers.items()
            if key.lower() not in {"host", "origin", "referer", "content-length"}
        }
        headers["Host"] = "127.0.0.1:8069"
        headers["X-Odoo-Database"] = ODOO_DB
        request = urllib.request.Request(
            upstream,
            data=body,
            headers=headers,
            method=self.command,
        )

        try:
            with urllib.request.urlopen(request) as response:
                self.send_response(response.status)
                for key, value in response.headers.items():
                    if key.lower() in {"transfer-encoding", "connection", "content-encoding"}:
                        continue
                    self.send_header(key, value)
                self.send_header("Access-Control-Allow-Origin", f"http://127.0.0.1:{PORT}")
                self.send_header("Access-Control-Allow-Credentials", "true")
                self.end_headers()
                data = response.read()
                if write_body:
                    self.wfile.write(data)
        except urllib.error.HTTPError as error:
            self.send_response(error.code)
            self.send_header("Content-Type", error.headers.get_content_type())
            self.send_header("Access-Control-Allow-Origin", f"http://127.0.0.1:{PORT}")
            self.send_header("Access-Control-Allow-Credentials", "true")
            self.end_headers()
            data = error.read()
            if write_body:
                self.wfile.write(data)


if __name__ == "__main__":
    with socketserver.TCPServer(("127.0.0.1", PORT), LocalProxyHandler) as server:
        print(f"Serving Flutter web build at http://127.0.0.1:{PORT}")
        server.serve_forever()
