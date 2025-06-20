#!/bin/bash

STATUS=$(windscribe status | head -n 1)
if ! echo "$STATUS" | grep -q "Connected"; then
  echo "$(date) | VPN disconnected. Attempting reconnect..." >> /var/log/windscribe-rotation.log
  /mnt/usbdrive/scripts/rotate-windscribe.sh
fi
