#!/usr/bin/env bash
set -euo pipefail

doragon_svc_usage() {
  cat <<'USAGE'
Service commands:
  - Status Services -
  doragon svc status <name>        # Status <name>
  doragon svc nginx                # Status nginx
  doragon svc fail2ban             # Status Fail2Ban
  doragon svc php-fpm              # Status php-fpm
  doragon svc mariadb              # Statustatus mariadb
  doragon svc postgresql           # Status postgresql
  doragon svc redis                # Status redis
  doragon svc running              # List running services (short)
  doragon svc running --full       # List running services (full)

  - Reload Services -
  doragon svc reload <name>        # Reload <name>
  doragon svc reload nginx         # Reload NGINX
  doragon svc reload fail2ban      # Reload Fail2Ban
  doragon svc reload php-fpm       # Reload PHP-FPM
  doragon svc reload mariadb       # Reload MariaDB
  doragon svc reload postgresql    # Reload Postgresql
  doragon svc reload redis         # Reload Redis

  - Restart Services -
  doragon svc restart <name>       # Restart <name>
  doragon svc restart nginx        # Restart NGINX
  doragon svc restart fail2ban     # Restart Fail2Ban
  doragon svc restart php-fpm      # Restart PHP-FPM
  doragon svc restart mariadb      # Restart MariaDB
  doragon svc restart postgresql   # Restart Postgresql
  doragon svc restart redis        # Restart Redis

  - Stop Services -
  doragon svc stop <name>          # Stop <name>
  doragon svc stop nginx           # Stop NGINX
  doragon svc stop fail2ban        # Stop Fail2Ban
  doragon svc stop php-fpm         # Stop PHP-FPM
  doragon svc stop mariadb         # Stop MariaDB
  doragon svc stop postgresql      # Stop Postgresql
  doragon svc stop redis           # Stop Redis

  - Start Services -
  doragon svc start <name>         # Start <name>
  doragon svc start nginx          # Start NGINX
  doragon svc start fail2ban       # Start Fail2Ban
  doragon svc start php-fpm        # Start PHP-FPM
  doragon svc start mariadb        # Start MariaDB
  doragon svc start postgresql     # Start Postgresql
  doragon svc start redis          # Start Redis

  - Enable Services -
  doragon svc enable <name>        # Enable <name>
  doragon svc enable nginx         # Enable NGINX
  doragon svc enable fail2ban      # Enable Fail2Ban
  doragon svc enable php-fpm       # Enable PHP-FPM
  doragon svc enable mariadb       # Enable MariaDB
  doragon svc enable postgresql    # Enable Postgresql
  doragon svc enable redis         # Enable Redis

  - Disable Services -
  doragon svc disable <name>       # Disable <name>
  doragon svc disable nginx        # Disable NGINX
  doragon svc disable fail2ban     # Disable Fail2Ban
  doragon svc disable php-fpm      # Disable PHP-FPM
  doragon svc disable mariadb      # Disable MariaDB
  doragon svc disable postgresql   # Disable Postgresql
  doragon svc disable redis        # Disable Redis

Timer commands:
  doragon timers                   # list timers --all
  doragon timer status <name>      # systemctl status <timer>

Notes:
  - Uses sudo automatically (doragon status/list usually requires root for full details).
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

doragon_unit_exists() {
  systemctl status "$1" >/dev/null 2>&1
}

doragon_svc_cmd() {
  local sub="${1:-}"
  shift || true

  _doragon_svc_require_root "$sub" "$@"

  case "$sub" in
    status)
      doragon_svc_status "${1:-}"
      ;;
    reload)
      doragon_svc_reload "${1:-}"
      ;;
    restart)
      doragon_svc_restart "${1:-}"
      ;;
    stop)
      doragon_svc_stop "${1:-}"
      ;;
    start)
      doragon_svc_start "${1:-}"
      ;;
    enable)
      doragon_svc_enable "${1:-}"
      ;;
    disable)
      doragon_svc_disable "${1:-}"
      ;;
    nginx|fail2ban|php-fpm|mariadb|postgresql|redis)
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
if ! doragon_unit_exists "$sub"; then
  warn "Service not installed: $sub"
  return 1
fi
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
