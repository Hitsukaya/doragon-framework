#!/usr/bin/env bash
set -euo pipefail

doragon_svc_usage() {
  cat <<'USAGE'
Service commands:
  doragon svc status <name>        # systemctl status <name>
  doragon svc nginx                # systemctl status nginx
  doragon svc php-fpm              # systemctl status php-fpm
  doragon svc mariadb              # systemctl status mariadb
  doragon svc postgresql           # systemctl status postgresql
  doragon svc running              # list running services (short)
  doragon svc running --full       # list running services (full)

Timer commands:
  doragon timers                   # list timers --all
  doragon timer status <name>      # systemctl status <timer>

Notes:
  - Uses sudo automatically (systemctl status/list usually requires root for full details).
USAGE
}

_doragon_svc_require_root() {
  if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" svc "$@"
  fi
}

_doragon_timers_require_root() {
  if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" timers "$@"
  fi
}

doragon_svc_status() {
  local name="${1:-}"
  [[ -z "$name" ]] && die "Usage: doragon svc status <name>"
  systemctl status "$name" --no-pager
}

doragon_svc_running_short() {
  # Short list of running services
  systemctl list-units --type=service --state=running --no-pager
}

doragon_svc_running_full() {
  systemctl list-units --type=service --state=running --no-pager --all
}

doragon_timers_list() {
  systemctl list-timers --all --no-pager
}

doragon_timer_status() {
  local name="${1:-}"
  [[ -z "$name" ]] && die "Usage: doragon timer status <name>"
  systemctl status "$name" --no-pager
}

doragon_svc_cmd() {
  local sub="${1:-}"
  shift || true

  _doragon_svc_require_root "$sub" "$@"

  case "$sub" in
    status)
      doragon_svc_status "${1:-}"
      ;;
    nginx|php-fpm|mariadb|postgresql)
      doragon_svc_status "$sub"
      ;;
    running)
      if [[ "${1:-}" == "--full" ]]; then
        doragon_svc_running_full
      else
        doragon_svc_running_short
      fi
      ;;
    -h|--help|"")
      doragon_svc_usage
      ;;
    *)
      die "Unknown svc subcommand: $sub. Try: doragon svc --help"
      ;;
  esac
}

doragon_timers_cmd() {
  local sub="${1:-}"
  shift || true

  _doragon_timers_require_root "$sub" "$@"

  case "$sub" in
    "" )
      doragon_timers_list
      ;;
    status)
      doragon_timer_status "${1:-}"
      ;;
    -h|--help)
      doragon_svc_usage
      ;;
    *)
      die "Unknown timers subcommand: $sub. Try: doragon timers (or: doragon timers status <name>)"
      ;;
  esac
}
