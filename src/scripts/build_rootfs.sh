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
mkdir -p "$ROOTFS_DIR/opt/ariba/ai"
cp "$WORK_DIR/src/ai/ariba_agent.py" "$ROOTFS_DIR/opt/ariba/ai/"

# GUI Scripts
mkdir -p "$ROOTFS_DIR/opt/ariba/gui"
cp "$WORK_DIR/src/gui/"*.py "$ROOTFS_DIR/opt/ariba/gui/" 2>/dev/null || true

# Config Files
mkdir -p "$ROOTFS_DIR/opt/ariba/config"
cp -r "$WORK_DIR/src/config/"* "$ROOTFS_DIR/opt/ariba/config/" 2>/dev/null || true

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
