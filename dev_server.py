#!/usr/bin/env python3
"""Simple development server for the web interfaces.

By default it serves the files from the ``web`` directory and exposes dummy
API endpoints so the frontend can be tested locally without deploying any
infrastructure. Pass ``--site saas_web`` to serve the SaaS landing page and
mock its signup endpoint. The SaaS mode also provides a mock cost endpoint
used by the console page.
"""

import http.server
import json
import os
import logging
import argparse
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

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Development server for the web UIs")
    parser.add_argument('--site', choices=['web', 'saas_web'], default='web', help='Which site to serve')
    args = parser.parse_args()

    if args.site == 'web':
        MOCK_RESPONSES.update({
            ('GET', '/STATUS_API_URL'): (200, {'state': 'running', 'players': 0}),
            ('POST', '/START_API_URL'): (200, None),
        })
    else:
        MOCK_RESPONSES.update({
            ('POST', '/SIGNUP_API_URL'): (200, None),
            ('POST', '/LOGIN_API_URL'): (200, {'token': 'dummy'}),
            ('GET', '/STATUS_API_URL'): (200, {'state': 'offline'}),
            ('POST', '/START_API_URL'): (200, None),
            ('GET', '/COST_API_URL'): (200, {
                'total': 12.34,
                'breakdown': {
                    'EC2': 10.00,
                    'S3': 2.34,
                }
            }),
        })

    logging.basicConfig(level=logging.INFO, format='[%(levelname)s] %(message)s')
    web_dir = os.path.join(os.path.dirname(__file__), args.site)
    handler = partial(Handler, directory=web_dir)
    with http.server.ThreadingHTTPServer(("localhost", PORT), handler) as httpd:
        logging.info('Serving %s at http://localhost:%s', args.site, PORT)
        httpd.serve_forever()
