import subprocess, json, sys, os

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
    try:
        res = subprocess.run(["pactl", "list", "sink-inputs"], capture_output=True, text=True)
        lines = res.stdout.splitlines()
        streams = []
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

        # Enforce saved application volumes across track/stream changes
        for s in streams:
            name = s.get("name")
            stream_id = s.get("id")
            if name and stream_id and name in saved_vols:
                target_vol = str(saved_vols[name])
                curr_vol = s.get("volume", "100")
                if curr_vol != target_vol:
                    subprocess.run(["pactl", "set-sink-input-volume", stream_id, target_vol + "%"], capture_output=True)
                    s["volume"] = target_vol

        return streams
    except Exception:
        return []

if __name__ == "__main__":
    if len(sys.argv) >= 4 and sys.argv[1] == "--set-app-vol":
        app_name = sys.argv[2]
        vol_pct = sys.argv[3]
        save_volume(app_name, vol_pct)
        # Find matching streams and apply
        for s in get_sink_inputs():
            if s.get("name") == app_name:
                subprocess.run(["pactl", "set-sink-input-volume", s["id"], vol_pct + "%"], capture_output=True)
        print(json.dumps(get_sink_inputs()))
    else:
        print(json.dumps(get_sink_inputs()))
