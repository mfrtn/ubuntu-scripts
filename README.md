# Ubuntu Secure Initial Setup Script

A fully automated Bash script to secure a fresh Ubuntu server.

## 🚀 Features

- System update and cleanup (apt update, upgrade, autoremove)
- Change root password
- Create a new user without interactive profile questions
- Set user password
- Add user to sudo group
- Add SSH public key to new user
- Change SSH port interactively
- Disable root SSH login (PermitRootLogin no)
- Auto firewall rule for new SSH port (UFW)
- Backup of sshd_config

---

## ⚡ One-Line Install Command

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/mfrtn/ubuntu-scripts/refs/heads/main/setup.sh)
