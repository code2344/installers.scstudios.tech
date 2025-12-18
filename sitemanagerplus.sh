#!/usr/bin/env bash
set -e

# --------------------------------------
# SiteManager+ OS Installer Script
# Version: 1.0.0
# Installs Node.js, clones repo, sets up service, custom GRUB with splash + ASCII
# --------------------------------------

APP_NAME="sitemanager"
APP_DIR="/opt/sitemanager"
NODE_VERSION="25.2.1"
APP_USER="sitemanager"
GITHUB_REPO="https://github.com/code2344/sitemanagerplus.git"
APP_VERSION="1.0.0"
GRUB_SPLASH_URL="https://scstudios.tech/logo.png"

echo "===== SiteManager+ OS Installer ====="

# --- Detect architecture ---
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    NODE_ARCH="x64"
elif [ "$ARCH" = "aarch64" ]; then
    NODE_ARCH="arm64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi
echo "Detected architecture: $ARCH"

# --- Update system ---
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl tar git build-essential

# --- Remove old Node.js if present ---
sudo apt remove -y nodejs npm || true
sudo rm -rf /usr/local/lib/nodejs/node-v* || true

# --- Download and install Node.js ---
echo "Installing Node.js $NODE_VERSION..."
cd /tmp
NODE_DIST="node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz"
curl -LO https://nodejs.org/dist/v${NODE_VERSION}/${NODE_DIST}
sudo mkdir -p /usr/local/lib/nodejs
sudo tar -xJf $NODE_DIST -C /usr/local/lib/nodejs
echo "export PATH=/usr/local/lib/nodejs/node-v${NODE_VERSION}-linux-${NODE_ARCH}/bin:\$PATH" | sudo tee /etc/profile.d/node.sh
source /etc/profile.d/node.sh

echo "Node version: $(node -v)"
echo "NPM version: $(npm -v)"

# --- Create app user ---
if ! id -u $APP_USER >/dev/null 2>&1; then
    echo "Creating system user $APP_USER..."
    sudo useradd -r -m -s /usr/sbin/nologin $APP_USER
fi

# --- Clone GitHub repo ---
echo "Cloning SiteManager+ repo..."
sudo rm -rf $APP_DIR
sudo git clone $GITHUB_REPO $APP_DIR
sudo chown -R $APP_USER:$APP_USER $APP_DIR

# --- Install npm dependencies ---
echo "Installing npm dependencies..."
cd $APP_DIR
sudo -u $APP_USER npm install --production

# --- Create systemd service ---
SERVICE_FILE="/etc/systemd/system/${APP_NAME}.service"
echo "Creating systemd service..."
sudo tee $SERVICE_FILE > /dev/null <<EOL
[Unit]
Description=SiteManager+ OS v${APP_VERSION} Core Service
After=network-online.target
Wants=network-online.target

[Service]
User=${APP_USER}
WorkingDirectory=${APP_DIR}
ExecStart=/usr/local/lib/nodejs/node-v${NODE_VERSION}-linux-${NODE_ARCH}/bin/node server.js
Restart=always
RestartSec=2
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOL

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable $APP_NAME
sudo systemctl start $APP_NAME

# --- Setup GRUB branding with splash and ASCII ---
echo "Setting up GRUB with splash image and ASCII art..."
sudo mkdir -p /boot/grub
sudo curl -o /boot/grub/splash.png $GRUB_SPLASH_URL || true

# Update /etc/default/grub
GRUB_DEFAULT_FILE="/etc/default/grub"
sudo cp $GRUB_DEFAULT_FILE ${GRUB_DEFAULT_FILE}.bak
sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5/' $GRUB_DEFAULT_FILE
sudo sed -i 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=menu/' $GRUB_DEFAULT_FILE
sudo sed -i '/GRUB_BACKGROUND/d' $GRUB_DEFAULT_FILE
echo "GRUB_BACKGROUND=/boot/grub/splash.png" | sudo tee -a $GRUB_DEFAULT_FILE

# Add custom styled menu entry
GRUB_CUSTOM="/etc/grub.d/40_custom"
sudo tee -a $GRUB_CUSTOM > /dev/null <<'EOL'
menuentry 'SiteManager+ OS v1.0.0' --class sitemanager {
    echo ''
    echo -e "\e[1;34m========================================\e[0m"
    echo -e "\e[1;33m                                        \e[0m"
    echo -e "\e[1;33m       ░██████╗███╗░░░███╗░░░░░░░       \e[0m"
    echo -e "\e[1;33m       ██╔════╝████╗░████║░░██╗░░       \e[0m"
    echo -e "\e[1;33m       ╚█████╗░██╔████╔██║██████╗       \e[0m"
    echo -e "\e[1;33m       ░╚═══██╗██║╚██╔╝██║╚═██╔═╝       \e[0m"
    echo -e "\e[1;33m       ██████╔╝██║░╚═╝░██║░░╚═╝░░       \e[0m"
    echo -e "\e[1;33m       ╚═════╝░╚═╝░░░░░╚═╝░░░░░░░       \e[0m"
    echo -e "\e[1;33m                                        \e[0m"
    echo -e "\e[1;34m========================================\e[0m"
    echo -e "\e[1;32m          Welcome to SiteManager+ OS\e[0m"
    echo -e "\e[1;32m                 Version: 1.0.0\e[0m"
    echo -e "\e[1;34m========================================\e[0m"
    sleep 2
    set root=(hd0,1)
    linux /boot/vmlinuz-$(uname -r) root=UUID=$(blkid -s UUID -o value /dev/sda1) ro quiet splash
    initrd /boot/initrd.img-$(uname -r)
}
EOL

# Update GRUB
sudo update-grub

echo "========================================"
echo "SiteManager+ OS installation complete!"
echo "Your app is running as a systemd service: $APP_NAME"
echo "Reboot to see the custom GRUB menu with splash image and ASCII branding."
systemctl status $APP_NAME --no-pager
