#!/bin/bash
set -e

USB_PATH="/mnt/usb"

echo "🔄 Updating system..."
sudo apt update && sudo apt upgrade -y

echo "💽 Installing exFAT, tools, and dependencies..."
sudo apt install -y exfat-fuse exfatprogs curl unzip git composer nginx php-fpm php-xml qbittorrent-nox aria2 samba

echo "📁 Mounting USB if not mounted..."
sudo mkdir -p $USB_PATH
sudo mount -a || true

echo "📂 Creating directories..."
mkdir -p $USB_PATH/{torrents,direct_downloads,media,.filebrowser}

# Skip chown if exFAT or FAT32
if ! grep -qi 'exfat\|vfat' <<< "$(findmnt -n -o FSTYPE $USB_PATH)"; then
  echo "🔐 Setting ownership to admin:admin..."
  sudo chown -R admin:admin $USB_PATH
else
  echo "⚠️ Skipping chown — filesystem does not support ownership (likely exFAT/FAT32)"
fi

echo "📦 Installing qBittorrent as a systemd service..."
cat <<EOF | sudo tee /etc/systemd/system/qbittorrent.service
[Unit]
Description=qBittorrent-nox
After=network.target

[Service]
User=admin
ExecStart=/usr/bin/qbittorrent-nox
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reexec
sudo systemctl enable qbittorrent
sudo systemctl start qbittorrent

echo "🗂 Installing FileBrowser..."
curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh -o get_filebrowser.sh
chmod +x get_filebrowser.sh
./get_filebrowser.sh

FOUND_FB=$(find . -type f -name "filebrowser" -perm -111 | head -n 1)
if [ -n "$FOUND_FB" ]; then
  sudo mv "$FOUND_FB" /usr/local/bin/filebrowser
  sudo chmod +x /usr/local/bin/filebrowser
else
  echo "❌ Could not find FileBrowser binary after install"
  exit 1
fi

filebrowser config init --database $USB_PATH/.filebrowser/filebrowser.db
filebrowser users add admin password --database $USB_PATH/.filebrowser/filebrowser.db

cat <<EOF | sudo tee /etc/systemd/system/filebrowser.service
[Unit]
Description=File Browser
After=network.target

[Service]
ExecStart=/usr/local/bin/filebrowser -r $USB_PATH -d $USB_PATH/.filebrowser/filebrowser.db
Restart=always
User=admin

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reexec
sudo systemctl enable filebrowser
sudo systemctl start filebrowser

echo "🌐 Setting up Samba for Windows sharing..."
cat <<EOL | sudo tee -a /etc/samba/smb.conf

[Downloads]
   path = $USB_PATH
   browseable = yes
   writeable = yes
   create mask = 0777
   directory mask = 0777
   public = no
EOL

echo "🔐 Set Samba password for 'admin':"
sudo smbpasswd -a admin
sudo systemctl restart smbd

echo "⬇️ Setting up FileBrowser aria2 plugin..."
cat <<EOF | tee $USB_PATH/.filebrowser/download.sh
#!/bin/bash
LINK="$1"
aria2c -d "$USB_PATH/direct_downloads" "$LINK"
EOF

chmod +x $USB_PATH/.filebrowser/download.sh

echo "🌐 Installing Heimdall dashboard..."
cd /var/www
sudo git clone https://github.com/linuxserver/Heimdall.git heimdall
cd heimdall
sudo composer install --no-dev
sudo chown -R www-data:www-data /var/www/heimdall

sudo bash -c 'cat > /etc/nginx/sites-available/heimdall <<EOF
server {
    listen 88 default_server;
    root /var/www/heimdall/public;

    index index.php;
    server_name _;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.4-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF'

sudo ln -s /etc/nginx/sites-available/heimdall /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo systemctl reload nginx
sudo systemctl enable nginx php7.4-fpm

echo "✅ Setup complete! Access via:"
echo "➡️ qBittorrent: http://<tailscale-ip>:8080"
echo "➡️ FileBrowser: http://<tailscale-ip>:8081"
echo "➡️ Heimdall: http://<tailscale-ip>:88"
echo "➡️ SMB Share: \\<pi-ip>\Downloads"
