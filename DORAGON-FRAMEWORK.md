# DORAGON FRAMEWORK

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

```
doragon/
├── bin/
│   ├── doragon                 # main CLI (bash or compiled, your choice)
│   └── doragonctl              # optional alias / compat
│
├── core/
│   ├── lib/
│   │   ├── logging.sh          # log levels + output formatting
│   │   ├── os-detect.sh        # fedora/debian/alma detection
│   │   ├── validators.sh       # validate config, permissions, paths
│   │   ├── exec.sh             # safe exec wrapper (dry-run, confirm)
│   │   └── io.sh               # read config, merge, defaults
│   │
│   ├── installers/
│   │   ├── install.sh          # core installer
│   │   ├── uninstall.sh
│   │   └── upgrade.sh
│   │
│   ├── templates/
│   │   ├── nginx/
│   │   ├── fail2ban/
│   │   └── systemd/
│   │
│   └── defaults/
│       ├── doragon.conf        # default config template
│       └── modules.conf        # default module enable states
│
├── modules/
│   ├── nginx/
│   │   ├── bin/                # module commands (called by doragon)
│   │   │   ├── enable.sh
│   │   │   ├── disable.sh
│   │   │   └── status.sh
│   │   ├── conf/
│   │   │   └── nginx.conf.example
│   │   ├── templates/
│   │   └── README.md
│   │
│   ├── fail2ban/
│   ├── firewall/
│   ├── selinux/
│   ├── sftp-toggle/
│   └── discord-alerts/
│
├── systemd/
│   ├── doragon.service
│   ├── doragon.timer
│   ├── doragon-discord.service
│   └── doragon-discord.timer
│
├── conf/
│   ├── doragon.conf.example
│   ├── doragon.env.example     # secrets live here (600 perms)
│   └── modules.d/
│       ├── nginx.conf.example
│       ├── fail2ban.conf.example
│       └── discord.conf.example
│
├── docs/
│   ├── QUICKSTART.md
│   ├── SECURITY.md
│   ├── MODULES.md
│   └── BUSINESS-EDITION.md
│
├── tests/
│   ├── smoke/
│   └── integration/
│
├── packaging/
│   ├── rpm/
│   └── deb/
│
├── Makefile
├── LICENSE
└── README.md

```

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

Valentaizar Hitsukaya
