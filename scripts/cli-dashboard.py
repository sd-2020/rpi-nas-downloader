#!/usr/bin/env python3
import os
import json
import requests
from time import sleep

QBIT_URL = "http://localhost:8080"
QBIT_USER = "admin"
QBIT_PASS = "adminadmin"
ARIA2_SESSION = "/mnt/usbdrive/aria2.session"

def get_qbit_status():
    session = requests.Session()
    try:
        r = session.post(QBIT_URL + "/api/v2/auth/login", data={'username': QBIT_USER, 'password': QBIT_PASS})
        if "Ok." not in r.text:
            print("[qBittorrent] Login failed")
            return
        torrents = session.get(QBIT_URL + "/api/v2/torrents/info").json()
        print("=== qBittorrent Downloads ===")
        for t in torrents:
            name = t.get("name", "Unknown")
            progress = round(t.get("progress", 0) * 100, 2)
            state = t.get("state", "N/A")
            print(f"{name[:40]:40} | {progress:6.2f}% | {state}")
        print()
    except Exception as e:
        print(f"[qBittorrent] Error: {e}")

def get_aria2_status():
    print("=== Aria2 (direct links) ===")
    if os.path.exists(ARIA2_SESSION):
        with open(ARIA2_SESSION) as f:
            lines = f.readlines()
            for line in lines:
                print(f"- {line.strip()}")
    else:
        print("No session file found.")
    print()

if __name__ == "__main__":
    print("📊 Raspberry Pi NAS CLI Dashboard")
    print("="*40)
    get_qbit_status()
    get_aria2_status()
