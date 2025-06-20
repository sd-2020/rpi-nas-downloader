#!/bin/bash
# Install nginx and set up reverse proxy for AriaNg with basic auth

set -e

echo "[INFO] Installing nginx..."
sudo apt-get update
sudo apt-get install -y nginx apache2-utils

echo "[INFO] Copying nginx config..."
sudo cp /mnt/usbdrive/nginx/aria2-nginx.conf /etc/nginx/sites-available/ariang
sudo ln -sf /etc/nginx/sites-available/ariang /etc/nginx/sites-enabled/ariang

echo "[INFO] Setting up basic auth..."
sudo mkdir -p /etc/nginx/.auth
sudo cp /mnt/usbdrive/nginx/.htpasswd /etc/nginx/.auth/aria2

echo "[INFO] Restarting nginx..."
sudo systemctl restart nginx

echo "[DONE] AriaNg available at http://<tailscale-ip>:88/ariang"
