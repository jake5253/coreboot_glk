#!/usr/bin/env python3

from http.server import CGIHTTPRequestHandler, HTTPServer

handler = CGIHTTPRequestHandler
handler.cgi_directories = ['/cgi-bin', '/htbin']  # this is the default
server = HTTPServer(('0.0.0.0', 8123), handler)
server.serve_forever()
