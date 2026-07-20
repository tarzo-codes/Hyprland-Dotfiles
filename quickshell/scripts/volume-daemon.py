#!/usr/bin/env python3
import subprocess, json, sys, os, time

CACHE_FILE = "/tmp/qs_app_volumes.json"

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
    try:
        res = subprocess.run(["pactl", "list", "sink-inputs"], capture_output=True, text=True)
        lines = res.stdout.splitlines()
        current = {}
        for line in lines:
            line = line.strip()
            if line.startswith("Sink Input #"):
                if current and "id" in current:
                    enforce_stream(current, saved_vols)
                current = {"id": line.split("#")[1]}
            elif line.startswith("Volume:"):
                parts = line.split("/")
                if len(parts) >= 2:
                    current["volume"] = parts[1].strip().replace("%", "")
            elif "application.name =" in line:
                current["name"] = line.split("=")[1].strip().strip('"')
            elif "media.name =" in line and "name" not in current:
                current["name"] = line.split("=")[1].strip().strip('"')
        if current and "id" in current:
            enforce_stream(current, saved_vols)
    except Exception:
        pass

def enforce_stream(stream, saved_vols):
    name = stream.get("name")
    stream_id = stream.get("id")
    if name and stream_id and name in saved_vols:
        target_vol = str(saved_vols[name])
        curr_vol = stream.get("volume", "100")
        if curr_vol != target_vol:
            subprocess.run(["pactl", "set-sink-input-volume", stream_id, target_vol + "%"], capture_output=True)

def main():
    check_and_enforce_volumes()

    try:
        proc = subprocess.Popen(["pactl", "subscribe"], stdout=subprocess.PIPE, text=True)
        while True:
            line = proc.stdout.readline()
            if not line:
                break
            if "sink-input" in line or "client" in line:
                check_and_enforce_volumes()
    except Exception:
        pass

if __name__ == "__main__":
    main()
