#!/usr/bin/env python3
"""Sinh ảnh bằng OpenAI Images API (gpt-image-2.6-flare) và ghi thẳng vào thư mục asset.

Key đọc từ file (không nằm trong repo): đặt đường dẫn qua OPENAI_KEY_FILE,
mặc định ~/.t3/userdata/secrets/files/b90802df318e841a42e54b4c281c5652.

Dùng:
  tools/gen_image.py NAME "prompt" [--size 1024x1024] [--quality high]
                     [--ref a.png --ref b.png] [--opaque] [--out DIR]
Mặc định: nền trong suốt (background=transparent) png. --ref dùng endpoint edits
(ảnh tham chiếu giữ thiết kế). --opaque cho cảnh nền đầy khung.
"""
import argparse, base64, json, os, sys, urllib.request, uuid

MODEL = os.environ.get("OPENAI_IMAGE_MODEL", "gpt-image-2.6-flare")
KEY_FILE = os.environ.get(
    "OPENAI_KEY_FILE",
    os.path.expanduser("~/.t3/userdata/secrets/files/b90802df318e841a42e54b4c281c5652"),
)
DEFAULT_OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "soft_miniature_ui_v1", "flare")


PERSISTENT_KEY_FILE = os.path.expanduser("~/.config/racing_manager/openai_key")


def key():
    # Thứ tự: OPENAI_KEY_FILE / file t3 cũ -> ~/.config/racing_manager/openai_key -> biến OPENAI_API_KEY.
    for path in (KEY_FILE, PERSISTENT_KEY_FILE):
        if os.path.isfile(path):
            return open(path).read().strip()
    if os.environ.get("OPENAI_API_KEY"):
        return os.environ["OPENAI_API_KEY"].strip()
    sys.exit("No OpenAI key: create " + PERSISTENT_KEY_FILE + " (chmod 600) or set OPENAI_API_KEY")


def post_json(url, body):
    req = urllib.request.Request(url, json.dumps(body).encode(), {
        "Authorization": "Bearer " + key(), "Content-Type": "application/json"})
    return json.load(urllib.request.urlopen(req, timeout=600))


def post_multipart(url, fields, files):
    b = uuid.uuid4().hex
    parts = []
    for k, v in fields.items():
        parts.append(f'--{b}\r\nContent-Disposition: form-data; name="{k}"\r\n\r\n{v}\r\n'.encode())
    for path in files:
        data = open(path, "rb").read()
        parts.append((f'--{b}\r\nContent-Disposition: form-data; name="image[]"; filename="{os.path.basename(path)}"\r\n'
                      f'Content-Type: image/png\r\n\r\n').encode() + data + b"\r\n")
    parts.append(f"--{b}--\r\n".encode())
    req = urllib.request.Request(url, b"".join(parts), {
        "Authorization": "Bearer " + key(), "Content-Type": f"multipart/form-data; boundary={b}"})
    return json.load(urllib.request.urlopen(req, timeout=600))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("name"); ap.add_argument("prompt")
    ap.add_argument("--size", default="1024x1024")
    ap.add_argument("--quality", default="low")  # low đủ cho icon ≤512 px; đổi --quality high khi cần nét tối đa
    ap.add_argument("--ref", action="append", default=[])
    ap.add_argument("--opaque", action="store_true")
    ap.add_argument("--out", default=DEFAULT_OUT)
    a = ap.parse_args()
    f = {"model": MODEL, "prompt": a.prompt, "size": a.size, "quality": a.quality,
         "output_format": "png", "background": "opaque" if a.opaque else "transparent", "n": 1}
    try:
        if a.ref:
            r = post_multipart("https://api.openai.com/v1/images/edits", {k: str(v) for k, v in f.items()}, a.ref)
        else:
            r = post_json("https://api.openai.com/v1/images/generations", f)
    except urllib.error.HTTPError as e:
        sys.exit("HTTP %s: %s" % (e.code, e.read().decode()[:600]))
    os.makedirs(a.out, exist_ok=True)
    path = os.path.join(a.out, a.name + ".png")
    open(path, "wb").write(base64.b64decode(r["data"][0]["b64_json"]))
    print(os.path.abspath(path), "usage:", json.dumps(r.get("usage", {})))


if __name__ == "__main__":
    main()
