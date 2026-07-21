#!/usr/bin/env python3
import sys, subprocess, os, re, json

CACHE_FILE = "/tmp/qs_brightness_val"

def get_all_i2c_buses():
    try:
        res = subprocess.run(['ddcutil', 'detect'], capture_output=True, text=True)
        buses = [line.split(':')[1].strip().replace('/dev/i2c-', '') for line in res.stdout.splitlines() if 'I2C bus:' in line]
        return buses
    except Exception:
        return []

def set_hardware_ddc(val):
    buses = get_all_i2c_buses()
    for b in buses:
        subprocess.Popen([
            'ddcutil', '--noverify', '--sleep-multiplier', '.01',
            'setvcp', '10', str(val), '--bus', b
        ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def read_cache():
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r") as f:
                val = int(f.read().strip())
                return val
        except Exception:
            pass
    return 80

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
        set_hardware_ddc(new_val)
        print(new_val)
        return

    print(read_cache())

if __name__ == '__main__':
    main()
