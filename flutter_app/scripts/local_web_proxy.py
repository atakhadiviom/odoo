#!/usr/bin/env python3
from __future__ import annotations

import http.server
import http.cookiejar
import email.utils
import mimetypes
import socketserver
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

# Add explicit mime types for common Flutter web assets
mimetypes.add_type('application/json', '.json')
mimetypes.add_type('application/javascript', '.js')
mimetypes.add_type('font/ttf', '.ttf')
mimetypes.add_type('font/otf', '.otf')
mimetypes.add_type('image/svg+xml', '.svg')
mimetypes.add_type('application/wasm', '.wasm')

ROOT = Path(__file__).resolve().parents[1] / "build" / "web"
ODOO_BASE = "http://127.0.0.1:8069"
ODOO_DB = "syntho_mobile_ecommerce_20260415"
PORT = 8123
PROXY_PREFIXES = (
    "/mobile_api",
    "/web",
    "/shop",
    "/website",
    "/my",
    "/payment",
    "/mail",
    "/portal",
)


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
        
        # Security: ensure we stay within ROOT
        if not str(target).startswith(str(ROOT)) or not target.exists() or target.is_dir():
            target = ROOT / "index.html"

        data = target.read_bytes()
        content_type, _ = mimetypes.guess_type(str(target))
        if not content_type:
            if target.suffix == '.json':
                content_type = 'application/json'
            elif target.suffix == '.wasm':
                content_type = 'application/wasm'
            elif target.suffix == '.js':
                content_type = 'application/javascript'
            else:
                content_type = 'text/html; charset=utf-8'

        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("Access-Control-Allow-Origin", "*")
        if target.name == "index.html":
            self.send_header("Clear-Site-Data", '"cache", "storage"')
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
        if parsed.path != "/web/session/authenticate":
            headers["X-Odoo-Database"] = ODOO_DB
        request = urllib.request.Request(
            upstream,
            data=body,
            headers=headers,
            method=self.command,
        )

        try:
            cookie_jar = http.cookiejar.CookieJar()
            opener = urllib.request.build_opener(
                urllib.request.HTTPCookieProcessor(cookie_jar)
            )
            with opener.open(request) as response:
                self.send_response(response.status)
                for key, value in response.headers.items():
                    lower_key = key.lower()
                    if lower_key in {
                        "transfer-encoding",
                        "connection",
                        "content-encoding",
                        "set-cookie",
                    }:
                        continue
                    self.send_header(key, value)
                sent_cookies = set()
                for cookie in response.headers.get_all("Set-Cookie", []):
                    sent_cookies.add(cookie)
                    self.send_header("Set-Cookie", cookie)
                for cookie in cookie_jar:
                    cookie_header = self._cookie_to_header(cookie)
                    if cookie_header and cookie_header not in sent_cookies:
                        self.send_header("Set-Cookie", cookie_header)
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

    def _cookie_to_header(self, cookie: http.cookiejar.Cookie) -> str:
        parts = [f"{cookie.name}={cookie.value}", f"Path={cookie.path or '/'}"]
        if cookie.expires:
            parts.append(f"Expires={email.utils.formatdate(cookie.expires, usegmt=True)}")
        if cookie.secure:
            parts.append("Secure")
        if "HttpOnly" in cookie._rest:
            parts.append("HttpOnly")
        return "; ".join(parts)


class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True


if __name__ == "__main__":
    with ReusableTCPServer(("127.0.0.1", PORT), LocalProxyHandler) as server:
        print(f"Serving Flutter web build at http://127.0.0.1:{PORT}")
        server.serve_forever()
