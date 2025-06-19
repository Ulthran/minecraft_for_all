#!/usr/bin/env python3
"""Simple development server for the web interface.

Serves the files from the ``web`` directory and exposes dummy API endpoints
for ``STATUS_API_URL`` and ``START_API_URL`` so the frontend can be tested
locally without deploying any infrastructure.
"""

import http.server
import json
import os
from functools import partial

PORT = 8000

class Handler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/STATUS_API_URL':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            payload = {'state': 'running', 'players': 0}
            self.wfile.write(json.dumps(payload).encode())
            return
        super().do_GET()

    def do_POST(self):
        if self.path == '/START_API_URL':
            self.send_response(200)
            self.end_headers()
            return
        self.send_error(404, 'Not Found')

if __name__ == '__main__':
    web_dir = os.path.join(os.path.dirname(__file__), 'web')
    handler = partial(Handler, directory=web_dir)
    with http.server.ThreadingHTTPServer(('localhost', PORT), handler) as httpd:
        print(f'Serving at http://localhost:{PORT}')
        httpd.serve_forever()
