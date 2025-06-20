#!/bin/bash

ARIA2_LOG="/mnt/usbdrive/status/aria2-status.log"
ARIA2_SESSION="/mnt/usbdrive/aria2.session"

# Check if aria2c is running
if ! pgrep -x "aria2c" > /dev/null; then
    echo "$(date) | aria2c not running, restarting..." >> "$ARIA2_LOG"
    nohup aria2c --conf-path=/mnt/usbdrive/aria2.conf >> "$ARIA2_LOG" 2>&1 &
else
    echo "$(date) | aria2c is running" >> "$ARIA2_LOG"
fi

# Log what’s currently in session file
if [ -s "$ARIA2_SESSION" ]; then
    echo "$(date) | Currently tracked downloads:" >> "$ARIA2_LOG"
    cat "$ARIA2_SESSION" | while read -r line; do
        echo "   - $line" >> "$ARIA2_LOG"
    done
else
    echo "$(date) | No downloads in session." >> "$ARIA2_LOG"
fi

echo "" >> "$ARIA2_LOG"
