#!/bin/bash
set -e

# Ariba OS - Kernel Build Script
# Downloads and compiles a stable Linux Kernel.

WORK_DIR="$(pwd)"
BUILD_DIR="$WORK_DIR/build"
KERNEL_VERSION="6.6.8" # LTS Version
KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$KERNEL_VERSION.tar.xz"
KERNEL_DIR="$BUILD_DIR/linux-$KERNEL_VERSION"

# Check for build deps
command -v gcc >/dev/null 2>&1 || { echo "gcc not found. Install build-essential."; exit 1; }
command -v flex >/dev/null 2>&1 || { echo "flex not found. Install flex."; exit 1; }
command -v bison >/dev/null 2>&1 || { echo "bison not found. Install bison."; exit 1; }

echo "=== Building Linux Kernel $KERNEL_VERSION ==="

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# 1. Download
if [ ! -d "linux-$KERNEL_VERSION" ]; then
    if [ ! -f "linux-$KERNEL_VERSION.tar.xz" ]; then
        echo "[*] Downloading kernel source..."
        wget "$KERNEL_URL"
    fi
    echo "[*] Extracting..."
    tar -xf "linux-$KERNEL_VERSION.tar.xz"
fi

cd "$KERNEL_DIR"

# 2. Configure
if [ ! -f ".config" ]; then
    echo "[*] tailored config not found, creating default defconfig..."
    # 'make defconfig' creates a standard generic config.
    # For a minimal OS, 'make localmodconfig' (running on the target hw) is better,
    # but since we are building offline/generic, defconfig is safer to start.
    make defconfig
    
    # Optional: Enable optimization flags here via scripts/config
    # ./scripts/config --enable CONFIG_OPTIMIZE_INLINING
fi

# 3. Compile
CORES=$(nproc)
echo "[*] Compiling with $CORES cores..."
make -j"$CORES" bzImage modules

# 4. Output
echo "[*] Copying artifacts..."
mkdir -p "$WORK_DIR/build/kernel"
cp arch/x86/boot/bzImage "$WORK_DIR/build/kernel/vmlinuz-$KERNEL_VERSION"
make INSTALL_MOD_PATH="$WORK_DIR/build/kernel/modules" modules_install

echo "=== Kernel Build Complete ==="
echo "Kernel: $WORK_DIR/build/kernel/vmlinuz-$KERNEL_VERSION"
echo "Modules: $WORK_DIR/build/kernel/modules"
