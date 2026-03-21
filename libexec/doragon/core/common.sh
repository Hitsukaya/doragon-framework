#!/usr/bin/env bash
set -euo pipefail

ts() { date +"%Y-%m-%d %H:%M:%S"; }

die() {
  echo "ERROR: $*" >&2
  exit 2
}

section() {
  echo
  printf "%s\n" "$1"
  printf "%s\n" "═════════════════════"
}

ok()   { printf "[OK]    %s\n" "$*"; }
warn() { printf "[WARN]  %s\n" "$*"; }
fail() { printf "[FAIL]  %s\n" "$*"; }
info() { printf "[INFO]  %s\n" "$*"; }

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

score_bar() {
  local score="${1:-0}"
  local total_blocks=20
  local filled empty
  local bar=""
  local i

  (( score < 0 )) && score=0
  (( score > 100 )) && score=100

  filled=$(( score * total_blocks / 100 ))
  empty=$(( total_blocks - filled ))

  for ((i=0; i<filled; i++)); do
    bar+="█"
  done

  for ((i=0; i<empty; i++)); do
    bar+="░"
  done

  printf '%s' "$bar"
}
