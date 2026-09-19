#!/usr/bin/env python3
import argparse
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

STATE = {
    "local": {"state": "paused", "volume": 24},
    "spotify": {"playing": False, "paused": True, "volume": 28000},
}

class Handler(BaseHTTPRequestHandler):
    server_version = "MuPiBoxMock/0.1"

    def log_message(self, fmt, *args):
        print(fmt % args)

    def json(self, status, payload):
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def body(self):
        size = int(self.headers.get("Content-Length", "0"))
        return json.loads(self.rfile.read(size) or b"{}")

    def do_GET(self):
        if self.path == "/api/health":
            return self.json(200, {"status": "ok", "version": "0.1.0-mock"})
        if self.path == "/api/system":
            return self.json(200, {"online": True, "wifi": {"connected": True, "interface": "wlan0", "signal_dbm": -47, "quality_percent": 82}, "battery": {"available": True, "percent": 74, "charging": True}})
        if self.path == "/api/status":
            return self.json(200, {"state": STATE["local"]["state"], "backend": "mock", "folder_id": "demo", "folder": "Demo Hörspiel", "queue": [{"id": "1", "title": "Kapitel 1"}], "index": 0, "position": 42.0, "duration": 180.0, "volume": STATE["local"]["volume"], "max_volume": 70})
        if self.path == "/api/spotify/status":
            return self.json(200, {"connected": True, "playing": STATE["spotify"]["playing"], "paused": STATE["spotify"]["paused"], "buffering": False, "volume": STATE["spotify"]["volume"], "volume_steps": 65535, "track": {"name": "Spotify Demo", "artists": ["MuPiBox"], "album": "Control", "position_ms": 20000, "duration_ms": 180000}})
        if self.path == "/api/connectivity/bluetooth":
            return self.json(200, {"enabled": True, "devices": [{"address": "AA:BB:CC:DD:EE:FF", "name": "Demo Speaker", "paired": True, "trusted": True, "connected": False}]})
        return self.json(404, {"error": "not found"})

    def do_POST(self):
        payload = self.body()
        if self.path == "/api/command":
            action = payload.get("action")
            if action in ("play", "resume"):
                STATE["local"]["state"] = "playing"
            elif action == "pause":
                STATE["local"]["state"] = "paused"
            elif action == "toggle":
                STATE["local"]["state"] = "paused" if STATE["local"]["state"] == "playing" else "playing"
            elif action == "volume":
                STATE["local"]["volume"] = int(payload.get("value", 0))
            return self.do_GET_path("/api/status")
        if self.path == "/api/spotify/command":
            action = payload.get("action")
            if action in ("play", "resume"):
                STATE["spotify"].update(playing=True, paused=False)
            elif action == "pause":
                STATE["spotify"].update(playing=False, paused=True)
            elif action == "volume":
                STATE["spotify"]["volume"] = int(payload.get("value", 0))
            return self.do_GET_path("/api/spotify/status")
        if self.path == "/api/speak":
            return self.json(200, {"speaking": True})
        return self.json(404, {"error": "not found"})

    def do_GET_path(self, path):
        original = self.path
        self.path = path
        try:
            return self.do_GET()
        finally:
            self.path = original

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--bind", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=8090)
    args = parser.parse_args()
    print(f"Mock MuPiBox listening on http://{args.bind}:{args.port}")
    ThreadingHTTPServer((args.bind, args.port), Handler).serve_forever()
