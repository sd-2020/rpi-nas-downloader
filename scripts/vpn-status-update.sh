#!/bin/bash

OUT_FILE="/mnt/usbdrive/status/status.json"
USER=$(windscribe account | grep Username | awk '{print $2}')
STATUS=$(windscribe status | head -n 1)
TIME=$(date '+%Y-%m-%d %H:%M:%S')

if echo "$STATUS" | grep -q "Connected"; then
  STATUS_MSG="Connected"
  CONNECTED=true
else
  STATUS_MSG="Disconnected"
  CONNECTED=false
fi

cat <<EOF > "$OUT_FILE"
{
  "status": "$STATUS_MSG",
  "user": "$USER",
  "connected": $CONNECTED,
  "time": "$TIME"
}
EOF
