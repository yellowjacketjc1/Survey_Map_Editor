#!/usr/bin/env python3
import http.server
import socketserver
import os

PORT = 8000
DIRECTORY = "Current Maps"

class CORSRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)
    
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        super().end_headers()

with socketserver.TCPServer(("", PORT), CORSRequestHandler) as httpd:
    print(f"Serving maps at http://localhost:{PORT}")
    print(f"Directory: {os.path.abspath(DIRECTORY)}")
    httpd.serve_forever()
