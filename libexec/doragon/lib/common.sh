#!/usr/bin/env bash
set -euo pipefail

ts() { date +"%Y-%m-%d %H:%M:%S"; }

die() {
  echo "ERROR: $*" >&2
  exit 2
}

ok()   { printf "[OK]    %s\n" "$*"; }
warn() { printf "[WARN]  %s\n" "$*"; }
fail() { printf "[FAIL]  %s\n" "$*"; }
info() { echo "$*"; }

detect_os_pretty() {
  if [[ -r /etc/almalinux-release ]]; then
    cat /etc/almalinux-release
    return 0
  fi
  if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    echo "${PRETTY_NAME:-unknown}"
    return 0
  fi
  echo "unknown"
}

is_almalinux_9() {
  local rel
  rel="$(detect_os_pretty)"
  [[ "${rel}" =~ AlmaLinux\ release\ 9\..* ]]
}

service_active() {
  local s="$1"
  systemctl is-active --quiet "${s}"
}

getenforce_safe() {
  command -v getenforce >/dev/null 2>&1 || { echo "unknown"; return 0; }
  getenforce 2>/dev/null || echo "unknown"
}

hostname_safe() { hostname 2>/dev/null || echo "unknown"; }
kernel_safe() { uname -r 2>/dev/null || echo "unknown"; }
uptime_short() { uptime 2>/dev/null | sed 's/^ *//'; }

