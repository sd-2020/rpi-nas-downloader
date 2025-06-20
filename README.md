# 🍓 Raspberry Pi NAS + Downloader Box (Bootstrap Project)

This project turns your Raspberry Pi and USB pen drive into a powerful, VPN-protected NAS & downloader with remote access, file management, and smart VPN fallback.

---

## 🧰 Features

| Feature           | Tool              | Access                                  |
|------------------|-------------------|-----------------------------------------|
| Torrent downloads | qBittorrent-nox   | http://<tailscale-ip>:8080              |
| Direct downloads  | aria2 + plugin    | via FileBrowser plugin                  |
| File manager UI   | FileBrowser       | http://<tailscale-ip>:8081              |
| Dashboard         | Heimdall          | http://<tailscale-ip>:88                |
| File share (LAN)  | Samba (SMB)       | `\\<pi-ip>\Downloads`                |
| VPN protection    | Windscribe        | CLI + auto-switch on quota              |
| Remote access     | Tailscale         | Auto mesh VPN, no port forwarding       |

---

## 📦 Folder Structure

```bash
rpi-nas-box-bootstrap/
├── scripts/
│   ├── setup-nas-box.sh         # Full setup script
│   └── rotate-windscribe.sh     # Failover VPN credential logic
├── plugins/
│   └── download.sh              # FileBrowser plugin for direct links
├── docs/
│   └── USAGE.md                 # Quick usage notes
├── .gitignore
├── LICENSE
└── README.md                    # You are here
```

---

## 🧱 Requirements

- Raspberry Pi 3B+ or newer
- Raspberry Pi OS (Lite preferred)
- USB pen drive (formatted as exFAT)
- Internet access
- SSH access or monitor/keyboard
- Windscribe (7 credentials)
- Tailscale account (free)

---

## 🔧 1. Flash and Setup Raspberry Pi

