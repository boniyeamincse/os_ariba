# Ariba OS Development Guide

## 1. Project Overview
**Ariba OS** is a custom Linux distribution designed for performance and AI assistance.
- **Base**: Debian Bookworm (Stable, reliable package management).
- **Desktop**: XFCE4 (Customized).
- **AI Core**: Python-based local daemon.

## 2. Required Tools
Run the following to install the toolchain:
```bash
sudo apt update && sudo apt install -y \
    debootstrap \
    xorriso \
    mtools \
    squashfs-tools \
    build-essential \
    python3 \
    python3-pip \
    grub-pc-bin \
    grub-efi-amd64-bin
```

## 3. Development Phases

### Phase 1: Base System (RootFS)
We use `debootstrap` to create a minimal Debian root filesystem.
```bash
# Example Snippet
sudo debootstrap --arch=amd64 bookworm build/rootfs http://deb.debian.org/debian/
```

### Phase 2: Kernel Construction
For a custom OS, you may want to compile a kernel.
1. Download Linux 6.x source.
2. `make defconfig` (or `make localmodconfig` for size).
3. `make -j$(nproc) bindeb-pkg`.
4. Install the generated `.deb` files into `build/rootfs`.

### Phase 3: AI Assistant Integration
The AI assistant runs as a systemd service.

**Code Snippet: Systemd Service (`/etc/systemd/system/ariba-ai.service`)**
```ini
[Unit]
Description=Ariba AI System Assistant
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/ariba/ai/ariba_agent.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
```

**Code Snippet: AI Agent Logic (Python)**
(See `src/ai/ariba_agent.py` in your workspace)
```python
def suggest_optimization():
    # Logic to check system load
    load = os.getloadavg()
    if load[0] > 2.0:
        return "High CPU usage detected. Suggest checking running processes."
    return "System is stable."
```

### Phase 4: GUI & Theming
To achieve the "Modern" look:
1. **Install XFCE**: `apt-get install xfce4 xfce4-goodies`.
2. **Apply Theme**:
   - Download "Prof-Gnome-Dark" theme.
   - Place in `/usr/share/themes`.
   - specific settings via `xfconf-query`.

## 4. Building the ISO
The final step is packing the `build/rootfs` into an ISO.
**Workflow**:
1. Mount `dev`, `proc`, `sys` to `build/rootfs`.
2. Install Kernel & GRUB inside `chroot`.
3. Create `filesystem.squashfs` from `build/rootfs`.
4. Use `xorriso` to generate the `.iso`.

## 5. Next Steps
1. Run `./setup_ariba.sh` (Already done).
2. Install dependencies.
3. Begin Phase 1 by running the `debootstrap` command.
