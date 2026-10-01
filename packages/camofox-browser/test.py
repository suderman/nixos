"""Exercise the pinned browser without network access or existing profiles."""

import http.server
import json
import os
from pathlib import Path
import re
import signal
import socket
import ssl
import subprocess
import sys
import tempfile
import threading
import time
import urllib.error
import urllib.request


class Page(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/html")
        self.end_headers()
        self.wfile.write(b'<h1>Browser check</h1><a href="/next">Next page</a>')

    def log_message(self, format, *args):
        pass


with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    fixture = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Page)
    threading.Thread(target=fixture.serve_forever, daemon=True).start()
    url = f"http://127.0.0.1:{fixture.server_port}"
    tls_servers = []
    for name in ("server", "untrusted"):
        tls_server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Page)
        tls = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        tls.load_cert_chain(
            Path(sys.argv[2]) / f"{name}.crt", Path(sys.argv[2]) / f"{name}.key"
        )
        tls_server.socket = tls.wrap_socket(tls_server.socket, server_side=True)
        threading.Thread(target=tls_server.serve_forever, daemon=True).start()
        tls_servers.append(tls_server)
    with socket.socket() as reservation:
        reservation.bind(("127.0.0.1", 0))
        port = reservation.getsockname()[1]
    endpoint = f"http://127.0.0.1:{port}"
    env = os.environ | {
        "HOME": directory,
        "XDG_CACHE_HOME": str(root / "cache"),
        "CAMOFOX_HOST": "127.0.0.1",
        "CAMOFOX_PORT": str(port),
        "CAMOFOX_HEADLESS": "true",
        "CAMOFOX_CRASH_REPORT_ENABLED": "false",
        "CAMOFOX_PROFILES_DIR": str(root / "profiles"),
        "CAMOFOX_COOKIES_DIR": str(root / "cookies"),
        "CAMOFOX_TRACES_DIR": str(root / "traces"),
    }

    def api(method, path, body=None):
        data = None if body is None else json.dumps(body).encode()
        request = urllib.request.Request(
            endpoint + path,
            data=data,
            method=method,
            headers={"Content-Type": "application/json"},
        )
        with urllib.request.urlopen(request, timeout=90) as response:
            return json.load(response)

    with (root / "server.log").open("w+") as log:
        server = subprocess.Popen(
            [sys.argv[1]], env=env, stdout=log, stderr=log, start_new_session=True
        )
        try:
            for attempt in range(30):
                try:
                    assert api("GET", "/health")["ok"]
                    break
                except (OSError, AssertionError):
                    if server.poll() is not None or attempt == 29:
                        raise
                    time.sleep(1)
            identity = {"userId": "package-check", "sessionKey": "first"}
            tab = api("POST", "/tabs", identity | {"url": url})["tabId"]
            snapshot = api("GET", f"/tabs/{tab}/snapshot?userId=package-check")[
                "snapshot"
            ]
            assert "Browser check" in snapshot, snapshot
            link = re.search(r'link "Next page" \[(e\d+)\]', snapshot)
            assert link, snapshot
            ref = link[1]
            clicked = api(
                "POST", f"/tabs/{tab}/click", {"userId": "package-check", "ref": ref}
            )
            assert clicked["url"] == url + "/next", clicked
            api(
                "POST",
                f"/tabs/{tab}/evaluate",
                {
                    "userId": "package-check",
                    "expression": "document.cookie='probe=kept; Max-Age=600; Path=/'; localStorage.setItem('probe','kept'); true",
                },
            )
            api("DELETE", "/sessions/package-check")
            tab = api(
                "POST",
                "/tabs",
                identity | {"sessionKey": "second", "url": url + "/next"},
            )["tabId"]
            stored = api(
                "POST",
                f"/tabs/{tab}/evaluate",
                {
                    "userId": "package-check",
                    "expression": "document.cookie.split('; ').includes('probe=kept') && localStorage.getItem('probe')==='kept'",
                },
            )
            assert stored["result"] is True, stored
            api("DELETE", "/sessions/package-check")
            trusted_url = f"https://127.0.0.1:{tls_servers[0].server_port}"
            tab = api("POST", "/tabs", identity | {"url": trusted_url})["tabId"]
            assert (
                "Browser check"
                in api("GET", f"/tabs/{tab}/snapshot?userId=package-check")["snapshot"]
            )
            untrusted_url = f"https://127.0.0.1:{tls_servers[1].server_port}"
            try:
                api("POST", "/tabs", identity | {"url": untrusted_url})
            except urllib.error.HTTPError as error:
                assert "SEC_ERROR_UNKNOWN_ISSUER" in error.read().decode()
            else:
                raise AssertionError("Browser accepted an untrusted certificate")
            api("DELETE", "/sessions/package-check")
            print("Trusted HTTPS passed; untrusted HTTPS rejected")
            print(
                "Pinned browser navigation, snapshot, click, and storage reopen passed"
            )
        except Exception:
            log.seek(0)
            print(log.read(), file=sys.stderr)
            raise
        finally:
            os.killpg(server.pid, signal.SIGTERM)
            try:
                server.wait(timeout=15)
            except subprocess.TimeoutExpired:
                os.killpg(server.pid, signal.SIGKILL)
                server.wait()
            fixture.shutdown()
            for tls_server in tls_servers:
                tls_server.shutdown()
