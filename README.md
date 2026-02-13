# Doragon Framework 🚀 (Coming Soon)
> Powered by Hitsukaya

[![Hitsukaya](https://img.shields.io/badge/Hitsukaya-red)](https://hitsukaya.com)
![Status](https://img.shields.io/badge/status-coming%20soon-orange)
![Type](https://img.shields.io/badge/type-self--hosted%20framework-blue)
![Focus](https://img.shields.io/badge/focus-security%20%2B%20low%20overhead-success)

Doragon Framework is a lightweight, self-hosted deployment and security framework for Linux VPS servers.

It builds a production-ready stack with **minimal overhead**, using native system tools close to the kernel layer:
**systemd, SELinux, firewalld/iptables, Fail2Ban, Nginx, Unix sockets**.

This project is designed for people who want:
- real security hardening (not just UI/UX hype)
- low memory usage
- clean and reproducible deployments
- a server that survives real-world abuse (scans, brute force, flood attempts)

---

## ✨ Planned Features

### 🔥 Security
- Fail2Ban (multi-jail setup + custom filters)
- Discord ban notifications (real-time)
- SELinux contexts + hardening helpers
- Firewall setup (firewalld + iptables)
- `/tmp` mounted with `noexec`

### 🧰 Self-hosted CLI tools
- MOTD Dashboard (quick monitoring + security commands)
- `system-helper-check` (ownership, permissions, SELinux context, quick fixes)
- SFTP ON/OFF Access Toggle (POSIX ACL based)

### 🌐 Web Stack
- Nginx optimized configs
- SSL automation (Certbot)
- Unix sockets (PHP-FPM, services)

### 🗄️ Databases
- MariaDB setup script
- PostgreSQL setup script

### 📦 Deployment Layout
- `/home/hitsukaya/web_public/` content deployment
- Laravel-ready defaults

---

## 🧱 Planned Structure
```
doragon-framework/
├─ motd/                     # MOTD Dashboard
│   └─ motd.sh
├─ helpers/                  # System helper CLI
│   └─ system-helper-check.sh
├─ sftp-toggle/              # SFTP ON/OFF toggle scripts
│   ├─ sftp-on.sh
│   └─ sftp-off.sh
├─ fail2ban/                 # Fail2Ban config + filters
│   ├─ jail.local
│   └─ filters/
├─ firewall/                 # iptables / firewalld rules
│   └─ firewall-setup.sh
├─ selinux/                  # SELinux context fixes
│   └─ selinux-setup.sh
├─ nginx/                    # Nginx configs + SSL
│   ├─ sites-available/
│   └─ certbot-setup.sh
├─ db/                       # MariaDB / PostgreSQL setup
│   ├─ mariadb-setup.sh
│   └─ postgresql-setup.sh
├─ public/                   # /home/hitsukaya/web_public/ content
│   └─ (Laravel / static files etc.)
└─ install.sh                # Main deploy script
```
 ---

## ⚙️ install.sh (planned flow)

- 01 Update OS & install packages
- 02 MOTD & system-helper-check
- 03 Firewall & SELinux setup
- 04 SFTP toggle ACL
- 05 Nginx config + Certbot SSL
- 06 Deploy /home/hitsukaya/web_public/ content
- 07 Setup MariaDB & PostgreSQL
- 08 Test security scripts (Discord alerts)
- 09 Restart services & final checks

---

## 🧠 Philosophy

- Modern infrastructure often adds unnecessary complexity.
- Doragon Framework follows a different rule:
- Use the system’s native tools first.
- Keep it simple. Keep it fast. Keep it secure.
- No bloat. No hype. Just production-ready Unix hardening.

---

📌 Status

🚧 Coming soon
- This repository will include:
  - full directory structure
  - installation scripts
  - security defaults
  - reproducible deployment flow

