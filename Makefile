# Ariba OS Makefile

# defaults
ARCH ?= amd64
SRC_DIR := src
BUILD_DIR := build
ISO_DIR := ISO
SCRIPTS := $(SRC_DIR)/scripts

.PHONY: all rootfs iso clean help

all: iso

help:
	@echo "Ariba OS Build System"
	@echo "---------------------"
	@echo "Targets:"
	@echo "  make rootfs   - Build the base Debian root filesystem (requires sudo)"
	@echo "  make iso      - Build the bootable ISO image (requires sudo, implies rootfs)"
	@echo "  make clean    - Remove build artifacts"
	@echo ""
	@echo "Usage:"
	@echo "  sudo make iso"

rootfs:
	@echo "[*] Building RootFS..."
	@sudo bash $(SCRIPTS)/build_rootfs.sh

iso: rootfs
	@echo "[*] Building ISO..."
	@sudo bash $(SCRIPTS)/build_iso.sh
	@echo "[+] ISO ready in $(ISO_DIR)/"

clean:
	@echo "[*] Cleaning build directory..."
	@sudo rm -rf $(BUILD_DIR)
	@echo "[+] Clean complete."
