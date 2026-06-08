#!/usr/bin/env python3
"""
PCaC Local Suggestion Board Service
Simple, local-only web form (no external deps, pure stdlib).

- GET  /           → HTML form to submit a suggestion (chill / internet layer)
- POST /submit     → Accepts form, appends to shared/suggestions/suggestions.txt
- GET  /view       → Shows recent suggestions (read-only, for Right side too)
- GET  /raw        → Plain text of the suggestions file

Run from Center or Left launcher. Binds to localhost only for safety.
Designed to be launched full-screen kiosk on the Left monitor (or viewed from Right).

Usage:
    python3 scripts/suggestion_service.py
    # or via the launcher scripts with --start-suggestions

The service writes to PCAC_SHARED_DIR/suggestions/suggestions.txt
(controlled via env or the launcher).
"""

import os
import sys
import urllib.parse
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
from pathlib import Path

# --- Configuration (can be overridden by env) ---
DEFAULT_PORT = int(os.environ.get("PCAC_SUGGESTION_PORT", "8765"))
SHARED_DIR = Path(os.environ.get(
    "PCAC_SHARED_DIR",
    Path(__file__).resolve().parent.parent / "shared"
))
SUGGESTIONS_FILE = SHARED_DIR / "suggestions" / "suggestions.txt"

# Ensure the target file exists
SUGGESTIONS_FILE.parent.mkdir(parents=True, exist_ok=True)
SUGGESTIONS_FILE.touch(exist_ok=True)

HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PCaC • Suggestions</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500&amp;family=Space+Grotesk:wght@500;600&amp;display=swap');
        
        :root {
            --bg: #0f1117;
            --card: #161a23;
            --accent: #7c9cff;
        }
        
        body {
            font-family: 'Inter', system_ui, sans-serif;
            background: var(--bg);
            color: #e2e8f0;
            margin: 0;
            padding: 0;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            line-height: 1.5;
        }
        
        .container {
            width: 100%;
            max-width: 620px;
            padding: 2rem;
        }
        
        .header {
            text-align: center;
            margin-bottom: 2rem;
        }
        
        .header h1 {
            font-family: 'Space Grotesk', sans-serif;
            font-size: 2.25rem;
            font-weight: 600;
            margin: 0 0 0.25rem;
            background: linear-gradient(90deg, #7c9cff, #a5b4fc);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        
        .header p {
            color: #64748b;
            margin: 0;
            font-size: 1.05rem;
        }
        
        .card {
            background: var(--card);
            border-radius: 16px;
            padding: 2rem;
            box-shadow: 0 10px 15px -3px rgb(0 0 0 / 0.1);
            border: 1px solid #1f2433;
        }
        
        .form-group {
            margin-bottom: 1.25rem;
        }
        
        label {
            display: block;
            font-size: 0.95rem;
            font-weight: 500;
            margin-bottom: 0.5rem;
            color: #94a3b8;
        }
        
        input[type="text"], textarea, select {
            width: 100%;
            padding: 0.75rem 1rem;
            background: #0f1117;
            border: 1px solid #2a3042;
            border-radius: 10px;
            color: #e2e8f0;
            font-size: 1rem;
            transition: border-color 0.2s;
            box-sizing: border-box;
        }
        
        input:focus, textarea:focus, select:focus {
            outline: none;
            border-color: var(--accent);
        }
        
        textarea {
            min-height: 110px;
            resize: vertical;
        }
        
        button {
            width: 100%;
            background: var(--accent);
            color: #0f1117;
            font-weight: 600;
            font-size: 1.05rem;
            padding: 0.9rem;
            border: none;
            border-radius: 10px;
            cursor: pointer;
            transition: all 0.2s;
        }
        
        button:hover {
            background: #6b8cff;
            transform: translateY(-1px);
        }
        
        .meta {
            font-size: 0.8rem;
            color: #64748b;
            text-align: center;
            margin-top: 1.5rem;
        }
        
        .links {
            display: flex;
            gap: 1rem;
            justify-content: center;
            margin-top: 1rem;
        }
        
        .links a {
            color: #64748b;
            text-decoration: none;
            font-size: 0.9rem;
        }
        
        .links a:hover {
            color: var(--accent);
        }
        
        .success {
            background: #052e16;
            color: #86efac;
            padding: 1rem;
            border-radius: 10px;
            margin-bottom: 1rem;
            border: 1px solid #166534;
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>PCaC Suggestions</h1>
            <p>Left monitor • Chill layer • Share ideas with the Right side</p>
        </div>
        
        <div class="card">
            {success}
            
            <form method="POST" action="/submit">
                <div class="form-group">
                    <label for="category">Category</label>
                    <select name="category" id="category">
                        <option value="chill">Chill / Vibe</option>
                        <option value="internet">Internet / Discovery</option>
                        <option value="suggestion">General Suggestion</option>
                        <option value="game">Game / Media Idea</option>
                        <option value="other">Other</option>
                    </select>
                </div>
                
                <div class="form-group">
                    <label for="text">Your suggestion / idea / link</label>
                    <textarea name="text" id="text" placeholder="I really want to try that new cozy game..." required></textarea>
                </div>
                
                <div class="form-group">
                    <label for="from">From (optional)</label>
                    <input type="text" name="from" id="from" placeholder="you or a nickname">
                </div>
                
                <button type="submit">Send to the board →</button>
            </form>
        </div>
        
        <div class="meta">
            Suggestions appear instantly on the shared board.<br>
            Visible from Center (Grok) and Right monitor.
        </div>
        
        <div class="links">
            <a href="/view">View all suggestions</a>
            <a href="/raw">Raw text file</a>
        </div>
    </div>
</body>
</html>
"""

VIEW_TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>PCaC • Suggestion Board</title>
    <style>
        body { font-family: system-ui, sans-serif; background:#0f1117; color:#e2e8f0; padding:2rem; max-width:800px; margin:0 auto; }
        h1 { color:#7c9cff; }
        .entry { background:#161a23; padding:1rem; margin-bottom:0.75rem; border-radius:10px; border-left:4px solid #7c9cff; }
        .meta { color:#64748b; font-size:0.85rem; }
        a { color:#7c9cff; }
    </style>
</head>
<body>
    <h1>PCaC Suggestion Board</h1>
    <p><a href="/">← Back to form</a> | <a href="/raw">Raw file</a></p>
    <div>
        {entries}
    </div>
</body>
</html>
"""


class SuggestionHandler(BaseHTTPRequestHandler):
    def _set_headers(self, content_type="text/html"):
        self.send_response(200)
        self.send_header("Content-type", content_type)
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        if path in ("/", "/index.html"):
            self._set_headers()
            success_html = ""
            # Very basic success flash if coming back from submit (not perfect but works)
            if "success=1" in parsed.query:
                success_html = '<div class="success">Thanks! Your suggestion was added to the board.</div>'
            self.wfile.write(HTML_TEMPLATE.format(success=success_html).encode())
            return

        if path == "/view":
            self._set_headers()
            entries_html = self._render_entries()
            self.wfile.write(VIEW_TEMPLATE.format(entries=entries_html).encode())
            return

        if path == "/raw":
            self._set_headers("text/plain; charset=utf-8")
            content = SUGGESTIONS_FILE.read_text(encoding="utf-8", errors="replace")
            self.wfile.write(content.encode())
            return

        self.send_error(404, "Not found")

    def do_POST(self):
        if self.path != "/submit":
            self.send_error(404)
            return

        content_length = int(self.headers.get("Content-Length", 0))
        post_data = self.rfile.read(content_length).decode("utf-8", errors="replace")
        fields = urllib.parse.parse_qs(post_data)

        category = fields.get("category", ["other"])[0]
        text = fields.get("text", [""])[0].strip()
        from_ = fields.get("from", [""])[0].strip() or "anonymous"

        if not text:
            self.send_error(400, "Suggestion text is required")
            return

        ts = datetime.now().isoformat(timespec="seconds")
        line = f"[{ts}] [{category}] {from_}: {text}\n"

        try:
            with open(SUGGESTIONS_FILE, "a", encoding="utf-8") as f:
                f.write(line)
        except Exception as e:
            self.send_error(500, f"Failed to save suggestion: {e}")
            return

        # Redirect back to form with success indicator
        self.send_response(303)
        self.send_header("Location", "/?success=1")
        self.end_headers()

    def _render_entries(self):
        if not SUGGESTIONS_FILE.exists() or SUGGESTIONS_FILE.stat().st_size == 0:
            return "<p><em>No suggestions yet. Be the first!</em></p>"

        lines = SUGGESTIONS_FILE.read_text(encoding="utf-8", errors="replace").strip().splitlines()
        html_parts = []
        for line in reversed(lines[-50:]):  # show latest first, limit
            html_parts.append(f'<div class="entry"><pre style="white-space:pre-wrap;margin:0">{line}</pre></div>')
        return "\n".join(html_parts)

    def log_message(self, format, *args):
        # Quieter logging
        sys.stderr.write(f"[{datetime.now().isoformat(timespec='seconds')}] {self.address_string()} - {args[0]}\n")


def run_server(port: int = DEFAULT_PORT):
    server_address = ("127.0.0.1", port)  # localhost only — important for "locked down"
    httpd = HTTPServer(server_address, SuggestionHandler)
    print(f"PCaC Suggestion Board running on http://127.0.0.1:{port}")
    print(f"Writing suggestions to: {SUGGESTIONS_FILE}")
    print("Press Ctrl-C to stop.")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down suggestion service...")
        httpd.server_close()


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_PORT
    run_server(port)
