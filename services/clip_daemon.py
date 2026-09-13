#!/usr/bin/env python3
import sys
import os
import json
import time
import re
import socket
import select
import signal
import hashlib
import subprocess
import threading
import ctypes

def _set_pdeathsig():
    try:
        libc = ctypes.CDLL("libc.so.6")
        libc.prctl(1, 15)  # PR_SET_PDEATHSIG = 1, SIGTERM = 15
    except Exception:
        pass

def get_sock_path():
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR")
    if runtime_dir and os.path.isdir(runtime_dir):
        return os.path.join(runtime_dir, "quickshell_clip.sock")
    uid = os.getuid() if hasattr(os, "getuid") else 1000
    return f"/tmp/quickshell_clip_{uid}.sock"

def get_cache_dir():
    cache_home = os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache"))
    qs_cache = os.path.join(cache_home, "quickshell")
    os.makedirs(qs_cache, exist_ok=True)
    return qs_cache

def get_cache_path():
    return os.path.join(get_cache_dir(), "clipboard_history.json")

def get_images_dir():
    img_dir = os.path.join(get_cache_dir(), "clipboard_images")
    os.makedirs(img_dir, exist_ok=True)
    return img_dir

def get_config_path():
    config_home = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
    state_dir = os.path.join(config_home, "quickshell", "state")
    os.makedirs(state_dir, exist_ok=True)
    return os.path.join(state_dir, "clipboard_config.json")

def load_config():
    config_file = get_config_path()
    cfg = {
        "retention_hours": 24,
        "clear_on_boot": False
    }
    if os.path.exists(config_file):
        try:
            with open(config_file, "r", encoding="utf-8") as f:
                loaded = json.load(f)
                if isinstance(loaded, dict):
                    cfg.update(loaded)
        except Exception:
            pass
    return cfg

def detect_image(raw):
    """Detect image format by magic bytes. Returns (is_image, ext, mime)"""
    if len(raw) < 8:
        return False, None, None
    if raw.startswith(b'\x89PNG\r\n\x1a\n'):
        return True, "png", "image/png"
    if raw.startswith(b'\xff\xd8\xff'):
        return True, "jpg", "image/jpeg"
    if raw.startswith(b'RIFF') and len(raw) >= 12 and raw[8:12] == b'WEBP':
        return True, "webp", "image/webp"
    if raw.startswith(b'GIF87a') or raw.startswith(b'GIF89a'):
        return True, "gif", "image/gif"
    if raw.startswith(b'BM'):
        return True, "bmp", "image/bmp"
    return False, None, None

def send_client():
    """Single-shot client invoked by wl-paste --watch"""
    try:
        chunks = []
        while True:
            chunk = sys.stdin.buffer.read(65536)
            if not chunk:
                break
            chunks.append(chunk)
        if not chunks:
            sys.exit(0)
        raw = b"".join(chunks)
        if not raw:
            sys.exit(0)

        sock_path = get_sock_path()
        if not os.path.exists(sock_path):
            sys.exit(0)

        is_img, ext, mime = detect_image(raw)
        if is_img:
            img_id = hashlib.sha1(raw).hexdigest()[:12]
            img_dir = get_images_dir()
            img_path = os.path.join(img_dir, f"{img_id}.{ext}")
            if not os.path.exists(img_path):
                with open(img_path, "wb") as f:
                    f.write(raw)
            payload_dict = {
                "kind": "image",
                "id": img_id,
                "imagePath": img_path,
                "mime": mime,
                "size": len(raw)
            }
        else:
            text = raw.decode("utf-8", errors="replace")
            if not text.strip():
                sys.exit(0)
            payload_dict = {
                "kind": "text",
                "text": text
            }

        payload = json.dumps(payload_dict).encode("utf-8")
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.connect(sock_path)
        # Send 4-byte length prefix + data
        s.sendall(len(payload).to_bytes(4, byteorder="big") + payload)
        s.close()
    except Exception:
        pass
    sys.exit(0)

