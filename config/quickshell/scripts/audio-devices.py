import subprocess
import json
import re

def get_devices():
    sinks = []
    sources = []
    def_sink = ""
    def_source = ""

    # 1. Native PipeWire dump (fast, no pactl connection leaks)
    try:
        res = subprocess.run(["pw-dump"], capture_output=True, text=True, timeout=2)
        if res.returncode == 0 and res.stdout:
            data = json.loads(res.stdout)
            seen_sinks = set()
            seen_sources = set()
            for item in data:
                if item.get("type") == "PipeWire:Interface:Node":
                    info = item.get("info", {})
                    props = info.get("props", {})
                    media_class = props.get("media.class", "")
                    node_name = props.get("node.name", "")
                    node_desc = props.get("node.description", node_name)
                    
                    if media_class == "Audio/Sink" and node_name not in seen_sinks:
                        seen_sinks.add(node_name)
                        sinks.append({"name": node_name, "description": node_desc})
                    elif media_class == "Audio/Source" and node_name not in seen_sources:
                        # Exclude monitor sources (speaker feedback loop)
                        if not node_name.endswith(".monitor") and "monitor" not in node_name.lower():
                            seen_sources.add(node_name)
                            sources.append({"name": node_name, "description": node_desc})
    except Exception:
        pass

    # 2. Fallback to pactl if pw-dump failed or gave no sinks
    if not sinks:
        try:
            res = subprocess.run(["pactl", "list", "sinks"], capture_output=True, text=True, timeout=1.5)
            curr = {}
            for line in res.stdout.splitlines():
                line_str = line.strip()
                if line_str.startswith("Sink #"):
                    if curr and "name" in curr: sinks.append(curr)
                    curr = {}
                elif line_str.startswith("Name:"): curr["name"] = line_str.split("Name:")[1].strip()
                elif line_str.startswith("Description:"): curr["description"] = line_str.split("Description:")[1].strip()
            if curr and "name" in curr: sinks.append(curr)
        except Exception:
            pass

    if not sources:
        try:
            res = subprocess.run(["pactl", "list", "sources"], capture_output=True, text=True, timeout=1.5)
            curr = {}
            for line in res.stdout.splitlines():
                line_str = line.strip()
                if line_str.startswith("Source #"):
                    if curr and "name" in curr and not curr.get("name", "").endswith(".monitor"):
                        sources.append(curr)
                    curr = {}
                elif line_str.startswith("Name:"): curr["name"] = line_str.split("Name:")[1].strip()
                elif line_str.startswith("Description:"): curr["description"] = line_str.split("Description:")[1].strip()
            if curr and "name" in curr and not curr.get("name", "").endswith(".monitor"):
                sources.append(curr)
        except Exception:
            pass

    # 3. Default Sink & Source
    try:
        res_sink = subprocess.run(["pactl", "get-default-sink"], capture_output=True, text=True, timeout=1)
        if res_sink.returncode == 0: def_sink = res_sink.stdout.strip()
    except Exception:
        pass

    try:
        res_src = subprocess.run(["pactl", "get-default-source"], capture_output=True, text=True, timeout=1)
        if res_src.returncode == 0: def_source = res_src.stdout.strip()
    except Exception:
        pass

    # If defaults are still empty, pick the first sink/source as default fallback
    if not def_sink and sinks:
        def_sink = sinks[0]["name"]
    if not def_source and sources:
        def_source = sources[0]["name"]

    return {
        "sinks": sinks,
        "sources": sources,
        "default_sink": def_sink,
        "default_source": def_source
    }

if __name__ == "__main__":
    print(json.dumps(get_devices()))
