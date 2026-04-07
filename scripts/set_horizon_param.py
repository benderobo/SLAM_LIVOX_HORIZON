#!/usr/bin/env python3
from pathlib import Path
import sys
import yaml

CFG = Path("/home/pi5/ros1_horizon/ws/catkin_ws/src/fast_lio/config/horizon.yaml")

ALLOWED = {
    "blind": ("preprocess", "blind", float),
    "point_filter_num": ("preprocess", "point_filter_num", int),
    "filter_size_map": ("mapping", "filter_size_map", float),
    "det_range": ("mapping", "det_range", int),
    "dense_publish_en": ("publish", "dense_publish_en", lambda v: str(v).lower() in ("1","true","yes","on")),
    "scan_publish_en": ("publish", "scan_publish_en", lambda v: str(v).lower() in ("1","true","yes","on")),
    "scan_bodyframe_pub_en": ("publish", "scan_bodyframe_pub_en", lambda v: str(v).lower() in ("1","true","yes","on")),
    "path_en": ("publish", "path_en", lambda v: str(v).lower() in ("1","true","yes","on")),
    "pcd_save_en": ("pcd_save", "pcd_save_en", lambda v: str(v).lower() in ("1","true","yes","on")),
    "interval": ("pcd_save", "interval", int),
}

def die(msg: str, code: int = 1):
    print(msg, file=sys.stderr)
    raise SystemExit(code)

def load_cfg():
    if not CFG.exists():
        die(f"Config not found: {CFG}")
    data = yaml.safe_load(CFG.read_text())
    if not isinstance(data, dict):
        die("Config root is not a dict")
    return data

def backup():
    bak = CFG.with_name(CFG.name + ".bak")
    bak.write_text(CFG.read_text())

def validate_root_keys(data):
    bad = [k for k in data.keys() if not isinstance(k, str)]
    if bad:
        die(f"Bad root keys in YAML: {bad}")

def main():
    if len(sys.argv) != 3:
        die("Usage: set_horizon_param.py <param> <value>")

    param = sys.argv[1].strip()
    raw_value = sys.argv[2].strip()

    if param not in ALLOWED:
        die(f"Unsupported param: {param}")

    section, key, caster = ALLOWED[param]

    try:
        value = caster(raw_value)
    except Exception as e:
        die(f"Bad value for {param}: {raw_value} ({e})")

    data = load_cfg()
    validate_root_keys(data)

    if section not in data or not isinstance(data[section], dict):
        data[section] = {}

    data[section][key] = value

    backup()
    CFG.write_text(yaml.safe_dump(data, sort_keys=False, default_flow_style=False))

    print(f"OK: {section}.{key} = {value}")

if __name__ == "__main__":
    main()
