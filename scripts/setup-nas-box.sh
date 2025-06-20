#!/bin/bash
set -e

USB_PATH="/mnt/usb"

echo "🔄 Updating system..."
sudo apt update && sudo apt upgrade -y

echo "💽 Installing exFAT support..."
sudo apt install exfat-fuse exfatprogs -y
sudo mkdir -p $USB_PATH

echo "📦 Installing Windscribe CLI..."
curl -O https://assets.windscribe.com/linux/windscribe-cli.deb
sudo dpkg -i windscribe-cli.deb || sudo apt install -f -y

echo "🧲 Installing qBittorrent-nox..."
sudo apt install qbittorrent-nox -y

cat <<EOF | sudo tee /etc/systemd/system/qbittorrent.service
[Unit]
Description=qBittorrent-nox
After=network.target

[Service]
User=pi
ExecStart=/usr/bin/qbittorrent-nox
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reexec
sudo systemctl enable qbittorrent
sudo systemctl start qbittorrent

echo "📁 Creating USB NAS directories..."
mkdir -p $USB_PATH/{torrents,direct_downloads,media,.filebrowser}
sudo chown -R pi:pi $USB_PATH

echo "📂 Installing Samba..."
sudo apt install samba -y

cat <<EOL | sudo tee -a /etc/samba/smb.conf

[Downloads]
   path = $USB_PATH
   browseable = yes
   writeable = yes
   create mask = 0777
   directory mask = 0777
   public = no
EOL

echo "🔐 Set Samba password for 'pi':"
sudo smbpasswd -a pi
sudo systemctl restart smbd

echo "🗂 Installing FileBrowser..."
curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
sudo mv filebrowser /usr/local/bin/filebrowser

filebrowser config init --database $USB_PATH/.filebrowser/filebrowser.db
filebrowser users add pi password --database $USB_PATH/.filebrowser/filebrowser.db

cat <<EOF | sudo tee /etc/systemd/system/filebrowser.service
[Unit]
Description=File Browser
After=network.target

[Service]
ExecStart=/usr/local/bin/filebrowser -r $USB_PATH -d $USB_PATH/.filebrowser/filebrowser.db
Restart=always
User=pi

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reexec
sudo systemctl enable filebrowser
sudo systemctl start filebrowser

echo "🌐 Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

echo "⬇️ Installing aria2 for direct link downloads..."
sudo apt install aria2 -y

echo "📜 Creating aria2 plugin script for FileBrowser..."
cat <<EOF | sudo tee $USB_PATH/.filebrowser/download.sh
#!/bin/bash
LINK="\$1"
aria2c -d "$USB_PATH/direct_downloads" "\$LINK"
EOF
chmod +x $USB_PATH/.filebrowser/download.sh

echo "⏲️ Adding Windscribe autostart to crontab..."
(crontab -l 2>/dev/null; echo "@reboot windscribe connect") | crontab -

# --------------------------------------------------
# Heimdall Dashboard
# --------------------------------------------------
echo "🌐 Installing Heimdall dashboard..."
sudo apt install nginx php-fpm php-xml unzip git composer -y
cd /var/www
sudo git clone https://github.com/linuxserver/Heimdall.git heimdall
cd heimdall
sudo composer install --no-dev
sudo chown -R www-data:www-data /var/www/heimdall

echo "🔧 Configuring Heimdall Nginx site..."
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

# --------------------------------------------------
# Final Summary
# --------------------------------------------------
echo
echo "✅ DONE! Your Raspberry Pi NAS is ready:"
echo "➡️ Heimdall Dashboard: http://<tailscale-ip>:88"
echo "➡️ FileBrowser:        http://<tailscale-ip>:8081"
echo "➡️ qBittorrent:        http://<tailscale-ip>:8080"
echo "➡️ SMB Share:          \\\\<pi-lan-ip>\\Downloads"
echo "➡️ VPN:                windscribe login && windscribe connect"
echo "➡️ Remote Access:      via Tailscale IP"
