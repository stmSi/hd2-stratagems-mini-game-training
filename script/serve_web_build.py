#!/usr/bin/env python3

from __future__ import annotations

import argparse
import http.server
import pathlib
import socketserver
import sys


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Serve the exported Godot Web build from build/web.",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=8000,
        help="Local port to use. Default: 8000.",
    )
    parser.add_argument(
        "--host",
        default="127.0.0.1",
        help="Host/interface to bind. Default: 127.0.0.1.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    project_root = pathlib.Path(__file__).resolve().parent.parent
    web_build_dir = project_root / "build" / "web"
    index_file = web_build_dir / "index.html"

    if not index_file.is_file():
        print(
            "Web build not found at %s.\nExport the Web build first."
            % index_file,
            file=sys.stderr,
        )
        return 1

    handler = lambda *handler_args, **handler_kwargs: http.server.SimpleHTTPRequestHandler(  # noqa: E731
        *handler_args,
        directory=str(web_build_dir),
        **handler_kwargs,
    )

    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer((args.host, args.port), handler) as httpd:
        print("Serving %s" % web_build_dir)
        print("Open http://%s:%d/" % (args.host, args.port))
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nServer stopped.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
