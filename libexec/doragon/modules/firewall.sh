#!/usr/bin/env bash
set -euo pipefail

doragon_fw_usage() {
  cat <<'USAGE'
Firewall commands:
  doragon fw zones                 # firewall-cmd --list-all-zones
  doragon fw rich                  # firewall-cmd --list-rich-rules
  doragon fw rich --zone public    # firewall-cmd --zone=public --list-rich-rules
  doragon fw iptables              # iptables -L -n
  doragon fw ip6tables             # ip6tables -L -n

Notes:
  - Requires root (Doragon will sudo automatically).
USAGE
}

_doragon_fw_require_root() {
  if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" fw "$@"
  fi
}

doragon_fw_zones()      { firewall-cmd --list-all-zones; }
doragon_fw_rich() {
  local zone="${1:-}"
  if [[ -n "$zone" ]]; then
    firewall-cmd --zone="$zone" --list-rich-rules
  else
    firewall-cmd --list-rich-rules
  fi
}
doragon_fw_iptables()   { iptables -L -n; }
doragon_fw_ip6tables()  { ip6tables -L -n; }

doragon_fw_cmd() {
  local sub="${1:-}"
  shift || true

  _doragon_fw_require_root "$sub" "$@"

  case "$sub" in
    zones)
      doragon_fw_zones
      ;;
    rich)
      if [[ "${1:-}" == "--zone" ]]; then
        doragon_fw_rich "${2:-}"
      else
        doragon_fw_rich ""
      fi
      ;;
    iptables)
      doragon_fw_iptables
      ;;
    ip6tables)
      doragon_fw_ip6tables
      ;;
    -h|--help|"")
      doragon_fw_usage
      ;;
    *)
      die "Unknown fw subcommand: $sub. Try: doragon fw --help"
      ;;
  esac
}
