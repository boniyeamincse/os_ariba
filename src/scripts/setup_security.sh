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

# 5. File System Security Defaults
echo "[*] Applying File System Security Defaults..."

# /etc/ariba permissions (root:root 600)
mkdir -p /etc/ariba
chown root:root /etc/ariba
chmod 600 /etc/ariba
echo "  - /etc/ariba permissions set to 600"

# /opt/ariba permissions (root:root 755)
# Ensure /opt/ariba exists (created in prior steps)
chown -R root:root /opt/ariba
chmod -R 755 /opt/ariba
echo "  - /opt/ariba permissions set to 755"

# Secure Mounts
# /tmp noexec
# Check if /tmp is already in fstab, if not add it
if ! grep -q " /tmp " /etc/fstab; then
    echo "tmpfs /tmp tmpfs defaults,noexec,nosuid 0 0" >> /etc/fstab
    echo "  - Added /tmp noexec to /etc/fstab"
else
    # If it exists, ensure noexec is present (simple append for now, or sed if needed)
    # For simplicity in this script, we assume a fresh build environment.
    echo "  - /tmp already in fstab, ensuring noexec..."
    sed -i '/\/tmp/s/defaults/defaults,noexec/' /etc/fstab
fi

# /home nodev,nosuid
# We add a placeholder or update fstab if /home partition is known.
# Since we are in a build script, we might not know the exact UUID, but we can set defaults.
# However, usually the installer sets fstab. 
# We will add a comment/check here or just enforce it if it's a separate mount point.
# A safe approach for default fstab generation:
echo "  - Note: dependent on installer for /home UUID."


echo "=== Security Setup Complete ==="
