import subprocess, json

def get_devices():
    sinks = []
    sources = []
    
    # Sinks (Output Speakers/Headphones)
    res = subprocess.run(["pactl", "list", "sinks"], capture_output=True, text=True)
    curr = {}
    for line in res.stdout.splitlines():
        line_str = line.strip()
        if line_str.startswith("Sink #"):
            if curr and "name" in curr: sinks.append(curr)
            curr = {}
        elif line_str.startswith("Name:"): curr["name"] = line_str.split("Name:")[1].strip()
        elif line_str.startswith("Description:"): curr["description"] = line_str.split("Description:")[1].strip()
    if curr and "name" in curr: sinks.append(curr)

    # Sources (Microphones only - filter out .monitor)
    res = subprocess.run(["pactl", "list", "sources"], capture_output=True, text=True)
    curr = {}
    for line in res.stdout.splitlines():
        line_str = line.strip()
        if line_str.startswith("Source #"):
            if curr and "name" in curr:
                if not curr.get("name", "").endswith(".monitor"):
                    sources.append(curr)
            curr = {}
        elif line_str.startswith("Name:"): curr["name"] = line_str.split("Name:")[1].strip()
        elif line_str.startswith("Description:"): curr["description"] = line_str.split("Description:")[1].strip()
    if curr and "name" in curr and not curr.get("name", "").endswith(".monitor"):
        sources.append(curr)

    # Default sink and source
    def_sink = ""
    def_source = ""
    res_info = subprocess.run(["pactl", "info"], capture_output=True, text=True)
    for line in res_info.stdout.splitlines():
        if "Default Sink:" in line:
            def_sink = line.split("Default Sink:")[1].strip()
        elif "Default Source:" in line:
            def_source = line.split("Default Source:")[1].strip()

    return {
        "sinks": sinks,
        "sources": sources,
        "default_sink": def_sink,
        "default_source": def_source
    }

if __name__ == "__main__":
    print(json.dumps(get_devices()))
