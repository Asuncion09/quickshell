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

def get_cache_path():
    cache_home = os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache"))
    qs_cache = os.path.join(cache_home, "quickshell")
    os.makedirs(qs_cache, exist_ok=True)
    return os.path.join(qs_cache, "clipboard_history.json")

def send_client():
    """Single-shot client invoked by wl-paste --watch"""
    try:
        raw = sys.stdin.buffer.read()
        if not raw:
            sys.exit(0)
        text = raw.decode("utf-8", errors="replace")
        if not text.strip():
            sys.exit(0)

        sock_path = get_sock_path()
        if not os.path.exists(sock_path):
            sys.exit(0)

        payload = json.dumps({"text": text}).encode("utf-8")
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
        self.history = []
        self.suppress_next = None
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

    def make_item(self, text):
        clean_text = text.rstrip("\r\n")
        # Limitar longitud máxima de texto para proteger memoria y el canal IPC de Quickshell
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
            "timestamp": int(time.time() * 1000)
        }

    def load_cache(self):
        if os.path.exists(self.cache_path):
            try:
                with open(self.cache_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    if isinstance(data, list):
                        for item in data:
                            if len(item.get("text", "")) > 30000:
                                item["text"] = item["text"][:30000]
                        self.history = data[:50]
            except Exception as e:
                self.history = []

    def save_cache(self):
        try:
            with open(self.cache_path, "w", encoding="utf-8") as f:
                json.dump(self.history, f, ensure_ascii=False, indent=2)
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

            item = self.make_item(clean)
            # Remove any existing instance with matching text or id (move to top)
            self.history = [h for h in self.history if h.get("text") != clean]
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
            if "text" in msg:
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
                action = cmd.get("action")
                if action == "copy":
                    text = cmd.get("text", "")
                    if text:
                        with self.lock:
                            self.suppress_next = text.rstrip("\r\n")
                        subprocess.run(["wl-copy"], input=text.encode("utf-8"), check=False)
                elif action == "delete":
                    item_id = cmd.get("id")
                    if item_id:
                        with self.lock:
                            self.history = [h for h in self.history if h.get("id") != item_id]
                            self.save_cache()
                        self.emit({"type": "removed", "id": item_id})
                elif action == "clear":
                    with self.lock:
                        self.history = []
                        self.save_cache()
                    self.emit({"type": "cleared"})
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

        # Brief pause to let socket initialize
        time.sleep(0.05)
        self.start_watcher()
        self.initial_check()

        # Listen for commands from QML on the main thread
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
        # Ignore SIGPIPE and auto-reap child processes to prevent <defunct> zombies
        signal.signal(signal.SIGPIPE, signal.SIG_DFL)
        try:
            signal.signal(signal.SIGCHLD, signal.SIG_IGN)
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
