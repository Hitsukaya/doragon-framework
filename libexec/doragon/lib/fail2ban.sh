#!/usr/bin/env bash
set -euo pipefail

# Default jail list (customize freely)
DORAGON_F2B_JAILS_DEFAULT=(
  sshd
  postgresql
  nginx-http-auth
  laravel-scan
  nginx-error
  nginx-blocked
  nginx-blocked-suspicious
  nginx-scanner
  nginx-ratelimit
  laravel-wordpress
  phpmyadmin
  recidive
  nginx-ssl-handshake-protection
  nginx-exchange-scan
  nginx-livewire
  convertor
  nginx-envscan
)

doragon_f2b_cmd() {
  local sub="${1:-status}"
  shift || true

  case "${sub}" in
    status)
      doragon_f2b_status "${@:-}"
      ;;
    bans)
      doragon_f2b_last_bans "${1:-5}"
      ;;
    nginx-errors)
      doragon_f2b_nginx_errors "${1:-10}"
      ;;
    tail)
      doragon_f2b_tail
      ;;
    unban-set)
      doragon_f2b_unban_set "$@"
      ;;
    set-list)
     doragon_f2b_set-list "$@"
     ;;
   unban)
    doragon_f2b_unban_global "$@"
    ;;
    -h|--help|help|"")
      doragon_f2b_usage
      ;;
    *)
      die "Unknown f2b subcommand: ${sub}. Try: doragon f2b --help"
      ;;
  esac
}

doragon_f2b_usage() {
  cat <<'USAGE'
Fail2Ban commands:

  doragon f2b status               # show status for default jail list
  doragon f2b status <jail>        # show status for one jail
  doragon f2b bans [N]             # show last N bans (default 5)
  doragon f2b nginx-errors [N]     # show last N nginx errors (default 10)
  doragon f2b tail                 # tail -f fail2ban log
  doragon f2b unban-set <set-name> <IP>  # Remove IP from ipset
  doragon f2b set-list <set-name>        # Show IPs in ipset

USAGE
}

doragon_f2b_status() {
  local one_jail="${1:-}"

  # If not root, use sudo automatically
  local SUDO=""
  if [[ "${EUID}" -ne 0 ]]; then
    SUDO="sudo"
  fi

  if ! command -v fail2ban-client >/dev/null 2>&1; then
    warn "Fail2Ban not installed (fail2ban-client not found)."
    return 1
  fi

  echo "===== FAIL2BAN STATUS ====="

  if [[ -n "${one_jail}" ]]; then
    ${SUDO} fail2ban-client status "${one_jail}" || warn "Jail '${one_jail}' not found or not running."
    return 0
  fi

  # global status
  ${SUDO} fail2ban-client status || true
  echo

  # per-jail status
  local jail
  for jail in "${DORAGON_F2B_JAILS_DEFAULT[@]}"; do
    echo "---- ${jail} ----"
    ${SUDO} fail2ban-client status "${jail}" || warn "Jail '${jail}' not found or not running."
    echo
  done
}

doragon_f2b_last_bans() {
  local n="${1:-5}"
  local SUDO=""
  if [[ "${EUID}" -ne 0 ]]; then SUDO="sudo"; fi

  echo "===== LAST ${n} FAIL2BAN BANS ====="
  ${SUDO} grep -E " Ban " /var/log/fail2ban.log 2>/dev/null | tail -n "${n}" || \
    warn "No bans found or /var/log/fail2ban.log not readable."
}

doragon_f2b_unban_set() {
  local set_name="${1:-}"
  local ip="${2:-}"

  [[ -z "$set_name" || -z "$ip" ]] && \
    die "Usage: doragon f2b unban-set <set-name> <IP>"

  command -v ipset >/dev/null 2>&1 || die "ipset not installed."

  if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" f2b unban-set "$set_name" "$ip"
  fi

  # Check set exists
  if ! ipset list "$set_name" >/dev/null 2>&1; then
    die "ipset '$set_name' does not exist."
  fi

  # Check IP exists in set
  if ! ipset test "$set_name" "$ip" >/dev/null 2>&1; then
    warn "IP $ip not found in set '$set_name'."
    return 0
  fi

 # Validate IPv4 (basic check)
 if ! [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
   die "Invalid IP format: $ip"
  fi

  ipset del "$set_name" "$ip"

  ok "Removed $ip from ipset '$set_name'."
}

doragon_f2b_unban_global() {
  local ip="${1:-}"
  [[ -z "$ip" ]] && die "Usage: doragon f2b unban <IP>"

  command -v ipset >/dev/null 2>&1 || die "ipset not installed."

  # basic IPv4 validation
  if ! [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    die "Invalid IP format: $ip"
  fi

  # elevate only if needed
  if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" f2b unban "$ip"
  fi

  local sets
  sets=$(ipset list -name 2>/dev/null | grep '^f2b-' || true)

  [[ -z "$sets" ]] && die "No f2b-* ipsets found."

  local removed=0

  for set in $sets; do
    if ipset test "$set" "$ip" >/dev/null 2>&1; then
      ipset del "$set" "$ip"
      ok "Removed $ip from $set"
      removed=1
    fi
  done

  if [[ "$removed" -eq 0 ]]; then
    warn "IP $ip not found in any f2b-* set."
  fi
}

doragon_f2b_set_list() {
  local set_name="${1:-}"
  [[ -z "$set_name" ]] && die "Usage: doragon f2b set-list <set-name>"

  if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" f2b set-list "$set_name"
  fi

  ipset list "$set_name"
}

doragon_f2b_nginx_errors() {
  local n="${1:-10}"
  local SUDO=""
  if [[ "${EUID}" -ne 0 ]]; then SUDO="sudo"; fi

  echo "===== LAST ${n} NGINX ERRORS ====="
  ${SUDO} tail -n "${n}" /var/log/nginx/error.log 2>/dev/null || warn "nginx error log not readable."
}

doragon_f2b_tail() {
  local SUDO=""
  if [[ "${EUID}" -ne 0 ]]; then SUDO="sudo"; fi

  echo "===== TAIL FAIL2BAN LOG (Ctrl+C to stop) ====="
  ${SUDO} tail -f /var/log/fail2ban.log
}
