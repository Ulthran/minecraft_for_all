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
    def do_GET(self):
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
    MOCK_RESPONSES.update(
        {
            ("POST", "/SIGNUP_API_URL"): (200, None),
            ("POST", "/LOGIN_API_URL"): (200, {"token": "dummy"}),
            ("GET", "/STATUS_API_URL"): (200, {"state": "offline"}),
            ("POST", "/START_API_URL"): (200, None),
        }
    )

    logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
    web_dir = os.path.join(os.path.dirname(__file__), "saas_web")
    handler = partial(Handler, directory=web_dir)
    with http.server.ThreadingHTTPServer(("localhost", PORT), handler) as httpd:
        logging.info("Serving %s at http://localhost:%s", "saas_web", PORT)
        httpd.serve_forever()
