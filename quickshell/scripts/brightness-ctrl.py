#!/usr/bin/env python3
import sys, subprocess, os, re, time

CACHE_FILE = "/tmp/qs_brightness_val"
BUS_CACHE = "/tmp/qs_valid_buses"

def get_valid_buses():
    if os.path.exists(BUS_CACHE):
        try:
            with open(BUS_CACHE, "r") as f:
                buses = f.read().split()
                if buses:
                    return buses
        except Exception:
            pass
    # Detect valid working buses once
    res = subprocess.run(['ddcutil', 'detect'], capture_output=True, text=True)
    all_buses = [line.split(':')[1].strip().replace('/dev/i2c-', '') for line in res.stdout.splitlines() if 'I2C bus:' in line]
    valid = []
    for bus in all_buses:
        r = subprocess.run(['ddcutil', '--noverify', '--sleep-multiplier', '.05', 'getvcp', '10', '--bus', bus], capture_output=True, text=True)
        if "current value" in r.stdout:
            valid.append(bus)
    if not valid:
        valid = all_buses
    try:
        with open(BUS_CACHE, "w") as f:
            f.write(" ".join(valid))
    except Exception:
        pass
    return valid

def read_cache():
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r") as f:
                val = int(f.read().strip())
                return val
        except Exception:
            pass
    # Initial seed from ddcutil
    buses = get_valid_buses()
    for b in buses:
        r = subprocess.run(['ddcutil', '--noverify', '--sleep-multiplier', '.05', 'getvcp', '10', '--bus', b], capture_output=True, text=True)
        m = re.search(r'current value =\s*(\d+)', r.stdout)
        if m:
            val = int(m.group(1))
            write_cache(val)
            return val
    return 95

def write_cache(val):
    try:
        with open(CACHE_FILE, "w") as f:
            f.write(str(val))
    except Exception:
        pass

def main():
    if len(sys.argv) > 1:
        arg = sys.argv[1]
        cur = read_cache()
        if arg == 'up':
            new_val = min(100, cur + 5)
        elif arg == 'down':
            new_val = max(5, cur - 5)
        else:
            try:
                new_val = int(arg)
            except ValueError:
                new_val = cur
        
        write_cache(new_val)
        
        # Fire non-blocking asynchronous hardware ddcutil in background
        buses = get_valid_buses()
        for b in buses:
            subprocess.Popen([
                'ddcutil', '--noverify', '--sleep-multiplier', '.05',
                'setvcp', '10', str(new_val), '--bus', b
            ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
        print(new_val)
        return

    print(read_cache())

if __name__ == '__main__':
    main()
