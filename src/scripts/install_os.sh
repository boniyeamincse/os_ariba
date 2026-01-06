#!/bin/bash
set -e

# Ariba OS Installer
# Installs the running system (or a specified rootfs) to a target disk.

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Ariba OS Installer ===${NC}"

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root${NC}"
  exit 1
fi

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <target_disk>"
    echo "Example: $0 /dev/sda"
    exit 1
fi

TARGET_DISK="$1"
MOUNT_POINT="/mnt/ariba_install"

echo -e "${RED}WARNING: ALL DATA ON $TARGET_DISK WILL BE ERASED!${NC}"
read -p "Are you sure you want to continue? (y/N): " confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Installation aborted."
    exit 0
fi

# 1. Partitioning (Simple Bios/MBR Layout for now)
# For EFI, a more complex parted script is needed.
echo "[*] Partitioning $TARGET_DISK..."
parted -s "$TARGET_DISK" mklabel msdos
parted -s "$TARGET_DISK" mkpart primary ext4 1MiB 100%
parted -s "$TARGET_DISK" set 1 boot on

PARTITION="${TARGET_DISK}1"
# Handle NVMe naming convention (e.g. /dev/nvme0n1p1)
if [[ "$TARGET_DISK" == *"nvme"* ]]; then
    PARTITION="${TARGET_DISK}p1"
fi

# 2. Formatting
echo "[*] Formatting $PARTITION..."
mkfs.ext4 -F "$PARTITION"

# 3. Mounting
echo "[*] Mounting target..."
mkdir -p "$MOUNT_POINT"
mount "$PARTITION" "$MOUNT_POINT"

# 4. Copying Files
echo "[*] Installing System Files (this may take a while)..."
# In a live environment, we usually copy from /run/live/rootfs/filesystem.squashfs or /
# Here we assume we are running from the build environment or a live system where / is valid source.
# Excluding pseudo-filesystems.
rsync -aAXv --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} / "$MOUNT_POINT"

# 5. Installing Bootloader (GRUB)
echo "[*] Installing GRUB..."
# Bind mount for grub-install
mount --bind /dev "$MOUNT_POINT/dev"
mount --bind /proc "$MOUNT_POINT/proc"
mount --bind /sys "$MOUNT_POINT/sys"

chroot "$MOUNT_POINT" grub-install "$TARGET_DISK"
chroot "$MOUNT_POINT" update-grub

# Cleanup
umount "$MOUNT_POINT/dev"
umount "$MOUNT_POINT/proc"
umount "$MOUNT_POINT/sys"
umount "$MOUNT_POINT"

echo -e "${GREEN}Installation Complete! You can now reboot.${NC}"
