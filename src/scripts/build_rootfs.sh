#!/bin/bash
set -e

# Ariba OS - RootFS Build Script
# This script creates the base filesystem using debootstrap.

WORK_DIR="$(pwd)"
BUILD_DIR="$WORK_DIR/build"
ROOTFS_DIR="$BUILD_DIR/rootfs"
ARCH="amd64"
DISTRO="bookworm"
MIRROR="http://deb.debian.org/debian/"

# Check for root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

echo "=== Building Ariba OS RootFS ==="
echo "Target: $ROOTFS_DIR"
echo "Distro: $DISTRO ($ARCH)"

# Clean previous build
# rm -rf "$ROOTFS_DIR" # optional: safety check needed before enabling
mkdir -p "$ROOTFS_DIR"

# 1. Bootstrap
if [ ! -f "$ROOTFS_DIR/bin/bash" ]; then
    echo "[*] Running debootstrap..."
    debootstrap --arch="$ARCH" --components=main,contrib,non-free-firmware "$DISTRO" "$ROOTFS_DIR" "$MIRROR"
else
    echo "[!] RootFS already exists. Skipping debootstrap."
fi

# 2. Bind Mounts for Configuration
echo "[*] Mounting dev/proc/sys..."
mount --bind /dev "$ROOTFS_DIR/dev"
mount --bind /proc "$ROOTFS_DIR/proc"
mount --bind /sys "$ROOTFS_DIR/sys"

# 3. Copy Setup Scripts
cp "$WORK_DIR/src/scripts/chroot_setup.sh" "$ROOTFS_DIR/tmp/"
chmod +x "$ROOTFS_DIR/tmp/chroot_setup.sh"

# 4. Copy Custom Components to RootFS
# AI Agent
mkdir -p "$ROOTFS_DIR/opt/ariba/agent"
cp "$WORK_DIR/src/ai/ariba_agent.py" "$ROOTFS_DIR/opt/ariba/agent/"

# GUI Scripts
mkdir -p "$ROOTFS_DIR/opt/ariba/installer"
mkdir -p "$ROOTFS_DIR/opt/ariba/store"
mkdir -p "$ROOTFS_DIR/opt/ariba/tools"

# Distribute GUI Apps
cp "$WORK_DIR/src/gui/welcome_app.py" "$ROOTFS_DIR/opt/ariba/installer/" 2>/dev/null || true
cp "$WORK_DIR/src/gui/installer_app.py" "$ROOTFS_DIR/opt/ariba/installer/" 2>/dev/null || true
cp "$WORK_DIR/src/gui/software_center.py" "$ROOTFS_DIR/opt/ariba/store/" 2>/dev/null || true
cp "$WORK_DIR/src/gui/ariba_personalizer.py" "$ROOTFS_DIR/opt/ariba/tools/" 2>/dev/null || true

# Installer Logic
cp "$WORK_DIR/src/scripts/install_os.sh" "$ROOTFS_DIR/opt/ariba/installer/"
chmod +x "$ROOTFS_DIR/opt/ariba/installer/install_os.sh"

# Config Files
mkdir -p "$ROOTFS_DIR/etc/ariba"
cp -r "$WORK_DIR/src/config/"* "$ROOTFS_DIR/etc/ariba/" 2>/dev/null || true
# Keep /opt/ariba/config for now if referenced elsewhere, but user wants /etc/ariba/os.conf etc.
# We will rely on chroot_setup to create specific conf files if not in src/config.

# Security Setup Script
cp "$WORK_DIR/src/scripts/setup_security.sh" "$ROOTFS_DIR/tmp/"
chmod +x "$ROOTFS_DIR/tmp/setup_security.sh"

# 5. Enter Chroot
echo "[*] Entering Chroot to configure system..."
chroot "$ROOTFS_DIR" /tmp/chroot_setup.sh

# 6. Cleanup mounts
echo "[*] Unmounting..."
umount "$ROOTFS_DIR/dev"
umount "$ROOTFS_DIR/proc"
umount "$ROOTFS_DIR/sys"

echo "=== RootFS Build Complete ==="
echo "Ready for Kernel installation or ISO packing."
