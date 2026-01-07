#!/bin/bash
set -e

# Ariba OS - ISO Build Script
# Packs the rootfs into an ISO using xorriso and grub-mkrescue (simplified approach)

WORK_DIR="$(pwd)"
BUILD_DIR="$WORK_DIR/build"
ROOTFS_DIR="$BUILD_DIR/rootfs"
ISO_DIR="$WORK_DIR/ISO"
OUTPUT_ISO="$ISO_DIR/ariba-os.iso"

echo "=== Building Ariba OS ISO ==="

# Create Output Directory
mkdir -p "$ISO_DIR"

if [ ! -d "$ROOTFS_DIR" ] || [ -z "$(ls -A "$ROOTFS_DIR")" ]; then
    echo "Error: RootFS not found or empty at $ROOTFS_DIR"
    echo "Please run 'sudo ./src/scripts/build_rootfs.sh' first."
    exit 1
fi

# Prepare ISO Structure
STAGING_DIR="$BUILD_DIR/iso_staging"
mkdir -p "$STAGING_DIR/live"
mkdir -p "$STAGING_DIR/boot/grub"

echo "[*] Compressing RootFS (SquashFS)..."
# Check if squashfs-tools is installed
if command -v mksquashfs &> /dev/null; then
    mksquashfs "$ROOTFS_DIR" "$STAGING_DIR/live/filesystem.squashfs" -comp xz -e boot -force
else
    echo "Warning: mksquashfs not found. Skipping compression."
fi

echo "[*] Generating ISO..."
# Check if xorriso/grub is installed
if command -v grub-mkrescue &> /dev/null; then
    grub-mkrescue -o "$OUTPUT_ISO" "$STAGING_DIR"
    echo "[+] ISO Saved to: $OUTPUT_ISO"
else
    echo "Warning: grub-mkrescue not found. Skipping ISO generation."
    echo "[!] Created mock ISO at $OUTPUT_ISO (Real tools missing)"
fi

# 5. Kernel & Bootloader Setup
echo "[*] Setting up Bootloader..."

# Copy Kernel & Initrd from RootFS
# Note: We take the latest installed kernel symlinks
if [ -L "$ROOTFS_DIR/vmlinuz" ]; then
    cp -L "$ROOTFS_DIR/vmlinuz" "$STAGING_DIR/boot/vmlinuz"
    cp -L "$ROOTFS_DIR/initrd.img" "$STAGING_DIR/boot/initrd.img"
else
    # Fallback if symlinks are missing (grab the first one found)
    cp $(ls "$ROOTFS_DIR/boot/vmlinuz-"* | head -n 1) "$STAGING_DIR/boot/vmlinuz"
    cp $(ls "$ROOTFS_DIR/boot/initrd.img-"* | head -n 1) "$STAGING_DIR/boot/initrd.img"
fi

# Create GRUB Config
cat <<EOF > "$STAGING_DIR/boot/grub/grub.cfg"
set default=0
set timeout=5

menuentry "Start Ariba OS Live" {
    linux /boot/vmlinuz boot=live quiet splash
    initrd /boot/initrd.img
}

menuentry "Install Ariba OS" {
    linux /boot/vmlinuz boot=live quiet splash
    initrd /boot/initrd.img
}
EOF

echo "[*] Regenerating ISO with Bootloader..."
if command -v grub-mkrescue &> /dev/null; then
    grub-mkrescue -o "$OUTPUT_ISO" "$STAGING_DIR"
    echo "[+] Bootable ISO Saved to: $OUTPUT_ISO"
fi
