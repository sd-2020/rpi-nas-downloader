#!/bin/bash
# Generate self-signed TLS certificate for nginx

CERT_DIR="/etc/nginx/certs"
DOMAIN="pi.local"

echo "[INFO] Creating cert directory..."
sudo mkdir -p "$CERT_DIR"

echo "[INFO] Generating self-signed certificate..."
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout "$CERT_DIR/aria2.key" \
  -out "$CERT_DIR/aria2.crt" \
  -subj "/C=IN/ST=NA/L=Pi City/O=Pi Inc./CN=$DOMAIN"

echo "[INFO] TLS certificate created at $CERT_DIR"
