#!/usr/bin/env python3
"""Simple development server for the web interface.

Serves the files from the ``web`` directory and exposes dummy API endpoints
for ``STATUS_API_URL`` and ``START_API_URL`` so the frontend can be tested
locally without deploying any infrastructure.
"""

import http.server
import json
import os
import logging
from functools import partial

PORT = 8000


class Handler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/STATUS_API_URL':
            logging.info("Received status check request")
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            payload = {'state': 'running', 'players': 0}
            self.wfile.write(json.dumps(payload).encode())
            return
        super().do_GET()

    def do_POST(self):
        if self.path == '/START_API_URL':
            logging.info("Received start server request")
            self.send_response(200)
            self.end_headers()
            return
        logging.warning("Unknown POST path: %s", self.path)
        self.send_error(404, 'Not Found')

if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='[%(levelname)s] %(message)s')
    web_dir = os.path.join(os.path.dirname(__file__), 'web')
    handler = partial(Handler, directory=web_dir)
    with http.server.ThreadingHTTPServer(('localhost', PORT), handler) as httpd:
        logging.info('Serving at http://localhost:%s', PORT)
        httpd.serve_forever()
