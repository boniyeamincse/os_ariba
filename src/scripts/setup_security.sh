#!/bin/bash

# Ariba OS - Network & Security Setup
# Implements basic firewall using UFW and configures SSH.

echo "=== Configuring Network Security ==="

# 1. Install Security Tools (apt integration)
# These should be in the rootfs but this script ensures config is ready
# apt-get install -y ufw fail2ban openssh-server

# 2. Configure UFW (Uncomplicated Firewall)
echo "[*] Setting up UFW..."
ufw default deny incoming
ufw default allow outgoing

# Allow SSH (limit rate)
ufw limit ssh

# Allow internal AI daemon (if running on a specific port, e.g., 5000)
# ufw allow 5000/tcp

# Enable
# ufw --force enable
echo "UFW rules configured (Default: Deny Incoming, Limit SSH)."

# 3. Secure SSH
echo "[*] Hardening SSH..."
SSH_CONFIG="/etc/ssh/sshd_config"

if [ -f "$SSH_CONFIG" ]; then
    # Disable Root Login
    sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG" || echo "PermitRootLogin no" >> "$SSH_CONFIG"
    
    # Disable Empty Passwords
    sed -i 's/^PermitEmptyPasswords.*/PermitEmptyPasswords no/' "$SSH_CONFIG" || echo "PermitEmptyPasswords no" >> "$SSH_CONFIG"
    
    echo "SSH Config updated for security."
else
    echo "Warning: $SSH_CONFIG not found (SSH not installed yet?)."
fi

# 4. Create AI Network Monitor Stub
mkdir -p /opt/ariba/security
cat <<EOF > /opt/ariba/security/network_monitor.py
import subprocess
import time

def check_open_ports():
    """Scans for open listening ports."""
    try:
        # Uses ss (socket statistics)
        res = subprocess.run(["ss", "-tuln"], capture_output=True, text=True)
        return res.stdout
    except FileNotFoundError:
        return "Error: 'ss' command not found."

def check_traffic_spike():
    """Placeholder for traffic anomaly detection."""
    # Real logic would read /proc/net/dev
    with open("/proc/net/dev", "r") as f:
        data = f.readlines()
    return data[2:] # Header skip

if __name__ == "__main__":
    print("--- Ariba Network Monitor ---")
    print("Open Ports:")
    print(check_open_ports())
EOF
chmod +x /opt/ariba/security/network_monitor.py

echo "=== Security Setup Complete ==="
