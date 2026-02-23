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

useradd -m -s /bin/bash "$NEWUSER"

echo "Set password for $NEWUSER"
passwd "$NEWUSER"

# -------------------------
# Add to sudo group
# -------------------------
usermod -aG sudo "$NEWUSER"
echo "User $NEWUSER added to sudo group"

# -------------------------
# Add SSH Authorized Key
# -------------------------
echo "Paste SSH public key for $NEWUSER:"
read -r SSHKEY

mkdir -p /home/$NEWUSER/.ssh
echo "$SSHKEY" > /home/$NEWUSER/.ssh/authorized_keys

chmod 700 /home/$NEWUSER/.ssh
chmod 600 /home/$NEWUSER/.ssh/authorized_keys
chown -R $NEWUSER:$NEWUSER /home/$NEWUSER/.ssh

echo "SSH key added for $NEWUSER"

# -------------------------
# Change SSH Port
# -------------------------
read -p "Enter new SSH port (e.g. 2222): " SSHPORT

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Change port
sed -i "s/^#Port 22/Port $SSHPORT/" /etc/ssh/sshd_config
sed -i "s/^Port 22/Port $SSHPORT/" /etc/ssh/sshd_config

# Disable root login
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
