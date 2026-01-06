#!/bin/bash
set -e

# Ariba OS - Internal Chroot Setup Script
# This runs INSIDE the new rootfs.

echo "=== Configuring Ariba OS (Inside Chroot) ==="

# 1. Hostname
echo "ariba-os" > /etc/hostname
echo "127.0.0.1   localhost" > /etc/hosts
echo "127.0.1.1   ariba-os" >> /etc/hosts

# 2. Apt Sources
cat <<EOF > /etc/apt/sources.list
deb http://deb.debian.org/debian/ bookworm main contrib non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free-firmware
deb http://deb.debian.org/debian/ bookworm-updates main contrib non-free-firmware
EOF

apt-get update

# 3. Install Essentials
# 3. Install Essentials
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    linux-image-amd64 \
    grub-pc \
    grub-efi-amd64-bin \
    network-manager \
    sudo \
    vim \
    nano \
    python3 \
    python3-pip \
    xfce4 \
    xfce4-goodies \
    xserver-xorg \
    firefox-esr \
    vlc \
    git \
    curl \
    wget \
    pulseaudio \
    mousepad \
    ufw \
    openssh-server

# 4. Create User
if ! id "user" &>/dev/null; then
    echo "[*] Creating default user 'user'..."
    useradd -m -s /bin/bash user
    echo "user:ariba" | chpasswd
    usermod -aG sudo user
fi
echo "root:toor" | chpasswd

# 5. Install Custom Components
echo "[*] Installing Ariba Custom Components..."

# GUI Apps
if [ -d "/opt/ariba/gui" ]; then
    echo "  - Installing GUI scripts to /usr/local/bin..."
    cp /opt/ariba/gui/*.py /usr/local/bin/
    chmod +x /usr/local/bin/*.py
fi

# Configs
if [ -d "/opt/ariba/config" ]; then
    echo "  - Applying XFCE4 Defaults..."
    # Note: Real implementation would copy to /etc/skel/.config or use xfconf-query
    # For now, just ensuring directory presence for manual tweaking
fi

# Security
if [ -f "/tmp/setup_security.sh" ]; then
    echo "[*] Running Security Setup..."
    chmod +x /tmp/setup_security.sh
    /tmp/setup_security.sh
fi

# 5b. Create 'Install Ariba OS' Desktop Shortcut
mkdir -p /usr/share/applications
cat <<EOF > /usr/share/applications/install-ariba.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Install Ariba OS
Comment=Install Ariba OS to disk
Exec=xfce4-terminal -e "sudo /usr/local/bin/install_os.sh"
Icon=drive-harddisk
Terminal=false
Categories=System;
EOF

# Ensure it appears on the desktop (for the 'user' account)
# Note: In a chroot, /home/user might not be fully populated until boot, 
# but we can try to place it if the home dir exists, or rely on /etc/skel.
mkdir -p /etc/skel/Desktop
cp /usr/share/applications/install-ariba.desktop /etc/skel/Desktop/
chmod +x /etc/skel/Desktop/install-ariba.desktop

# 6. Setup AI Service (Basic Systemd)
cat <<EOF > /etc/systemd/system/ariba-ai.service
[Unit]
Description=Ariba AI Assistant
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/ariba/ai/ariba_agent.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl enable ariba-ai.service

echo "=== Configuration Complete ==="
