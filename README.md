# Doragon Framework
 
> Powered by Hitsukaya
[![Hitsukaya](https://img.shields.io/badge/Hitsukaya-red)](https://hitsukaya.com)
![Type](https://img.shields.io/badge/type-self--hosted%20framework-blue)
![Focus](https://img.shields.io/badge/focus-security%20%2B%20low%20overhead-success)

STABILITY • SIMPLICITY • SECURE BY ARCHITECTURE
Doragon Framework is a lightweight, self-hosted deployment and
security framework for Linux VPS servers.
Doragon Framework is a deterministic CLI-based security orchestration layer for AlmaLinux systems.
It enforces layered security controls using native Linux mechanisms without container abstraction.

# v1.0.4 Enterprise Architecture & Technical Documentation

## 2. Architectural Overview

Doragon Framework is a deterministic CLI-based security orchestration layer for AlmaLinux systems.
It enforces layered security controls using native Linux mechanisms without container abstraction.

Security Layers:

1. Network Isolation (firewalld)
2. SSH Hardening
3. SELinux Mandatory Access Control
4. Fail2Ban Runtime Mitigation
5. Observability & Reporting

## 3. CLI Execution Flow

1. User invokes `/usr/bin/doragon`
2. Configuration is loaded from `/etc/doragon/doragon.conf`
3. CLI arguments are parsed and validated
4. Execution is delegated to `/usr/libexec/doragon/lib/*.sh`
5. Operational logic executes with validation checks
6. Reports are generated under `/var/lib/doragon/output`
7. Logs are written to `/var/log/doragon`

## 4. Threat Model

### Mitigated Threats

- SSH brute force attacks
- Automated vulnerability scans
- Web exploit noise
- Configuration drift

### Out of Scope

- Kernel zero-day exploits
- Post-root compromise scenarios
- Physical access threats
- Supply chain attacks

## 5. Security Guarantees

- Deterministic configuration enforcement
- Minimal attack surface exposure
- Runtime validation before execution
- Explicit logging and reporting

## 6. Limitations

- Does not prevent unknown kernel vulnerabilities
- Assumes trusted root environment
- Relies on correct SELinux and firewalld baseline

## 7. Versioning Strategy

Doragon follows semantic versioning principles:

- Major: Architectural changes
- Minor: Feature additions
- Patch: Bug fixes and improvements

## Install
```bash
sudo ./install.sh
