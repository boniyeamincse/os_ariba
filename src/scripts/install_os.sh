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

# Parse Arguments
TARGET_DISK=""
Confirm="false"
FIRMWARE="bios"
MODE="auto"
USER_NAME=""
USER_PASS=""
AUTOLOGIN="false"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -y|--yes) Confirm="true" ;;
        --firmware) FIRMWARE="$2"; shift ;;
        --mode) MODE="$2"; shift ;;
        --user) USER_NAME="$2"; shift ;;
        --password) USER_PASS="$2"; shift ;;
        --autologin) AUTOLOGIN="$2"; shift ;;
        *) TARGET_DISK="$1" ;;
    esac
    shift
done

if [ -z "$TARGET_DISK" ]; then
    echo "Usage: $0 <target_disk> [--mode auto|manual] [--firmware efi|bios] [-y]"
    exit 1
fi

MOUNT_POINT="/mnt/ariba_install"

if [ "$Confirm" != "true" ]; then
    echo -e "${RED}WARNING: ALL DATA ON $TARGET_DISK WILL BE ERASED!${NC}"
    read -p "Are you sure you want to continue? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Installation aborted."
        exit 0
    fi
fi

# 1. Partitioning
echo "[*] Partitioning $TARGET_DISK ($MODE / $FIRMWARE)..."

if [ "$MODE" == "manual" ]; then
    echo "Manual mode selected. Assuming partitions are already created."
    # For manual, we'd typically need user input for which partition is root.
    # Current simplistic manual implementation: Assume Partition 1 is Root.
    # In a full impl, we'd pass partitions as args.
    # For now, we'll just skip mklabel.
else
    # Auto Mode
        if [ "$FIRMWARE" == "efi" ]; then
            parted -s "$TARGET_DISK" mklabel gpt
            # 1. ESP (512MB)
            parted -s "$TARGET_DISK" mkpart ESP fat32 1MiB 513MiB
            parted -s "$TARGET_DISK" set 1 boot on
            # 2. Root (30GB)
            parted -s "$TARGET_DISK" mkpart primary ext4 513MiB 30.5GiB
            # 3. Swap (8GB)
            parted -s "$TARGET_DISK" mkpart primary linux-swap 30.5GiB 38.5GiB
            # 4. Home (Rest)
            parted -s "$TARGET_DISK" mkpart primary ext4 38.5GiB 100%
        else
        # BIOS
        parted -s "$TARGET_DISK" mklabel msdos
        parted -s "$TARGET_DISK" mkpart primary ext4 1MiB 100%
        parted -s "$TARGET_DISK" set 1 boot on
    fi
fi

# Determine Partitions
PART_PREFIX="${TARGET_DISK}"
if [[ "$TARGET_DISK" == *"nvme"* ]]; then PART_PREFIX="${TARGET_DISK}p"; fi

if [ "$FIRMWARE" == "efi" ]; then
    PART_ESP="${PART_PREFIX}1"
    PART_ROOT="${PART_PREFIX}2"
    PART_SWAP="${PART_PREFIX}3"
    PART_HOME="${PART_PREFIX}4"
else
    PART_ROOT="${PART_PREFIX}1"
fi

# 2. Formatting
if [ "$MODE" == "auto" ]; then
    echo "[*] Formatting..."
    if [ "$FIRMWARE" == "efi" ]; then
        mkfs.fat -F32 "$PART_ESP"
        mkswap "$PART_SWAP"
        mkfs.ext4 -F "$PART_HOME"
    fi
    mkfs.ext4 -F "$PART_ROOT"
fi

# 3. Mounting
echo "[*] Mounting target..."
mkdir -p "$MOUNT_POINT"
mount "$PART_ROOT" "$MOUNT_POINT"

if [ "$FIRMWARE" == "efi" ]; then
    mkdir -p "$MOUNT_POINT/boot/efi"
    mount "$PART_ESP" "$MOUNT_POINT/boot/efi"
    
    mkdir -p "$MOUNT_POINT/home"
    mount "$PART_HOME" "$MOUNT_POINT/home"
fi

# 4. Copying Files
echo "[*] Installing System Files..."
SOURCE_DIR="/"
if [ -d "/run/live/rootfs" ]; then
    echo "  - Detected Live RootFS at /run/live/rootfs. Using it as source."
    SOURCE_DIR="/run/live/rootfs/"
    # When copying from rootfs directly, we don't need complex excludes usually, 
    # but good to stay safe.
    rsync -aAXv "$SOURCE_DIR" "$MOUNT_POINT"
else
    echo "  - copying from / (Live System Overlay)"
    rsync -aAXv --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} / "$MOUNT_POINT"
fi

# 5. System Configuration
echo "[*] Configuring System..."

# 5a. Generate fstab
echo "  - Generating /etc/fstab..."
# We use blkid to get UUIDs (Simulating genfstab -U)
ROOT_UUID=$(blkid -s UUID -o value "$PART_ROOT")
echo "# /etc/fstab: static file system information." > "$MOUNT_POINT/etc/fstab"
echo "# <file system> <mount point>   <type>  <options>       <dump>  <pass>" >> "$MOUNT_POINT/etc/fstab"
echo "UUID=$ROOT_UUID /               ext4    errors=remount-ro 0       1" >> "$MOUNT_POINT/etc/fstab"

