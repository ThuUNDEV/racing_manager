#!/usr/bin/env python3
"""Gọi Claude trên server riêng. Dùng: ask_remote_claude.py [-m MODEL] [-s SYSTEM] [-f FILE ...] "prompt"
Prompt cũng có thể đọc từ stdin. Key nằm ở .claude/remote.env (không commit)."""
import argparse, json, os, sys, urllib.request, urllib.error

here = os.path.dirname(os.path.abspath(__file__))
env = {}
with open(os.path.join(here, "..", "remote.env")) as f:
    for line in f:
        if "=" in line and not line.startswith("#"):
            k, v = line.rstrip("\n").split("=", 1); env[k] = v

p = argparse.ArgumentParser()
p.add_argument("prompt", nargs="?")
p.add_argument("-m", "--model", default="claude-sonnet")
p.add_argument("-s", "--system", default="")
p.add_argument("-f", "--file", action="append", default=[], help="đính kèm nội dung file vào prompt")
p.add_argument("--max-tokens", type=int, default=8192)
a = p.parse_args()

text = a.prompt if a.prompt is not None else sys.stdin.read()
for path in a.file:
    with open(path, encoding="utf-8", errors="replace") as fh:
        text += f"\n\n--- FILE: {path} ---\n{fh.read()}"

body = {"model": a.model, "max_tokens": a.max_tokens, "messages": [{"role": "user", "content": text}]}
if a.system: body["system"] = a.system
req = urllib.request.Request(
    env["REMOTE_CLAUDE_BASE_URL"].rstrip("/") + "/v1/messages",
    data=json.dumps(body).encode(),
    headers={"content-type": "application/json", "x-api-key": env["REMOTE_CLAUDE_API_KEY"],
             "anthropic-version": "2023-06-01"})
try:
    with urllib.request.urlopen(req, timeout=300) as r:
        d = json.load(r)
except urllib.error.HTTPError as e:
    sys.exit(f"HTTP {e.code}: {e.read().decode()[:500]}")
print("".join(b.get("text", "") for b in d.get("content", [])))
