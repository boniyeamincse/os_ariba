#!/bin/bash
# GUI Customization Script for Ariba OS
# Applies a modern dark theme and icon set to XFCE4

THEME_NAME="WhiteSur-Dark"
ICON_THEME="Tela-circle-dark"

echo "Applying Ariba OS Modern Theme..."

# Configure GTK Theme
xfconf-query -c xsettings -p /Net/ThemeName -s "$THEME_NAME"
xfconf-query -c xfwm4 -p /general/theme -s "$THEME_NAME"

# Configure Icon Theme
xfconf-query -c xsettings -p /Net/IconThemeName -s "$ICON_THEME"

# Set Font
xfconf-query -c xsettings -p /Gtk/FontName -s "Inter Regular 10"

# Enable Compositor (for transparency)
xfconf-query -c xfwm4 -p /general/use_compositing -s true
xfconf-query -c xfwm4 -p /general/frame_opacity -s 100

echo "Theme applied. Restart XFCE or log out/in to see changes."
