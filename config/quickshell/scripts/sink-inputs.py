import subprocess
import json
import sys
import os

CACHE_FILE = "/tmp/qs_app_volumes.json"

def load_saved_volumes():
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r") as f:
                return json.load(f)
        except Exception:
            pass
    return {}

def save_volume(app_name, vol_pct):
    vols = load_saved_volumes()
    vols[app_name] = int(vol_pct)
    try:
        with open(CACHE_FILE, "w") as f:
            json.dump(vols, f)
    except Exception:
        pass

def get_sink_inputs():
    saved_vols = load_saved_volumes()
    streams = []
    
    # 1. Native pw-dump first (instant, non-blocking)
    try:
        res = subprocess.run(["pw-dump"], capture_output=True, text=True, timeout=1.5)
        if res.returncode == 0 and res.stdout:
            data = json.loads(res.stdout)
            for item in data:
                if item.get("type") == "PipeWire:Interface:Node":
                    info = item.get("info", {})
                    props = info.get("props", {})
                    media_class = props.get("media.class", "")
                    if media_class == "Stream/Output/Audio":
                        node_id = str(item.get("id"))
                        app_name = props.get("application.name", props.get("media.name", props.get("node.name", "Audio App")))
                        vol_pct = "100"
                        muted = False
                        streams.append({"id": node_id, "name": app_name, "volume": vol_pct, "muted": muted})
    except Exception:
        pass

    # 2. Fallback to pactl if pw-dump didn't find any streams
    if not streams:
        try:
            res = subprocess.run(["pactl", "list", "sink-inputs"], capture_output=True, text=True, timeout=1.5)
            lines = res.stdout.splitlines()
            current = {}
            for line in lines:
                line = line.strip()
                if line.startswith("Sink Input #"):
                    if current and "id" in current:
                        streams.append(current)
                    current = {"id": line.split("#")[1]}
                elif line.startswith("Volume:"):
                    parts = line.split("/")
                    if len(parts) >= 2:
                        current["volume"] = parts[1].strip().replace("%", "")
                elif line.startswith("Mute:"):
                    current["muted"] = "yes" in line
                elif "application.name =" in line:
                    current["name"] = line.split("=")[1].strip().strip('"')
                elif "media.name =" in line and "name" not in current:
                    current["name"] = line.split("=")[1].strip().strip('"')
            if current and "id" in current:
                streams.append(current)
        except Exception:
            pass

    # Enforce saved application volumes across track/stream changes
    for s in streams:
        name = s.get("name")
        stream_id = s.get("id")
        if name and stream_id and name in saved_vols:
            target_vol = str(saved_vols[name])
            curr_vol = s.get("volume", "100")
            if curr_vol != target_vol:
                try:
                    subprocess.run(["pactl", "set-sink-input-volume", stream_id, target_vol + "%"], capture_output=True, timeout=1)
                except Exception:
                    pass
                s["volume"] = target_vol

    return streams

if __name__ == "__main__":
    if len(sys.argv) >= 4 and sys.argv[1] == "--set-app-vol":
        app_name = sys.argv[2]
        vol_pct = sys.argv[3]
        save_volume(app_name, vol_pct)
        # Find matching streams and apply
        for s in get_sink_inputs():
            if s.get("name") == app_name:
                try:
                    subprocess.run(["pactl", "set-sink-input-volume", s["id"], vol_pct + "%"], capture_output=True, timeout=1)
                except Exception:
                    pass
        print(json.dumps(get_sink_inputs()))
    else:
        print(json.dumps(get_sink_inputs()))
