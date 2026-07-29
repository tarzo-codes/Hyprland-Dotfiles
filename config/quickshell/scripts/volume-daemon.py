#!/usr/bin/env python3
import subprocess
import json
import sys
import os
import time
import fcntl

LOCK_FILE = "/tmp/qs_volume_daemon.lock"
CACHE_FILE = "/tmp/qs_app_volumes.json"

def acquire_lock():
    """Ensure only one instance of volume-daemon.py runs."""
    try:
        lock_fd = open(LOCK_FILE, "w")
        fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        return lock_fd
    except (IOError, OSError):
        sys.exit(0)

def load_saved_volumes():
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r") as f:
                return json.load(f)
        except Exception:
            pass
    return {}

def check_and_enforce_volumes():
    saved_vols = load_saved_volumes()
    if not saved_vols:
        return

    streams = []
    # 1. Native pw-dump (fast, zero subprocess leaks)
    try:
        res = subprocess.run(["pw-dump"], capture_output=True, text=True, timeout=1.5)
        if res.returncode == 0 and res.stdout:
            data = json.loads(res.stdout)
            for item in data:
                if item.get("type") == "PipeWire:Interface:Node":
                    info = item.get("info", {})
                    props = info.get("props", {})
                    if props.get("media.class") == "Stream/Output/Audio":
                        node_id = str(item.get("id"))
                        app_name = props.get("application.name", props.get("media.name", props.get("node.name", "")))
                        if app_name and node_id:
                            streams.append({"id": node_id, "name": app_name})
    except Exception:
        pass

    # 2. Fallback to pactl if pw-dump didn't find streams
    if not streams:
        try:
            res = subprocess.run(["pactl", "list", "sink-inputs"], capture_output=True, text=True, timeout=1.5)
            lines = res.stdout.splitlines()
            current = {}
            for line in lines:
                line = line.strip()
                if line.startswith("Sink Input #"):
                    if current and "id" in current and "name" in current:
                        streams.append(current)
                    current = {"id": line.split("#")[1]}
                elif "application.name =" in line:
                    current["name"] = line.split("=")[1].strip().strip('"')
            if current and "id" in current and "name" in current:
                streams.append(current)
        except Exception:
            pass

    # Enforce saved volumes
    for s in streams:
        name = s.get("name")
        stream_id = s.get("id")
        if name and stream_id and name in saved_vols:
            target_vol = str(saved_vols[name])
            try:
                subprocess.run(["pactl", "set-sink-input-volume", stream_id, target_vol + "%"], capture_output=True, timeout=1)
            except Exception:
                pass

def main():
    _lock = acquire_lock()
    
    last_run = 0
    check_and_enforce_volumes()

    try:
        proc = subprocess.Popen(["pactl", "subscribe"], stdout=subprocess.PIPE, text=True)
        while True:
            line = proc.stdout.readline()
            if not line:
                break
            if "sink-input" in line:
                now = time.time()
                if now - last_run >= 1.0: # Rate limit to max 1 check per second
                    last_run = now
                    check_and_enforce_volumes()
    except Exception:
        pass

if __name__ == "__main__":
    main()
