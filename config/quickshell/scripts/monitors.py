#!/usr/bin/env python3
import subprocess, json, sys

def get_monitors():
    try:
        res = subprocess.run(["hyprctl", "monitors", "-j"], capture_output=True, text=True)
        monitors = json.loads(res.stdout)
        return [{"id": m["id"], "name": m["name"], "description": m["description"], "model": m.get("model", m["name"])} for m in monitors]
    except Exception:
        return []

if __name__ == "__main__":
    print(json.dumps(get_monitors()))
