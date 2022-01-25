import time
import sys
import os
import asyncio
import websockets

from wsgiref.simple_server import make_server

loop = asyncio.get_event_loop()
options = {}


async def tail(websocket, path):
    with open(options['path'], 'rt') as file:
        seek = 0
        sleep = None

        while True:
            file.seek(seek)
            line = file.readline()
            where = file.tell()

            if line:
                if seek != where:
                    sleep = None
                    await websocket.send(line.strip())
            else:
                sleep = 0.04

            seek = where

            if sleep:
                time.sleep(sleep)


def wsgiapplication(environ, start_response):
    start_response('200 OK', [('Content-Type', 'text/html')])
    return open('index.html', 'rb')


def main(action):
    if action == 'webserver':
        with make_server('', 8123, wsgiapplication) as httpd:
            print("Serving on port 8123...")

            try:
                httpd.serve_forever()
            except KeyboardInterrupt:
                httpd.shutdown()

    elif action == 'tailserver':
        tail_server = websockets.serve(tail, '', 9000)
        loop.run_until_complete(tail_server)
        loop.run_forever()


if __name__ == '__main__':
    assert len(sys.argv) == 3, "Required at least two arguments, action and log path.

    _, action, path = sys.argv

    options['path'] = path

    main(action)
