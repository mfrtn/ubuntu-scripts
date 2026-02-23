#!/bin/bash

# Must run as root
if [[ $EUID -ne 0 ]]; then
   echo "Run this script as root or with sudo"
   exit 1
fi

echo "=== Change ROOT password ==="
passwd root

echo "=== Create new user ==="
read -p "Enter new username: " NEWUSER

# Create user without extra info prompts
useradd -m -s /bin/bash "$NEWUSER"

echo "Set password for $NEWUSER"
passwd "$NEWUSER"

echo "=== Add user to sudo group ==="
usermod -aG sudo "$NEWUSER"

echo "User $NEWUSER added to sudo group"

echo "=== Change SSH port ==="
read -p "Enter new SSH port (e.g. 2222): " SSHPORT

# Backup sshd_config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Change port (uncomment if needed)
sed -i "s/^#Port 22/Port $SSHPORT/" /etc/ssh/sshd_config
sed -i "s/^Port 22/Port $SSHPORT/" /etc/ssh/sshd_config

# Allow port in firewall if UFW is active
if command -v ufw &> /dev/null; then
    ufw allow "$SSHPORT"/tcp
    ufw reload
fi

echo "Restarting SSH..."
systemctl restart ssh

echo "======================================"
echo "DONE!"
echo "New SSH port: $SSHPORT"
echo "New user: $NEWUSER (sudo enabled)"
echo "Root password changed"
echo "======================================"
