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
    openssh-server \
    live-boot \
    live-config \
    python3-gi \
    gir1.2-gtk-3.0 \
    xfce4-terminal \
    wireless-tools \
    wpasupplicant \
    ethtool \
    net-tools \
    network-manager-gnome \
    systemd-timesyncd \
    parted \
    dosfstools \
    e2fsprogs \
    util-linux \
    cryptsetup \
    cryptsetup-bin \
    firmware-linux \
    firmware-linux-nonfree \
    firmware-iwlwifi \
    firmware-realtek \
    firmware-atheros \
    firmware-libertas \
    firmware-brcm80211 \
    rfkill

# 4. Create User (Moved to after skel setup)
# (See below)


# 4b. Configure /etc/skel (Default Home Layout)
echo "[*] Configuring Default Home Layout (/etc/skel)..."
mkdir -p /etc/skel/Desktop
mkdir -p /etc/skel/Documents
mkdir -p /etc/skel/Downloads
mkdir -p /etc/skel/Projects/ariba
mkdir -p /etc/skel/CyberLab
mkdir -p /etc/skel/.ariba

# Default files
touch /etc/skel/.ariba/preferences.conf
touch /etc/skel/.ariba/history.log

# Verify ownership of skel (root:root is standard, copied to user on create)


# 4b. Autostart Welcome App
mkdir -p /etc/xdg/autostart
cat <<EOF > /etc/xdg/autostart/ariba-welcome.desktop
[Desktop Entry]
Type=Application
Name=Welcome to Ariba OS
Exec=/usr/bin/python3 /opt/ariba/installer/welcome_app.py
Icon=start-here
Terminal=false
StartupNotify=false
EOF

# 4c. Autostart Network Manager Applet
cat <<EOF > /etc/xdg/autostart/nm-applet.desktop
[Desktop Entry]
Type=Application
Name=Network Manager
Exec=nm-applet
Icon=nm-device-wireless
Terminal=false
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# 5. Install Custom Components
echo "[*] Installing Ariba Custom Components..."

# Wallpaper
if [ -f "/etc/ariba/ariba_wallpaper.jpg" ]; then
    echo "  - Installing Wallpaper..."
    mkdir -p /usr/share/backgrounds
    cp /etc/ariba/ariba_wallpaper.jpg /usr/share/backgrounds/ariba_wallpaper.jpg
fi

# GUI Apps
# Apps are already in /opt/ariba/{installer,store,tools}, no need to copy to /usr/local/bin unless we specifically want them on PATH.
# We will skip copying to /usr/local/bin to respect the /opt structure requested.


# Configs
if [ -d "/etc/ariba" ]; then
    echo "  - Applying XFCE4 Defaults..."
    # Placeholder
fi

# Security
if [ -f "/tmp/setup_security.sh" ]; then
    echo "[*] Running Security Setup..."
    chmod +x /tmp/setup_security.sh
    /tmp/setup_security.sh
fi

# 5b. Create Desktop Shortcuts
mkdir -p /usr/share/applications

# GUI Installer
cat <<EOF > /usr/share/applications/install-ariba.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Install Ariba OS
Comment=Install Ariba OS to disk
Exec=pkexec /usr/bin/python3 /opt/ariba/installer/installer_app.py
Icon=drive-harddisk
Terminal=false
Categories=System;
EOF

# Software Center
cat <<EOF > /usr/share/applications/ariba-store.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Software Center
Comment=Install Applications
Exec=/usr/bin/python3 /opt/ariba/store/software_center.py
Icon=system-software-install
Terminal=false
Categories=System;
EOF

# Personalizer
cat <<EOF > /usr/share/applications/ariba-personalizer.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Ariba Personalizer
Comment=Customize Desktop
Exec=/usr/bin/python3 /opt/ariba/tools/ariba_personalizer.py
Icon=preferences-desktop-theme
Terminal=false
Categories=Settings;
EOF

# Ensure shortcuts appear on the desktop
# Note: In a chroot, /home/user might not be fully populated until boot, 
# but we can try to place it if the home dir exists, or rely on /etc/skel.
mkdir -p /etc/skel/Desktop
cp /usr/share/applications/install-ariba.desktop /etc/skel/Desktop/
chmod +x /etc/skel/Desktop/install-ariba.desktop

# Add Files and Settings to Desktop
cp /usr/share/applications/thunar.desktop /etc/skel/Desktop/ 2>/dev/null || true
cp /usr/share/applications/xfce4-settings-manager.desktop /etc/skel/Desktop/ 2>/dev/null || true
chmod +x /etc/skel/Desktop/*.desktop

# 6. Setup AI Service (Basic Systemd)
cat <<EOF > /etc/systemd/system/ariba-ai.service
[Unit]
Description=Ariba AI Assistant
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/ariba/agent/ariba_agent.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl enable ariba-ai.service


# 7. Enforce Filesystem Hierarchy
echo "[*] Enforcing Ariba Filesystem Hierarchy..."
mkdir -p /var/log/ariba
touch /var/log/ariba/installer.log
touch /var/log/ariba/agent.log
touch /var/log/ariba/updater.log
touch /var/log/ariba/security.log
chmod 600 /var/log/ariba/*.log

mkdir -p /var/cache/ariba
mkdir -p /var/lib/ariba

# /run/ariba via tmpfiles.d
echo "d /run/ariba 0755 root root -" > /etc/tmpfiles.d/ariba.conf

# Default Configs
echo "[block]" > /etc/ariba/os.conf
echo "version=1.0" >> /etc/ariba/os.conf
echo "update_channel=stable" >> /etc/ariba/os.conf

echo "[agent]" > /etc/ariba/agent.conf
echo "enabled=true" >> /etc/ariba/agent.conf
echo "log_level=info" >> /etc/ariba/agent.conf

echo "[update]" > /etc/ariba/update.conf
echo "url=https://update.aribaos.org" >> /etc/ariba/update.conf

# Verify symlinks (UsrMerge)
if [ -L /bin ] && [ -L /sbin ] && [ -L /lib ]; then
    echo "  - UsrMerge verified: bin/sbin/lib are symlinks."
else
    echo "  - Warning: UsrMerge not fully detected."
fi


# 4. Create Default User (Must be after /etc/skel setup)
if ! id "boni" &>/dev/null; then
    echo "[*] Creating default user 'boni'..."
    useradd -m -s /bin/bash boni
    echo "boni:ariba" | chpasswd
    usermod -aG sudo boni
fi
echo "root:toor" | chpasswd

echo "=== Configuration Complete ==="


