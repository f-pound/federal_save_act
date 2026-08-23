#!/usr/bin/env python3
"""
serve_explorer.py — Build and serve the Computational Amicus Explorer.

Usage:
    python tools/serve_explorer.py
    # Opens http://127.0.0.1:8000
"""

from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
import os
import subprocess
import sys
import webbrowser

ROOT = Path(__file__).resolve().parents[1]
WEB = ROOT / "web"


def main():
    # Step 1: Build explorer data
    build_script = ROOT / "tools" / "build_explorer_data.py"
    if build_script.exists():
        print("Building explorer data...")
        subprocess.check_call([sys.executable, str(build_script)], cwd=ROOT)
        print()

    # Step 2: Serve
    os.chdir(WEB)
    port = 8000
    server = ThreadingHTTPServer(("127.0.0.1", port), SimpleHTTPRequestHandler)
    url = f"http://127.0.0.1:{port}"
    print(f"Serving Federal SAVE Act Computational Amicus Explorer at {url}")
    print("Press Ctrl+C to stop.\n")

    # Try to open browser
    try:
        webbrowser.open(url)
    except Exception:
        pass

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down.")
        server.shutdown()


if __name__ == "__main__":
    main()
