#!/bin/bash

# Must run as root
if [[ $EUID -ne 0 ]]; then
   echo "Run this script as root or with sudo"
   exit 1
fi

echo "======================================"
echo " Ubuntu Server Initial Security Setup "
echo "======================================"

# -------------------------
# Update System
# -------------------------
echo "=== Updating system packages ==="
apt update && apt upgrade -y && apt autoremove -y

# -------------------------
# Change Root Password
# -------------------------
echo "=== Change ROOT password ==="
passwd root

# -------------------------
# Create New User
# -------------------------
read -p "Enter new username: " NEWUSER

# Create user without extra info prompts
useradd -m -s /bin/bash "$NEWUSER"

echo "Set password for $NEWUSER"
passwd "$NEWUSER"

# Add to sudo
usermod -aG sudo "$NEWUSER"
echo "User $NEWUSER added to sudo group"

# -------------------------
# Add SSH Authorized Keys (multi-line, multiple keys)
# -------------------------
echo "Paste SSH public key(s) for $NEWUSER."
echo "When finished, press CTRL+D to end input."

mkdir -p /home/$NEWUSER/.ssh
cat >> /home/$NEWUSER/.ssh/authorized_keys

chmod 700 /home/$NEWUSER/.ssh
chmod 600 /home/$NEWUSER/.ssh/authorized_keys
chown -R $NEWUSER:$NEWUSER /home/$NEWUSER/.ssh

echo "SSH key(s) added for $NEWUSER"

# -------------------------
# Change SSH Port with Validation
# -------------------------
while true; do
    read -p "Enter new SSH port (1024-65535): " SSHPORT
    # Check if input is a number
    if ! [[ "$SSHPORT" =~ ^[0-9]+$ ]]; then
        echo "Error: Please enter a valid number."
        continue
    fi
    # Check valid port range
    if ((SSHPORT < 1024 || SSHPORT > 65535)); then
        echo "Error: Port must be between 1024 and 65535."
        continue
    fi
    break
done

echo "Selected SSH port: $SSHPORT"

# -------------------------
# Backup SSH config
# -------------------------
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Change port and disable root login
sed -i "s/^#Port 22/Port $SSHPORT/" /etc/ssh/sshd_config
sed -i "s/^Port 22/Port $SSHPORT/" /etc/ssh/sshd_config
sed -i "s/^#PermitRootLogin.*/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i "s/^PermitRootLogin.*/PermitRootLogin no/" /etc/ssh/sshd_config

# -------------------------
# Firewall Rule
# -------------------------
if command -v ufw &> /dev/null; then
    ufw allow "$SSHPORT"/tcp
    ufw reload
fi

# -------------------------
# Restart SSH
# -------------------------
systemctl restart ssh

# -------------------------
# Final Message
# -------------------------
echo "======================================"
echo " SETUP COMPLETED SUCCESSFULLY"
echo "--------------------------------------"
echo " New user: $NEWUSER (sudo enabled)"
echo " SSH Port: $SSHPORT"
echo " Root SSH login: DISABLED"
echo " SSH Key login: ENABLED for $NEWUSER"
echo "======================================"
echo " IMPORTANT: Test SSH before closing session!"
echo " ssh -p $SSHPORT $NEWUSER@SERVER_IP"