if [ "$FIRMWARE" == "efi" ]; then
    ESP_UUID=$(blkid -s UUID -o value "$PART_ESP")
    echo "UUID=$ESP_UUID  /boot/efi       vfat    umask=0077      0       1" >> "$MOUNT_POINT/etc/fstab"

    SWAP_UUID=$(blkid -s UUID -o value "$PART_SWAP")
    echo "UUID=$SWAP_UUID none            swap    sw              0       0" >> "$MOUNT_POINT/etc/fstab"

    HOME_UUID=$(blkid -s UUID -o value "$PART_HOME")
    echo "UUID=$HOME_UUID /home           ext4    defaults,nodev,nosuid 0       2" >> "$MOUNT_POINT/etc/fstab"
    HOME_UUID=$(blkid -s UUID -o value "$PART_HOME")
    echo "UUID=$HOME_UUID /home           ext4    defaults,nodev,nosuid 0       2" >> "$MOUNT_POINT/etc/fstab"
fi

# Secure /tmp
echo "tmpfs           /tmp            tmpfs   defaults,noexec,nosuid 0       0" >> "$MOUNT_POINT/etc/fstab"


# 5b. Hostname
echo "  - Setting Hostname to 'ariba-os'..."
echo "ariba-os" > "$MOUNT_POINT/etc/hostname"
cat <<EOF > "$MOUNT_POINT/etc/hosts"
127.0.0.1   localhost
127.0.1.1   ariba-os
EOF

# 5c. Locale & Keyboard
# We copy the settings from the Live Environment if available, or default to US/English
if [ -f /etc/deployment/keyboard ]; then
    cp /etc/default/keyboard "$MOUNT_POINT/etc/default/keyboard"
else
    echo 'XKBLAYOUT="us"' > "$MOUNT_POINT/etc/default/keyboard"
fi

if [ -f /etc/locale.gen ]; then
    # Ensure en_US.UTF-8 is uncommented
    sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' "$MOUNT_POINT/etc/locale.gen"
    echo "LANG=en_US.UTF-8" > "$MOUNT_POINT/etc/default/locale"
    # We will run locale-gen in chroot later if needed, or rely on live-build's pre-gen
fi

# 5d. Timezone
# Default to UTC or copy from host
if [ -f /etc/timezone ]; then
    cp /etc/timezone "$MOUNT_POINT/etc/timezone"
    cp /etc/localtime "$MOUNT_POINT/etc/localtime"
else
    echo "UTC" > "$MOUNT_POINT/etc/timezone"
fi

# 6. User Configuration
echo "[*] Configuring User & Security..."
if [ -n "$USER_NAME" ] && [ -n "$USER_PASS" ]; then
    echo "  - Creating user '$USER_NAME'..."
    chroot "$MOUNT_POINT" useradd -m -s /bin/bash -G sudo "$USER_NAME"
    
    echo "  - Setting password..."
    echo "$USER_NAME:$USER_PASS" | chroot "$MOUNT_POINT" chpasswd
    
    # Security: Lock root account
    echo "  - Use 'sudo' for administrative tasks. Locking root account..."
    chroot "$MOUNT_POINT" passwd -l root

    # Autologin
    if [ "$AUTOLOGIN" == "true" ]; then
        echo "  - Enabling Autologin for '$USER_NAME'..."
        # Configure LightDM
        if [ -f "$MOUNT_POINT/etc/lightdm/lightdm.conf" ]; then
            sed -i "s/^#autologin-user=.*/autologin-user=$USER_NAME/" "$MOUNT_POINT/etc/lightdm/lightdm.conf"
            sed -i "s/^#autologin-user-timeout=.*/autologin-user-timeout=0/" "$MOUNT_POINT/etc/lightdm/lightdm.conf"
        else
            echo "    [!] LightDM config not found, skipping autologin."
        fi
    fi
else
    echo "  - No user specified. Root account remains unlocked with no password (unsafe!)."
fi

# 7. Installing Bootloader
echo "[*] Installing Bootloader ($FIRMWARE)..."
mount --bind /dev "$MOUNT_POINT/dev"
mount --bind /proc "$MOUNT_POINT/proc"
mount --bind /sys "$MOUNT_POINT/sys"

if [ "$FIRMWARE" == "efi" ]; then
    chroot "$MOUNT_POINT" grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=AribaOS --recheck
else
    chroot "$MOUNT_POINT" grub-install "$TARGET_DISK"
fi
chroot "$MOUNT_POINT" update-grub

# Cleanup
umount "$MOUNT_POINT/dev"
umount "$MOUNT_POINT/proc"
umount "$MOUNT_POINT/sys"
if [ "$FIRMWARE" == "efi" ]; then
    umount "$MOUNT_POINT/boot/efi"
fi
umount "$MOUNT_POINT"

echo -e "${GREEN}Installation Complete!${NC}"
