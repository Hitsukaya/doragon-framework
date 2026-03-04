# Doragon Framework
 
> Powered by Hitsukaya
[![Hitsukaya](https://img.shields.io/badge/Hitsukaya-red)](https://hitsukaya.com)
![Type](https://img.shields.io/badge/type-self--hosted%20framework-blue)
![Focus](https://img.shields.io/badge/focus-security%20%2B%20low%20overhead-success)

**STABILITY • SIMPLICITY • SECURE BY ARCHITECTURE**

Doragon Framework is a lightweight, self-hosted deployment and security framework for Linux VPS servers.

It provides a deterministic CLI-based security orchestration layer designed for **AlmaLinux systems**, enforcing layered security controls using native Linux mechanisms such as:

- SELinux
- firewalld
- Fail2Ban
- SSH hardening
- systemd services

Doragon focuses on **minimal overhead**, **predictable behavior**, and **transparent system security auditing**.

---

# Key Features

Doragon provides a modular CLI toolkit for security inspection and server hardening.

Core capabilities include:

- Fail2Ban management and inspection
- SELinux AVC analysis
- Firewall configuration auditing
- SSH configuration auditing
- Service monitoring
- Network exposure analysis
- System timer inspection
- Security score evaluation
- Structured reporting

The framework is designed to run **directly on the host system** without container abstraction.

---

# Supported Systems

Currently supported:

- AlmaLinux 9.x

Future compatibility may include:

- Rocky Linux
- RHEL compatible systems

---

# Installation

```bash
git clone https://github.com/Hitsukaya/doragon-framework.git
cd doragon-framework
sudo ./install.sh
```

Run first security scan:

```bash
sudo doragon status
```

---

# Example Usage

```bash
sudo doragon status
```

Example output:

```
[OK] SELinux: Enforcing
[OK] Firewall: running
[OK] Fail2Ban: active (17 jails)
[WARN] PostgreSQL listening on public interface

Security Score: 95 / 100
```

---

# CLI Commands Overview

## Core

```
doragon status
doragon report
doragon helper
```

## Fail2Ban

```
doragon f2b status
doragon f2b bans
doragon f2b nginx-errors
doragon f2b tail
doragon f2b unban
doragon f2b unban-jail
doragon f2b set-list
doragon f2b unban-set
```

## SELinux

```
doragon selinux status
doragon selinux avc today
doragon selinux avc count
doragon selinux avc summary
doragon selinux avc grep
```

## Firewall

```
doragon fw zones
doragon fw rich
doragon fw iptables
```

## Network

```
doragon net ports
doragon net ip
```

## Services

```
doragon svc nginx
doragon svc php-fpm
doragon svc mariadb
doragon svc postgresql
doragon svc redis
doragon svc status
```

---

# Architecture Overview

Execution flow:

1. `/usr/bin/doragon` invoked
2. Config loaded from `/etc/doragon/doragon.conf`
3. CLI arguments parsed
4. Modules executed from `/usr/libexec/doragon/lib`
5. Reports stored in `/var/lib/doragon/output`
6. Logs written to `/var/log/doragon`

---

# Security Model

Layers:

1. Network Isolation (firewalld)
2. SSH Hardening
3. SELinux Mandatory Access Control
4. Fail2Ban Runtime Mitigation
5. Monitoring & Reporting

---

# Directory Layout

```
/usr/bin/doragon
/etc/doragon/
/usr/libexec/doragon/
/var/lib/doragon/
/var/log/doragon/
```

---

# Versioning

Semantic versioning:

- Major → architecture
- Minor → features
- Patch → fixes

---

# Roadmap

Planned:

- Doragon Doctor auto-remediation
- JSON reporting
- Extended scoring
- Remote scan

---

# License

MIT License

---

# Project

Doragon Framework is developed under the **Hitsukaya** ecosystem.

https://hitsukaya.com
