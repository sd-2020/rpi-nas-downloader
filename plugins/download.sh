#!/bin/bash
LINK="$1"
aria2c -d "/mnt/usbdrive/direct_downloads" "$LINK"
