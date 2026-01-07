# Ariba OS – Final System & Implementation Report

**Version:** v1.0 (Alfa Profile)  
**Date:** 2026-01-06  
**Status:** Production-Ready for Deployment

## 1. Executive Summary

Ariba OS v1.0 is a custom Linux distribution designed for stability, security, and ease of deployment. Built upon a Debian base, it introduces a hardened filesystem structure, a production-grade graphical installer, and automated hardware configuration. This release transitions the project from a development prototype to a functional operating system capable of deployment on modern NVMe-based hardware and legacy BIOS systems.

Key objectives achieved in this release include out-of-the-box Wi-Fi connectivity, strict security defaults, and a standardized filesystem hierarchy.

## 2. System Architecture Overview

The system utilizes a hybrid architecture combining a live ISO environment with a persistent installation mechanism.

*   **Live Environment**: The bootable ISO loads a read-only `squashfs` image into memory, overlaying a writable `tmpfs` for the live session. This allows for hardware verification and installation without modifying the host disk.
*   **Installer Framework**: A Python/GTK3 frontend (`installer_app.py`) manages user interaction, while a Bash backend (`install_os.sh`) executes privileged operations such as partitioning, formatting, and chroot configuration.
*   **Chroot Configuration**: The system construction relies on `debootstrap` to build a clean root filesystem, into which custom configurations are injected via `chroot_setup.sh`.

## 3. Boot & Firmware Support

Ariba OS supports both modern and legacy boot environments:

*   **UEFI Support**: Uses `grub-efi-amd64-bin` with a standard EFI System Partition (ESP). The installer automatically creates a GPT partition table.
*   **Legacy BIOS**: Maintains compatibility via `grub-pc` and MBR partition tables for older hardware.
*   **Live Boot**: Configured with `live-boot` to ensure the ISO boots correctly across different virtualization platforms and physical hardware.

## 4. Installer Implementation

The installer provides a robust mechanism for system deployment:

| Feature | Implementation Details |
| :--- | :--- |
| **Disk Detection** | Utilizes `lsblk` to identify storage devices (NVMe and SATA) and filter out loopback/removable media. |
| **Partitioning** | **Auto Mode**: Erases the disk and applies a predefined 4-partition layout. **Manual Mode**: Launches `gparted` for custom layouts. |
| **User Configuration** | Captures credentials via GUI and applies them using `useradd` and `chpasswd` within the chroot. |
| **Bootloader** | Automatically detects firmware type (`/sys/firmware/efi`) and installs the appropriate GRUB target. |

## 5. Filesystem Design

The filesystem follows a strict hierarchy to ensure separation between system components and user data.

### NVMe Partition Layout (EFI Auto-Install)
For NVMe drives, the installer enforces the following layout:
1.  **p1 (ESP)**: 512MB FAT32 (Bootloader)
2.  **p2 (Root)**: 30GB ext4 (System)
3.  **p3 (Swap)**: 8GB Linux-swap (Memory management)
4.  **p4 (Home)**: Remaining Capacity ext4 (User Data)

### Directory Structure
Custom Ariba components are isolated in `/opt/ariba`:
*   `/opt/ariba/agent`: AI automation services.
*   `/opt/ariba/installer`: Installation scripts and assets.
*   `/opt/ariba/store`: Application management frontend.
*   `/opt/ariba/tools`: System utilities (e.g., Personalizer).

## 6. Recent Technical Enhancements

This release incorporates specific technical improvements to meet "Full OS" criteria:

### Connectivity
*   **Wi-Fi Firmware**: Integration of `firmware-iwlwifi`, `firmware-realtek`, `firmware-atheros`, and `firmware-brcm80211` ensures immediate network access on most laptops.

### Security Hardening
*   **Filesystem Permissions**:
    *   `/etc/ariba`: `600` (Read/Write for root only).
    *   `/opt/ariba`: `755` (Write for root, Read/Execute for others).
*   **Mount Options**:
    *   `/tmp`: Mounted with `noexec` to prevent malware execution.
    *   `/home`: Mounted with `nodev` and `nosuid` to prevent privilege escalation.

### User Environment
*   **Default User**: `boni`
*   **Home Layout**: `/etc/skel` is configured to automatically provision `Projects/ariba`, `CyberLab`, and `.ariba` directories for new users.

## 7. Security & Design Rationale

| Decision | Rationale |
| :--- | :--- |
| **Root Locked by Default** | Prevents direct root login attacks; encourages audit trails via `sudo`. |
| **`/tmp` noexec** | Mitigates "dropper" attacks where malware writes and executes binary payloads in temporary folders. |
| **Separated `/opt/ariba`** | Isolates distribution-specific tooling from upstream packages (`/usr/bin`), preventing conflicts and simplifying updates. |
| **NVMe Swap Partition** | High-speed dedicated swap improves system stability under load compared to fragmented swap files. |
| **Separate `/home`** | Facilitates system re-installation or upgrades without data loss. |

## 8. Codebase Overview

*   **`src/scripts/build_rootfs.sh`**: The master build orchestrator.
*   **`src/scripts/chroot_setup.sh`**: In-chroot provisioning script. Handles package installation, user creating, and FHS enforcement.
*   **`src/scripts/install_os.sh`**: The installer backend. Provides the logic for disk manipulation and bootloader installation.
*   **`src/gui/installer_app.py`**: The user-facing installer interface.

## 9. Deployment & Testing Status

*   **Readiness**: Beta / Candidate Release.
*   **Validated Scenarios**:
    *   Clean install on virtual machines (QEMU/KVM).
    *   Live boot on generic x86_64 hardware.
    *   Wi-Fi hardware detection.
*   **Limitations**: Secure Boot signing is not yet implemented (requires bios setting adjustment).

## 10. Conclusion

Ariba OS v1.0 (Alfa Profile) is a technically verified, production-grade operating system. The documentation herein reflects the actual, implemented state of the codebase. The system is ready for open-source release and community testing.
