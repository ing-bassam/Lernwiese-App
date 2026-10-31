#!/usr/bin/env python3
"""Reads `xcrun simctl list devices available -j` from stdin and prints the UDID of the best simulator.

Usage: xcrun simctl list devices available -j | python3 scripts/pick_simulator.py [iphone|ipad]

Prefers the largest current devices (needed for 6.9" iPhone and 13" iPad App Store screenshots)
on the newest iOS runtime.
"""
import json
import re
import sys

PREFERRED = {
    "iphone": ["iPhone 17 Pro Max", "iPhone 16 Pro Max", "iPhone 17 Pro", "iPhone 16 Pro", "iPhone 17", "iPhone 16"],
    "ipad": ["iPad Pro 13-inch (M5)", "iPad Pro 13-inch (M4)", "iPad Air 13-inch (M3)", "iPad Air 13-inch (M2)",
             "iPad Pro (12.9-inch) (6th generation)"],
}
FALLBACK = {"iphone": ("iPhone",), "ipad": ("iPad Pro 13", "iPad Air 13", "iPad Pro (12.9", "iPad")}


def runtime_version(identifier):
    match = re.search(r"iOS-(\d+)-(\d+)", identifier)
    return (int(match.group(1)), int(match.group(2))) if match else (0, 0)


def main():
    kind = sys.argv[1] if len(sys.argv) > 1 else "iphone"
    devices = json.load(sys.stdin)["devices"]
    runtimes = sorted((r for r in devices if "iOS" in r), key=runtime_version, reverse=True)
    for runtime in runtimes:
        available = {d["name"]: d["udid"] for d in devices[runtime] if d.get("isAvailable", True)}
        for name in PREFERRED[kind]:
            if name in available:
                print(available[name])
                return
        for prefix in FALLBACK[kind]:
            for name, udid in available.items():
                if name.startswith(prefix):
                    print(udid)
                    return
    sys.exit(f"Kein {kind}-Simulator gefunden")


if __name__ == "__main__":
    main()
