#!/bin/bash

LOG_FILE="/var/log/windscribe-rotation.log"

# Define your Windscribe credentials below
# Format: "username:password"
declare -a USERS=(
  "user1:pass1"
  "user2:pass2"
  "user3:pass3"
  "user4:pass4"
  "user5:pass5"
  "user6:pass6"
  "user7:pass7"
)

echo "===== $(date) | Starting Windscribe connection check =====" >> "$LOG_FILE"

for entry in "${USERS[@]}"; do
  username="${entry%%:*}"
  password="${entry#*:}"

  echo "$(date) | 🔄 Trying Windscribe user: $username" >> "$LOG_FILE"

  windscribe disconnect >/dev/null 2>&1
  windscribe logout >/dev/null 2>&1

  echo -e "$username\n$password" | windscribe login >/dev/null 2>&1

  output=$(windscribe connect 2>&1)
  echo "$output" >> "$LOG_FILE"

  if echo "$output" | grep -qi "Connected"; then
    echo "$(date) | ✅ Successfully connected with $username" >> "$LOG_FILE"
    exit 0
  elif echo "$output" | grep -qi "quota"; then
    echo "$(date) | ⚠️ Quota reached for $username, trying next..." >> "$LOG_FILE"
    continue
  else
    echo "$(date) | ❌ Failed to connect with $username, trying next..." >> "$LOG_FILE"
    continue
  fi
done

echo "$(date) | ❌ All credentials failed or hit quota. No VPN connected." >> "$LOG_FILE"
exit 1
