#!/bin/bash

# Ariba OS - Theme Installer
# Downloads and installs modern themes (WhiteSur) and icons (Tela Circle).

THEME_DIR="/usr/share/themes"
ICON_DIR="/usr/share/icons"
TEMP_DIR="/tmp/ariba_themes"

echo "=== Installing Ariba OS Themes ==="

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root to install themes system-wide."
  exit 1
fi

mkdir -p "$TEMP_DIR"
mkdir -p "$THEME_DIR"
mkdir -p "$ICON_DIR"

# Install dependencies for theme building usually needed (sassc, git)
# apt-get install -y sassc git

cd "$TEMP_DIR"

# 1. WhiteSur GTK Theme (MacOS Big Sur like - very clean/modern)
if [ ! -d "$THEME_DIR/WhiteSur-Dark" ]; then
    echo "[*] Downloading WhiteSur GTK Theme..."
    git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git
    cd WhiteSur-gtk-theme
    # Install Dark theme, Blue accent
    ./install.sh -t blue -c Dark -N stable
    cd ..
else
    echo "[+] WhiteSur Theme already installed."
fi

# 2. Tela Circle Icons
if [ ! -d "$ICON_DIR/Tela-circle-dark" ]; then
    echo "[*] Downloading Tela Circle Icons..."
    git clone https://github.com/vinceliuice/Tela-circle-icon-theme.git
    cd Tela-circle-icon-theme
    ./install.sh -c blue
    cd ..
else
    echo "[+] Tela Circle Icons already installed."
fi

# 3. Background Wallpaper
WALLPAPER_DIR="/usr/share/backgrounds/ariba"
mkdir -p "$WALLPAPER_DIR"
echo "[*] Installing Default Wallpaper..."
if [ -f "$WORK_DIR/src/config/themes/ariba_default.png" ]; then
    cp "$WORK_DIR/src/config/themes/ariba_default.png" "$WALLPAPER_DIR/default.png"
else
    echo "Warning: Generated wallpaper not found, using fallback."
    wget -O "$WALLPAPER_DIR/default.png" "https://images.unsplash.com/photo-1451187580459-43490279c0fa?q=80&w=1920&auto=format&fit=crop"
fi

if [ -f "$WORK_DIR/src/config/themes/ariba_red.png" ]; then
    cp "$WORK_DIR/src/config/themes/ariba_red.png" "$WALLPAPER_DIR/red.png"
fi

# 4. Set as default background (XFCE)
# Note: This command needs to run as user, not root, so we skip execution here
# or append it to a user-init script.

echo "=== Theme Installation Complete ==="
echo "Themes installed to $THEME_DIR"
echo "Icons installed to $ICON_DIR"