- Flash [Raspberry Pi OS](https://www.raspberrypi.com/software/)
- Enable SSH by placing a blank `ssh` file in `/boot`
- Boot and SSH into Pi:
  ```bash
  ssh pi@<your-raspberry-pi-ip>
  ```

---

## 💽 2. Prepare USB Drive

- Format USB pen drive as **exFAT** on Windows
- Label it `NASDRIVE` (optional)
- Plug it into Raspberry Pi

---

## 📁 3. Download & Extract Project

```bash
cd ~
wget <your-zip-url>
unzip rpi-nas-box-bootstrap.zip
cd rpi-nas-box-bootstrap
chmod +x scripts/*.sh plugins/*.sh
```

---

## 🔐 4. Configure VPN Credentials

Edit `scripts/rotate-windscribe.sh`:

```bash
nano scripts/rotate-windscribe.sh
```

Replace:

```bash
"user1:pass1"
"user2:pass2"
...
```

With your **actual Windscribe credentials**.

---

## 🚀 5. Run Setup Script

```bash
sudo ./scripts/setup-nas-box.sh
```

This installs:

- Windscribe CLI
- qBittorrent + Web UI (port 8080)
- aria2 for direct downloads
- FileBrowser (port 8081)
- Samba share
- Tailscale
- Heimdall dashboard (port 88)

---

## 🌐 6. Connect to VPN and Tailscale

```bash
windscribe login
windscribe connect
sudo tailscale up
```

Tailscale gives you a remote-accessible IP like `100.x.x.x`

---

## 🌍 7. Access Services

| Tool         | Address                           |
|--------------|------------------------------------|
| FileBrowser  | http://<tailscale-ip>:8081         |
| qBittorrent  | http://<tailscale-ip>:8080         |
| Heimdall     | http://<tailscale-ip>:88           |
| Samba Share  | `\\<pi-lan-ip>\Downloads`       |
| SSH          | `ssh pi@<tailscale-ip>`            |

---

## 🔗 8. Add FileBrowser Download Plugin

In FileBrowser Web UI:

- Go to ⚙️ Settings → Plugins → ➕ Add Plugin
  - Name: `Download via Link`
  - Command: `/mnt/usbdrive/.filebrowser/download.sh`
  - Arguments: `{{ prompt }}`

To use:
- Right-click in white space → Plugin → Download via Link
- Paste any direct link (zip, mp4, etc.)

---

## 🧠 9. Automate VPN Fallback

This script auto-detects if Windscribe quota is exceeded and logs in with the next account.

To auto-run on boot:

```bash
crontab -e
@reboot /mnt/usbdrive/scripts/rotate-windscribe.sh
```

---

## 📜 Notes

- All downloads and storage go to: `/mnt/usbdrive/`
- USB drive remains **Windows-readable** (exFAT)
- You can unplug it anytime and read files from any PC
- Use `windscribe status` to check VPN connection
- Logs saved at: `/var/log/windscribe-rotation.log`

---

## 🧾 License

MIT — Feel free to fork, adapt, or redistribute.


---

## 🔄 VPN Status Page (Web)

The status of the current VPN user, quota issues, and whether the VPN is connected is available at:

```
http://<tailscale-ip>:8081/status/status.html
```

## ♻️ VPN Watchdog (auto reconnect)

- A cron job runs every 5 minutes to check VPN connection
- If disconnected or quota is hit, it switches to the next user
- It logs to: `/var/log/windscribe-rotation.log`

To enable:

```bash
crontab -e
*/5 * * * * /mnt/usbdrive/scripts/vpn-watchdog.sh
```

## 🧠 Aria2 Auto Resume Support

Aria2 now uses:

- `--continue=true`
- Session file at `/mnt/usbdrive/aria2.session`

So any failed direct download will resume automatically on retry.


---

## 📊 Combined Web Dashboard

A single dashboard view combining qBittorrent and FileBrowser:

- **URL**: http://<tailscale-ip>:8081/status/dashboard.html
- **Served via**: FileBrowser (from USB drive)

You can bookmark this for 1-click access to both tools.

---

## 🖥 CLI Dashboard (for SSH use)

SSH into the Pi and run:

```bash
python3 scripts/cli-dashboard.py
```

This shows:

- Active qBittorrent downloads
- Direct download links tracked in Aria2 session

Great for headless or terminal-only access.


---

## 🔁 Aria2 Auto-Restart + Resume (via Cron)

Aria2 is monitored every 5 minutes to ensure:

- It's running
- Any session downloads are resumed
- Status is logged

**Log File:** `/mnt/usbdrive/status/aria2-status.log`

### 🛠 Add to Cron:

```bash
crontab -e
*/5 * * * * /mnt/usbdrive/scripts/aria2-watchdog.sh
```

This ensures your direct link downloads **always recover** even after unexpected failures.


---

## 🌐 AriaNg – Web UI for Aria2 (Direct Downloads)

You can now control **direct downloads** from your browser!

- **URL:** `http://<tailscale-ip>:8081/ariang/index.html`
- This page redirects to: `https://ariang.mayswind.net/latest/`
- AriaNg will auto-connect to your Pi via RPC on port 6800

### 🛠 Aria2 RPC Config
Located in `/mnt/usbdrive/aria2.conf`, includes:

```
enable-rpc=true
rpc-allow-origin-all=true
rpc-listen-all=true
rpc-listen-port=6800
rpc-secret=mysecuretoken
```

### 🔐 Connect AriaNg:
When prompted:
- RPC Host: `http://<tailscale-ip>:6800/jsonrpc`
- Secret Token: `mysecuretoken`

✅ Now you can:
- Add download links
- Pause/resume individual or all files
- View download speed, progress, and logs



---

## 🔐 Secure Reverse Proxy (Nginx + Auth for AriaNg)

To access Aria2 via browser securely and offline:

1. Run setup:
   ```bash
   sudo bash /mnt/usbdrive/scripts/nginx-aria2-proxy.sh
   ```

2. Place AriaNg static files in:
   ```
   /mnt/usbdrive/ariang/
   ```

3. Access UI via:
   ```
   http://<tailscale-ip>:88/ariang/
   ```

4. AriaNg RPC target:
   ```
   http://<tailscale-ip>:88/rpc/aria2
   ```

### 👤 Authentication
- Username: `ariauser`
- Password: (configured via `.htpasswd` — replace placeholder)

Update `.htpasswd` securely using:
```bash
sudo htpasswd -c /mnt/usbdrive/nginx/.htpasswd ariauser
```


---

## 🔐 HTTPS (TLS) with Self-Signed Certificate

This project supports serving AriaNg + RPC securely over HTTPS using a self-signed certificate.

### 🛠 Steps:

1. Generate certificate:
```bash
sudo bash /mnt/usbdrive/scripts/generate-selfsigned-cert.sh
```

2. Set up Nginx with HTTPS:
```bash
sudo bash /mnt/usbdrive/scripts/nginx-aria2-proxy.sh
```

3. Access UI securely:
```
https://<tailscale-ip>:88/ariang/
```

### ⚠️ Note:
- Your browser will show a warning for self-signed cert — this is normal. Proceed to continue.
- You can add the cert as trusted manually in your OS if preferred.

