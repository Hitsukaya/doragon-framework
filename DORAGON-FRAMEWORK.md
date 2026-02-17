# 🐉 DORAGON FRAMEWORK

## Enterprise Server Security & Automation Stack

---

## 1. Overview

**Doragon Framework** is a modular server security and automation system
designed for small and medium-sized businesses.

### Purpose

- Rapid deployment
- Secure-by-default configuration
- Centralized monitoring
- Modular architecture
- Scalable infrastructure

Doragon transforms a clean VPS into a production-ready secured
environment in minutes.

---

## 2. Architecture

    doragon-framework/
    │
    ├── bin/
    │   └── doragon
    │
    ├── core/
    │   ├── bootstrap.sh
    │   ├── logger.sh
    │   ├── helpers.sh
    │   └── config-loader.sh
    │
    ├── config/
    │   ├── doragon.conf
    │   ├── doragon.conf.example
    │   └── modules/
    │       ├── fail2ban.conf
    │       ├── sftp-toggle.conf
    │       └── discord.conf
    │
    ├── modules/
    │   ├── fail2ban/
    │   ├── firewall/
    │   ├── selinux/
    │   ├── nginx/
    │   ├── sftp-toggle/
    │   └── discord/
    │
    ├── vendor/
    │   └── sftp-toggle/
    │
    ├── templates/
    │   ├── nginx/
    │   ├── systemd/
    │   └── motd/
    │
    ├── install.sh
    ├── uninstall.sh
    ├── README.md
    └── LICENSE

---

## 3. Core Principles

1.  Modularity\
2.  Idempotent operations\
3.  Separation of config and logic\
4.  Unified CLI\
5.  Production-ready structure

---

## 4. CLI Usage

    doragon <module> <action>

### Examples

    doragon fail2ban enable
    doragon firewall status
    doragon sftp on
    doragon nginx create-domain example.com
    doragon discord configure

---

## 5. Security Stack

- Custom Fail2Ban jails
- Recidive protection
- ipset integration
- SELinux audit monitoring
- Hardened firewall rules
- SFTP access toggle
- Discord webhook monitoring
- Hardened Nginx configuration
- /tmp mounted noexec
- systemd timers

---

## 6. Product Vision

> "Secure business servers in 15 minutes."

Target audience: - Agencies - Freelancers - Laravel developers -
WordPress developers - Small SaaS startups

---

## Author

Valentin Hitsukaya
