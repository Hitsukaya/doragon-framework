# Doragon Framework
 
[![Hitsukaya](https://img.shields.io/badge/Hitsukaya-red)](https://hitsukaya.com)
![Type](https://img.shields.io/badge/type-self--hosted%20framework-blue)
![Focus](https://img.shields.io/badge/focus-security%20%2B%20low%20overhead-success)
[![Powered by Hitsukaya](https://img.shields.io/badge/Hitsukaya-Framework-red)](https://hitsukaya.com)
![Language](https://img.shields.io/badge/language-bash-blue)
![Platform](https://img.shields.io/badge/platform-Linux-orange)
![Focus](https://img.shields.io/badge/security-first-success)
![Dependencies](https://img.shields.io/badge/dependencies-native%20linux-success)

**STABILITY • SIMPLICITY • SECURE BY ARCHITECTURE**

## Overview

Doragon Framework is a lightweight, self-hosted deployment and security platform designed  
for Linux servers, hosting providers, and cloud infrastructure environments.

It provides a deterministic CLI-based orchestration layer focused on system hardening, inspection, and audit — built entirely on native Linux components.

---

## Core Philosophy

It is a modular infrastructure framework designed to provide:

- deterministic execution  
- transparent system inspection  
- minimal overhead  
- predictable behavior  

---

## Key Features

- Server status & diagnostics  
- Fail2Ban inspection and control  
- SELinux context and AVC analysis  
- Firewall auditing (firewalld / iptables)  
- SSH security inspection  
- Service monitoring (nginx, php-fpm, mariadb, redis)  
- Network exposure analysis  
- System timer inspection  
- Security score engine  
- GDPR compliance audit  
- Structured CLI reporting  

---

## Architecture

```text
                ┌──────────────────────────────┐
                │         Doragon CLI          │
                │       /usr/bin/doragon       │
                └──────────────┬───────────────┘
                               │
                ┌──────────────▼───────────────┐
                │        Bootstrap Layer       │
                │   verify + init + config     │
                └──────────────┬───────────────┘
                               │
                ┌──────────────▼───────────────┐
                │          Loader              │
                │   dynamic module loading     │
                └──────────────┬───────────────┘
                               │
                ┌──────────────▼───────────────┐
                │          Registry            │
                │   CLI routing & dispatch     │
                └──────────────┬───────────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
 ┌──────▼────────┐    ┌────────▼────────┐    ┌────────▼────────┐
 │   Security    │    │    Services     │    │     Network     │
 │               │    │                 │    │                 │
 │ • SELinux     │    │ • nginx         │    │ • firewall      │
 │ • Fail2Ban    │    │ • php-fpm       │    │ • ports         │
 │ • SSH         │    │ • mariadb       │    │ • connectivity  │
 │ • SFTP        │    │ • redis         │    │                 │
 └───────────────┘    └─────────────────┘    └─────────────────┘
                               │
                ┌──────────────▼───────────────┐
                │        Reporting Layer       │
                │   status • report • scoring  │
                └──────────────┬───────────────┘
                               │
                ┌──────────────▼───────────────┐
                │         System Layer         │
                │   RHEL-like Linux systems    │
                └──────────────────────────────┘
```
---

# Design Principles
- Minimal CLI entrypoint
- Separation between core and modules
- Dynamic module loading
- Deterministic execution flow
- Security-first defaults
- Native Linux integration

---

# Supported Systems

Currently supported:

- AlmaLinux 9.x
- RHEL 9.x

Planned:
FreeBSD (future support)
---

# Installation

```bash
git clone https://github.com/Hitsukaya/doragon-framework.git
cd doragon-framework
sudo ./install.sh
```
---
```
Run first security scan:

```bash
sudo doragon 
```
---
```
# Doragon includes a GDPR-oriented audit module designed to detect:

# GDPR Compliance

```bash
sudo doragon gdpr
```

- exposed databases
- insecure authentication
- publicly accessible services
- weak infrastructure configurations


---

# Architecture Overview

Execution Flow
1. /usr/bin/doragon is invoked
2. Bootstrap initializes environment
3. Core verification is executed
4. Modules are dynamically loaded
5. CLI command is routed via registry
6. Output is generated in real time
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


1. /usr/bin/doragon
2. /etc/doragon/
3. /usr/libexec/doragon/core
4. /usr/libexec/doragon/modules
5. /var/lib/doragon/
6. /var/log/doragon/


---

# Releases

- See GitHub Releases for version history and changes.

---

# License

MIT License

---

# Project

Doragon Framework is part of the Hitsukaya ecosystem.

https://hitsukaya.com


---

## Production testing

Doragon has been running on a production, supporting a multi-site 
environment with several web applications.

This real-world deployment helps validate:

- service detection
- security auditing
- Fail2Ban integration
- SELinux inspection
- system health reporting

Continuous updates are tested directly on a live environment,
ensuring the framework behaves correctly under real workloads.