class ClipboardDaemon:
    def __init__(self):
        self.sock_path = get_sock_path()
        self.cache_path = get_cache_path()
        self.images_dir = get_images_dir()
        self.config = load_config()
        self.history = []
        self.suppress_next = None
        self.suppress_next_image = None
        self.running = True
        self.watcher_proc = None
        self.lock = threading.Lock()

    def classify(self, text):
        t = text.strip()
        # 1. Color Hex (e.g. #fff, #1a2b3c, #1a2b3c4d)
        if re.match(r"^#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$", t):
            return "color", t
        # 2. URL / Links
        if re.match(r"^(https?://|git@|ftp://|magnet:)", t):
            return "url", None
        # 3. Multi-line Code or structured syntax
        if ("\n" in text or "  " in text) and any(kw in text for kw in ["def ", "function", "class ", "import ", "const ", "let ", "var ", "return ", "{", "}", "=>"]):
            return "code", None
        return "text", None

    def make_item(self, text, pinned=False):
        clean_text = text.rstrip("\r\n")
        if len(clean_text) > 30000:
            clean_text = clean_text[:30000]

        item_type, color_val = self.classify(clean_text)
        preview = clean_text.strip().split("\n")[0].strip()
        if len(preview) > 120:
            preview = preview[:120] + "..."
        line_count = len(clean_text.split("\n"))

        item_id = hashlib.sha1(clean_text.encode("utf-8")).hexdigest()[:12]
        return {
            "id": item_id,
            "text": clean_text,
            "preview": preview,
            "type": item_type,
            "color": color_val or "",
            "lines": line_count,
            "charCount": len(clean_text),
            "pinned": pinned,
            "timestamp": int(time.time() * 1000)
        }

    def load_cache(self):
        if os.path.exists(self.cache_path):
            try:
                with open(self.cache_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    if isinstance(data, list):
                        valid_items = []
                        for item in data:
                            if item.get("type") == "image":
                                img_path = item.get("imagePath")
                                if img_path and os.path.exists(img_path):
                                    valid_items.append(item)
                            else:
                                if len(item.get("text", "")) > 30000:
                                    item["text"] = item["text"][:30000]
                                valid_items.append(item)
                        self.history = valid_items[:50]
            except Exception:
                self.history = []
        # Aplicar limpieza de expiración inicial según retención y configuración
        self.cleanup_expired(is_boot_check=True)

    def save_cache(self):
        try:
            with open(self.cache_path, "w", encoding="utf-8") as f:
                json.dump(self.history, f, ensure_ascii=False, indent=2)
        except Exception:
            pass

    def cleanup_expired(self, is_boot_check=False):
        """Pruena elementos no fijados con más de 24h de antigüedad o según política de reinicio."""
        retention_hours = self.config.get("retention_hours", 24)
        cutoff = int((time.time() - (retention_hours * 3600)) * 1000)
        clear_on_boot = self.config.get("clear_on_boot", False)

        boot_cutoff = 0
        if is_boot_check and clear_on_boot:
            try:
                with open("/proc/uptime", "r") as uf:
                    uptime_sec = float(uf.readline().split()[0])
                    boot_cutoff = int((time.time() - uptime_sec) * 1000)
            except Exception:
                boot_cutoff = int(time.time() * 1000)

        with self.lock:
            retained = []
            removed_images = []
            changed = False
            for h in self.history:
                # Los elementos FIJADOS (pinned) NUNCA se eliminan automáticamente
                if h.get("pinned", False):
                    retained.append(h)
                    continue

                ts = h.get("timestamp", 0)
                # Si se configuró limpieza al reiniciar y el ítem es anterior al arranque actual
                if is_boot_check and clear_on_boot and ts < boot_cutoff:
                    changed = True
                    if h.get("type") == "image" and h.get("imagePath"):
                        removed_images.append(h["imagePath"])
                    continue

                # Expiración por límite de tiempo (por defecto 24h)
                if ts >= cutoff:
                    retained.append(h)
                else:
                    changed = True
                    if h.get("type") == "image" and h.get("imagePath"):
                        removed_images.append(h["imagePath"])

            if changed:
                self.history = retained
                self.save_cache()
                for p in removed_images:
                    if p and os.path.exists(p):
                        try:
                            os.remove(p)
                        except Exception:
                            pass
                self.emit({"type": "init", "items": self.history})

    def periodic_cleanup_loop(self):
        """Hilo de mantenimiento para limpiar elementos no fijados cada 10 minutos."""
        while self.running:
            time.sleep(600)
            if self.running:
                try:
                    self.cleanup_expired(is_boot_check=False)
                except Exception:
                    pass

    def add_clip(self, text):
        clean = text.rstrip("\r\n")
        if not clean.strip():
            return

        with self.lock:
            # Check if suppressed (echo from our own wl-copy)
            if self.suppress_next and self.suppress_next == clean:
                self.suppress_next = None
                return

            # Avoid duplicate events if top item is already identical
            if self.history and self.history[0].get("text") == clean:
                return

            existing = next((h for h in self.history if h.get("text") == clean), None)
            is_pinned = existing.get("pinned", False) if existing else False

            item = self.make_item(clean, pinned=is_pinned)
            self.history = [h for h in self.history if h.get("text") != clean]
            self.history.insert(0, item)
            self.history = self.history[:50]
            self.save_cache()

            self.emit({"type": "add", "item": item})

    def add_image_clip(self, info):
        img_id = info.get("id")
        img_path = info.get("imagePath")
        mime = info.get("mime", "image/png")
        size = info.get("size", 0)
        if not img_id or not img_path:
            return

        with self.lock:
            if self.suppress_next_image and self.suppress_next_image == img_id:
                self.suppress_next_image = None
                return

            if self.history and self.history[0].get("id") == img_id:
                return

            existing = next((h for h in self.history if h.get("id") == img_id), None)
            is_pinned = existing.get("pinned", False) if existing else False

            kb_size = round(size / 1024, 1)
            ext_upper = mime.split("/")[-1].upper()
            preview = f"Image ({ext_upper}, {kb_size} KB)"

            item = {
                "id": img_id,
                "text": f"[{preview}]",
                "preview": preview,
                "type": "image",
                "mime": mime,
                "imagePath": img_path,
                "color": "",
                "lines": 1,
                "charCount": size,
                "pinned": is_pinned,
                "timestamp": int(time.time() * 1000)
            }

            self.history = [h for h in self.history if h.get("id") != img_id]
            self.history.insert(0, item)
            self.history = self.history[:50]
            self.save_cache()

            self.emit({"type": "add", "item": item})

    def emit(self, data):
        try:
            line = json.dumps(data, ensure_ascii=False)
            sys.stdout.write(line + "\n")
            sys.stdout.flush()
        except Exception:
            pass

    def handle_client(self, conn):
        try:
            raw_len = conn.recv(4)
            if len(raw_len) < 4:
                conn.close()
                return
            msg_len = int.from_bytes(raw_len, byteorder="big")
            chunks = []
            bytes_recvd = 0
            while bytes_recvd < msg_len:
                chunk = conn.recv(min(msg_len - bytes_recvd, 4096))
                if not chunk:
                    break
                chunks.append(chunk)
                bytes_recvd += len(chunk)
            conn.close()

            payload = b"".join(chunks).decode("utf-8", errors="replace")
            msg = json.loads(payload)
            if "action" in msg:
                self.process_command(msg)
            elif msg.get("kind") == "image":
                self.add_image_clip(msg)
            elif "text" in msg:
                self.add_clip(msg["text"])
        except Exception:
            try:
                conn.close()
            except Exception:
                pass

    def socket_loop(self):
        if os.path.exists(self.sock_path):
            try:
                os.remove(self.sock_path)
            except Exception:
                pass

        server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        server.bind(self.sock_path)
        server.listen(10)
        server.setblocking(False)

        while self.running:
            readable, _, _ = select.select([server], [], [], 0.5)
            if readable:
                try:
                    conn, _ = server.accept()
                    threading.Thread(target=self.handle_client, args=(conn,), daemon=True).start()
                except Exception:
                    pass

        try:
            server.close()
            if os.path.exists(self.sock_path):
                os.remove(self.sock_path)
        except Exception:
            pass

    def process_command(self, cmd):
        action = cmd.get("action")
        if action == "copy":
            text = cmd.get("text", "")
            if text:
                with self.lock:
                    self.suppress_next = text.rstrip("\r\n")
                try:
                    p = subprocess.Popen(["wl-copy"], stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    p.communicate(input=text.encode("utf-8"), timeout=2.0)
                except Exception:
                    pass
        elif action == "copy_image":
            item_id = cmd.get("id")
            img_path = cmd.get("path")
            mime = cmd.get("mime", "image/png")
            if img_path and os.path.exists(img_path):
                with self.lock:
                    self.suppress_next_image = item_id
                try:
                    with open(img_path, "rb") as img_file:
                        p = subprocess.Popen(["wl-copy", "--type", mime], stdin=img_file, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                        p.wait(timeout=2.0)
                except Exception:
                    pass
        elif action == "toggle_pin":
            item_id = cmd.get("id")
            if item_id:
                new_pinned = False
                with self.lock:
                    for h in self.history:
                        if h.get("id") == item_id:
                            h["pinned"] = not h.get("pinned", False)
                            new_pinned = h["pinned"]
                            break
                    self.save_cache()
                self.emit({"type": "update_pin", "id": item_id, "pinned": new_pinned})
        elif action == "delete":
            item_id = cmd.get("id")
            if item_id:
                with self.lock:
                    deleted = next((h for h in self.history if h.get("id") == item_id), None)
                    self.history = [h for h in self.history if h.get("id") != item_id]
                    self.save_cache()
                    if deleted and deleted.get("type") == "image":
                        p = deleted.get("imagePath")
                        if p and os.path.exists(p):
                            try:
                                os.remove(p)
                            except Exception:
                                pass
                self.emit({"type": "removed", "id": item_id})
        elif action == "clear":
            with self.lock:
                unpinned_images = [
                    h.get("imagePath") for h in self.history
                    if not h.get("pinned", False) and h.get("type") == "image"
                ]
                # Preservar elementos fijados
                self.history = [h for h in self.history if h.get("pinned", False)]
                self.save_cache()
                for p in unpinned_images:
                    if p and os.path.exists(p):
                        try:
                            os.remove(p)
                        except Exception:
                            pass
            self.emit({"type": "init", "items": self.history})

    def stdin_loop(self):
        """Reads JSON commands from Quickshell via standard input"""
        while self.running:
            line = sys.stdin.readline()
            if not line:
                break
            line = line.strip()
            if not line:
                continue
            try:
                cmd = json.loads(line)
                self.process_command(cmd)
            except Exception:
                pass

    def start_watcher(self):
        script_path = os.path.abspath(__file__)
        try:
            subprocess.run(["pkill", "-f", f"wl-paste --watch python3 {script_path}"], stderr=subprocess.DEVNULL)
        except Exception:
            pass
        cmd = ["wl-paste", "--watch", "python3", script_path, "--send"]
        try:
            self.watcher_proc = subprocess.Popen(
                cmd,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                preexec_fn=_set_pdeathsig
            )
        except Exception:
            pass

    def initial_check(self):
        """Check if there is an existing clipboard item at startup"""
        try:
            # Primero chequear si Wayland ofrece un mime de imagen
            types_proc = subprocess.run(["wl-paste", "-l"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=1.0)
            if types_proc.returncode == 0:
                offered = types_proc.stdout.decode("utf-8", errors="ignore")
                if "image/" in offered:
                    mime = "image/png"
                    if "image/jpeg" in offered:
                        mime = "image/jpeg"
                    elif "image/webp" in offered:
                        mime = "image/webp"
                    img_res = subprocess.run(["wl-paste", "--type", mime], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=1.5)
                    if img_res.returncode == 0 and img_res.stdout:
                        is_img, ext, m = detect_image(img_res.stdout)
                        if is_img:
                            img_id = hashlib.sha1(img_res.stdout).hexdigest()[:12]
                            img_path = os.path.join(self.images_dir, f"{img_id}.{ext}")
                            if not os.path.exists(img_path):
                                with open(img_path, "wb") as f:
                                    f.write(img_res.stdout)
                            self.add_image_clip({
                                "id": img_id,
                                "imagePath": img_path,
                                "mime": m,
                                "size": len(img_res.stdout)
                            })
                            return

            res = subprocess.run(["wl-paste", "-n"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=1.0)
            if res.returncode == 0 and res.stdout:
                text = res.stdout.decode("utf-8", errors="replace")
                if text.strip():
                    self.add_clip(text)
        except Exception:
            pass

    def run(self):
        self.load_cache()
        self.emit({"type": "init", "items": self.history})

        sock_thread = threading.Thread(target=self.socket_loop, daemon=True)
        sock_thread.start()

        cleanup_thread = threading.Thread(target=self.periodic_cleanup_loop, daemon=True)
        cleanup_thread.start()

        time.sleep(0.05)
        self.start_watcher()
        self.initial_check()

        try:
            self.stdin_loop()
        except KeyboardInterrupt:
            pass
        finally:
            self.cleanup()

    def cleanup(self):
        self.running = False
        if self.watcher_proc:
            try:
                self.watcher_proc.terminate()
            except Exception:
                pass
        if os.path.exists(self.sock_path):
            try:
                os.remove(self.sock_path)
            except Exception:
                pass

def main():
    if "--send" in sys.argv:
        send_client()
    else:
        signal.signal(signal.SIGPIPE, signal.SIG_DFL)
        try:
            sys.stdin.reconfigure(line_buffering=True)
            sys.stdout.reconfigure(line_buffering=True)
        except Exception:
            pass
        daemon = ClipboardDaemon()
        def sig_handler(signum, frame):
            daemon.cleanup()
            sys.exit(0)
        signal.signal(signal.SIGTERM, sig_handler)
        signal.signal(signal.SIGINT, sig_handler)
        daemon.run()

if __name__ == "__main__":
    main()
