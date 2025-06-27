#!/usr/bin/env python3
"""Simple development server for the web interfaces.
"""

import http.server
import json
import os
import logging
from functools import partial

PORT = 8000


MOCK_RESPONSES = {}


class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        """Disable caching to ensure changes are always reflected."""
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def do_GET(self):
        if self.path.startswith("/MC_API/build/"):
            build_id = self.path.rsplit("/", 1)[-1]
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            body = {
                "build": {
                    "id": build_id,
                    "status": "SUCCEEDED",
                    "current_phase": "COMPLETED",
                }
            }
            self.wfile.write(json.dumps(body).encode())
            return
        resp = MOCK_RESPONSES.get(("GET", self.path))
        if resp:
            status, body = resp
            self.send_response(status)
            if body is not None:
                self.send_header("Content-Type", "application/json")
            self.end_headers()
            if body is not None:
                self.wfile.write(json.dumps(body).encode())
            return
        super().do_GET()

    def do_POST(self):
        resp = MOCK_RESPONSES.get(("POST", self.path))
        if resp:
            status, body = resp
            self.send_response(status)
            if body is not None:
                self.send_header("Content-Type", "application/json")
            self.end_headers()
            if body is not None:
                self.wfile.write(json.dumps(body).encode())
            return
        logging.warning("Unknown POST path: %s", self.path)
        self.send_error(404, "Not Found")


if __name__ == "__main__":
    dummy_token = "eyJhbGciOiAibm9uZSJ9." "eyJjdXN0b206dGVuYW50X2lkIjogImRlbW8ifQ==."

    MOCK_RESPONSES.update(
        {
            ("POST", "/SIGNUP_API_URL"): (200, None),
            ("POST", "/CONFIRM_API_URL"): (200, None),
            ("POST", "/LOGIN_API_URL"): (200, {"token": dummy_token}),
            ("POST", "/MC_API/init"): (200, {"build_id": "demo-build"}),
            ("GET", "/MC_API/status"): (200, {"state": "offline"}),
            ("POST", "/MC_API/start"): (200, None),
            ("GET", "/MC_API/cost"): (200, {"total": 0}),
            ("POST", "/MC_API/checkout"): (200, {"client_secret": "seti_dummy"}),
        }
    )

    logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
    web_dir = os.path.join(os.path.dirname(__file__), "saas_web")
    handler = partial(Handler, directory=web_dir)
    with http.server.ThreadingHTTPServer(("localhost", PORT), handler) as httpd:
        logging.info("Serving %s at http://localhost:%s", "saas_web", PORT)
        httpd.serve_forever()
