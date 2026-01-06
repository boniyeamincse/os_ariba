#!/bin/bash

# Ariba OS - Modern Desktop Setup Script
# Configures XFCE4 to look modern (Glassy, Dock-like panel).

echo "=== Configuring Modern Desktop Experience ==="

# 1. Reset Panel
xfconf-query -c xfce4-panel -p /panels -a -rR

# 2. CREATE TOP BAR (Panel 1)
# - Length: 100%
# - Position: Top
# - Items: Menu, Clock, Status Tray
xfconf-query -c xfce4-panel -p /panels/panel-1/position -n -t string -s "p=6;x=0;y=0"
xfconf-query -c xfce4-panel -p /panels/panel-1/length -n -t int -s 100
xfconf-query -c xfce4-panel -p /panels/panel-1/position-locked -n -t bool -s true
xfconf-query -c xfce4-panel -p /panels/panel-1/size -n -t int -s 32
# Add plugins (Whisker menu, DateDateTime, PulseAudio, Notification, Power)
xfconf-query -c xfce4-panel -p /plugins/plugin-1 -n -t string -s "whiskermenu"
xfconf-query -c xfce4-panel -p /plugins/plugin-2 -n -t string -s "separator"
xfconf-query -c xfce4-panel -p /plugins/plugin-2/style -n -t int -s 0 # Transparent separator
xfconf-query -c xfce4-panel -p /plugins/plugin-2/expand -n -t bool -s true
xfconf-query -c xfce4-panel -p /plugins/plugin-3 -n -t string -s "clock"
xfconf-query -c xfce4-panel -p /plugins/plugin-4 -n -t string -s "pulseaudio"
xfconf-query -c xfce4-panel -p /plugins/plugin-5 -n -t string -s "notification-plugin"
xfconf-query -c xfce4-panel -p /plugins/plugin-6 -n -t string -s "power-manager-plugin"

# Assign to Panel 1
xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids -n -t int -s 1 -t int -s 2 -t int -s 3 -t int -s 4 -t int -s 5 -t int -s 6

# 3. CREATE BOTTOM DOCK (Panel 2)
# - Length: 50%
# - Position: Bottom Center
# - Items: Launchers
xfconf-query -c xfce4-panel -p /panels -a -n -t int -s 2
xfconf-query -c xfce4-panel -p /panels/panel-2/position -n -t string -s "p=10;x=0;y=0"
xfconf-query -c xfce4-panel -p /panels/panel-2/length -n -t int -s 50
xfconf-query -c xfce4-panel -p /panels/panel-2/row-size -n -t int -s 48
xfconf-query -c xfce4-panel -p /panels/panel-2/autohide-behavior -n -t int -s 1 # Intelligently hide

# Add Application Launchers (Terminal, File Manager, Browser, AI Personalizer)
xfconf-query -c xfce4-panel -p /plugins/plugin-7 -n -t string -s "launcher" # Terminal
xfconf-query -c xfce4-panel -p /plugins/plugin-8 -n -t string -s "launcher" # Files
xfconf-query -c xfce4-panel -p /plugins/plugin-9 -n -t string -s "launcher" # Browser
xfconf-query -c xfce4-panel -p /plugins/plugin-10 -n -t string -s "launcher" # Ariba AI

# Assign to Panel 2
xfconf-query -c xfce4-panel -p /panels/panel-2/plugin-ids -n -t int -s 7 -t int -s 8 -t int -s 9 -t int -s 10

# 4. Desktop Settings
# Remove Home/Trash icons from desktop for cleaner look
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-home -n -t bool -s false
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-filesystem -n -t bool -s false
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-trash -n -t bool -s false

# 5. Window Manager (Compositor)
xfconf-query -c xfwm4 -p /general/use_compositing -s true
xfconf-query -c xfwm4 -p /general/frame_opacity -s 100
xfconf-query -c xfwm4 -p /general/shadow_opacity -s 50

echo "Desktop configured. Please restart XFCE."
