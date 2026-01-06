# Ariba OS

**Ariba OS** is a custom, high-performance Linux distribution based on Debian Bookworm. It is designed to provide a secure, modern, and AI-optimized environment for developers and power users.

## 🚀 Features

- **🧠 Ariba AI Assistant**: A built-in local AI agent that helps monitor system health, suggest optimizations, and execute natural language commands.
- **🛡️ Security First**: Pre-configured security policies and integrated tools for secure operations.
- **🎨 Modern UI**: A customized XFCE4 desktop environment with a sleek, modern aesthetic (Prof-Gnome-Dark theme, vibrant wallpapers).
- **⚡ Lightweight & Fast**: stripped down to essentials for maximum performance.

## 🛠️ Build from Source

You can build the Ariba OS root filesystem locally.

### Prerequisites
- A Debian/Ubuntu-based host system.
- Root privileges (`sudo`).
- Required tools: `debootstrap`, `xorriso`, `squashfs-tools`, `python3`.

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/boniyeamincse/os_ariba.git
   cd os_ariba
   ```

2. **Initialize the workspace:**
   ```bash
   ./setup_ariba.sh
   ```

3. **Build the Root Filesystem:**
   ```bash
   sudo ./src/scripts/build_rootfs.sh
   ```
   This will create a `build/rootfs` directory containing the complete OS filesystem.

## 💿 Installing to Disk

To install Ariba OS to a physical hard drive (WARNING: Erases all data):

1. Boot into the Ariba OS Live environment.
2. Run the installer script:
   ```bash
   sudo /usr/local/bin/install_os.sh /dev/sdX
   ```
   Replace `/dev/sdX` with your target drive (e.g., `/dev/sda`).

## 🤖 Using the AI Agent

The **Ariba AI Agent** runs as a system service but can also be used via CLI.

```bash
# Check system status
/opt/ariba/ai/ariba_agent.py "status"

# Ask for help
/opt/ariba/ai/ariba_agent.py "help"
```

## 📂 Project Structure

- `src/scripts`: Build systems (RootFS, Kernel, ISO).
- `src/ai`: Source code for the Python-based AI assistant.
- `src/gui`: Custom GUI applications (Welcome App, Software Center).
- `src/config`: System configuration and themes.
- `docs`: Detailed development guides and roadmaps.

## 🤝 Contributing

Contributions are welcome! Please check [docs/ARIBA_OS_DEVELOPMENT_GUIDE.md](docs/ARIBA_OS_DEVELOPMENT_GUIDE.md) for details on the architecture and build process.

## 📄 License

This project is open-source.
